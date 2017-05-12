
package dev::edit;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;


sub run
{
  my ($s, $context) = @_;
  
  $Response->Write("Edit $Form->{type} id $Form->{id}");
}# end run()

1;# return true:

