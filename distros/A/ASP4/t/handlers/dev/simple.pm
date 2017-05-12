
package dev::simple;

use common::sense;
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  $Response->Write("Hello from 'dev::simple'");
}# end run()

1;# return true:

