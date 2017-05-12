
package dev::create;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;


sub run
{
  my ($s, $context) = @_;
  
  $Response->Write("Create $Form->{type}");
}# end run()

1;# return true:

