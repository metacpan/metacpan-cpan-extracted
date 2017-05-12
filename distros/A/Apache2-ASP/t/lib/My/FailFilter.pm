
package My::FailFilter;

use strict;
use warnings 'all';
use base 'Apache2::ASP::RequestFilter';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  return $Response->Redirect('/no-way-jose/');
}# end run()

1;# return true:

