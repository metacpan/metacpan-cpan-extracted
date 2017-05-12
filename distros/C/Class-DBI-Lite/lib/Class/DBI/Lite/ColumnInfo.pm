
package Class::DBI::Lite::ColumnInfo;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my @required = qw(
    name
    type
    length
    is_nullable
    default_value
    is_pk
    key
  );
  
  foreach( @required )
  {
    die "Required parameter '$_' was not provided"
      unless exists($args{$_});
  }# end foreach()
  
  return bless \%args, $class;
}# end new()

sub null { $_[0]->{is_nullable} }
sub default { $_[0]->{default_value} }
sub enum_values { shift->{enum_values} }


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/([^:]+)$/;
  
  return exists($s->{$key}) ? $s->{$key} : die "Invalid field '$key'";
}# end AUTOLOAD()
sub DESTROY {}

1;# return true:

__END__

=pod

=head1 NAME

Class::DBI::Lite::ColumnInfo - Extended meta-information about database table fields.

=head1 SYNOPSIS

  foreach my $field ( app::artist->columns )
  {
  
  }# end foreach()

=head1 DESCRIPTION

Sometimes database table field information needs to be available during runtime.

This class provides a simple interface to query a specific database field.

=head1 PUBLIC PROPERTIES

=head2 name

Returns the name of the column.

=head2 type

Returns the data type of the column - varchar, int, etc.

=head2 length

Returns the size of the field.

=head2 is_nullable

True or false.

=head2 default_value

Returns the default value of the field, if any.

=head2 is_pk

Returns true if the field is a primary key field.  False otherwise.

=head2 key

Returns either C<undef>, C<primary_key> or C<unique>.

=head2 enum_values

ONLY if the column is an C<enum> data type, this property will return an arraref 
of the possible enum values.

=head1 BUGS

It's possible that some bugs have found their way into this release.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

L<http://www.devstack.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 John Drago <jdrago_999@yahoo.com>, All Rights Reserved.

This software is Free software and may be used and redistributed under the same
terms as perl itself.

=cut
