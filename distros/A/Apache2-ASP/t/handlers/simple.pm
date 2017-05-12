
package simple;

use strict;
use warnings 'all';
use base 'Apache2::ASP::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  $Response->Write("HELLO WORLD");
}# end run()

1;# return true:

