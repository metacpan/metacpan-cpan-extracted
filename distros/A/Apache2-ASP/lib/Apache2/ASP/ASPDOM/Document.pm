
package Apache2::ASP::ASPDOM::Document;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ASPDOM::Node';


#==============================================================================
sub new
{
  my ($class) = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  return $s;
}# end new()

1;# return true:

