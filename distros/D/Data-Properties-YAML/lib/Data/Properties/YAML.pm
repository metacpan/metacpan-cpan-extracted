
package Data::Properties::YAML;

use strict;
use warnings 'all';
use YAML 'Load';

our $VERSION = 0.04;


#====================================================================
sub new
{
  my ($class, %args) = @_;
  
  if( $args{properties_file} )
  {
    my $yaml_file = $args{properties_file};
    open my $ifh, '<', $yaml_file
      or die "Cannot open '$yaml_file': $!";
    my $data = '';
    while( my $line = <$ifh> )
    {
      $line =~ s/\t/  /
        while $line =~ m/\t/;
      $data .= $line;
    }# end while()
    $args{data} = Load( $data );
    $args{__name} = 'root';
  }
  elsif( $args{yaml_data} )
  {
    $args{data} = Load( $args{yaml_data} );
    $args{__name} = 'root';
  }# end if()
  
  my $s = bless \%args, $class;
  if( ref($s->{data}) )
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


#====================================================================
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

__END__

=head1 NAME

Data::Properties::YAML - YAML-ized properties for your application

=head1 DEPRECATED

Do not use - this module has been deprecated.

=head1 SYNOPSIS

  use Data::Properties::YAML;
  
  my $yaml = Data::Properties::YAML->new(
    properties_file => '/etc/properties.yaml'
  );
  
  # OR:
  my $yaml = Data::Properties::YAML->new(
    yaml_data => <<'YAML',
  ---
  password_resend:
    general:
      is_not_found: Invalid email address
    contact_email:
      is_missing: Required
      is_invalid: Invalid email address
      is_not_found: Email is not valid - please try again.
  YAML
    );
  
  # Access your properties:
  print "Error: " . $yaml->general->is_not_found;
  
  # Access another property:
  print "Another error: " . $yaml->contact_email->is_missing;
  
  # Dies "Node root.general has no property named 'isnt_found'"
  $yaml->general->isnt_found; 

=head1 DESCRIPTION

YAML is a simple way to store many strings.  Why not use it in place of the typical "properties" file
as used by C<java.util.properties>?

Why not give ourselves a nice Perl-ish interface?

Well, here we go.  Use Data::Properties::YAML and you have just that.

=head1 METHODS

=head2 new( properties_file => '/path/to/file.yaml' )

Returns a new C<Data::Properties::YAML> object based on the structure of your YAML.

=head2 new( yaml_data => $yaml )

Returns a new C<Data::Properties::YAML> object based on the structure of your YAML.

=head1 SEE ALSO

L<YAML>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Properties-YAML> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Data::Properties::YAML in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
