
package 
Class::DBI::Lite::AdHocEntity;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub create { confess "Cannot call 'create' on a @{[ __PACKAGE__ ]}" }
sub update { confess "Cannot call 'update' on a @{[ __PACKAGE__ ]}" }
sub delete { confess "Cannot call 'delete' on a @{[ __PACKAGE__ ]}" }


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/([^:]+)$/;
  
  return unless exists $s->{data}->{$key};
  
  # Read-only access:
  $s->{data}->{$key};
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef( %$s );
}# end DESTROY()

1;# return true:

