
package Data::Properties::JSON;

use strict;
use warnings 'all';
use JSON::XS;
our $VERSION = '0.004';


sub new
{
  my ($class, %args) = @_;
  
  if( $args{properties_file} )
  {
    $args{__name} = 'root';
    open my $ifh, '<', $args{properties_file}
      or die "Cannot open '$args{properties_file}' for reading: $!";
    local $/;
    $args{data} = decode_json(scalar(<$ifh>));
  }
  elsif( $args{json} )
  {
    $args{data} = decode_json($args{json});
    $args{__name} = 'root';
  }
  elsif( $args{data} )
  {
    $args{__name} ||= 'root';
  }
  else
  {
    die "Neither properties_file nor json nor data were provided.";
  }# end if()
  
  my $s = bless \%args, $class;
  if( ref($s->{data}) eq 'HASH' )
  {
    foreach my $key ( keys(%{ $s->{data} }) )
    {
      next unless ref($s->{data}->{$key});
      $s->{$key} = ref($s)->new(
        __name => "$s->{__name}.$key",
        data => $s->{data}->{$key},
      );
    }# end foreach()
  }# end if()
  
  # Finally:
  return $s;
}# end new()


sub as_hash
{
  wantarray ? %{ $_[0]->{data} } : $_[0]->{data};
}# end as_hash()


sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  
  my ($name) = $AUTOLOAD =~ m/::([^:]+)$/;
  die "Node $s->{__name} has no property named '$name'"
    unless exists( $s->{$name} ) || exists( $s->{data}->{$name} );
  
  return $s->{$name} || $s->{data}->{$name};
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:

=pod

=head1 NAME

Data::Properties::JSON - JSON test fixtures and properties.

=head1 DEPRECATED

This module is now deprecated and should no longer be used.

=head1 SYNOPSIS

File C</path/to/file.json>

  {
    "contact_form": {
      "first_name": "John",
      "last_name":  "Doe",
      "email":      "john.doe@test.com",
      "message":    "This is a test message...just a test."
    }
  }

Your Perl code:

  use Data::Properties::JSON;
  
  my $props = Data::Properties::JSON->new(
    properties_file => "/path/to/file.json"
  );
  
  -- or --
  my $props = Data::Properties::JSON->new( json => $json_string );
  -- or --
  my $props = Data::Properties::JSON->new( data => { foo => "bar" } );
  
  $props->contact_form->first_name; # John
  $props->contact_form->last_name;  # Doe
  $props->contact_form->email;      # john.doe@test.com
  
  # Works differently depending on the calling context:
  my %hash    = $props->contact_form->as_hash;
  my $hashref = $props->contact_form->as_hash;

=head1 AUTHOR and Copyright

Copyright 2011 John Drago <jdrago_999@yahoo.com> all rights reserved.

=head1 LICENSE

This software is Free software and may be used and redistributed under the same 
terms as any version of perl itself.

=head1 SEE ALSO

L<JSON> and L<JSON::XS>

L<ASP4>

=cut

