
package DefaultApp::form;

use strict;
use warnings 'all';
use base 'ASP4x::Controller';
use vars __PACKAGE__->VARS;


handle get => sub {
  my ($s, $context) = @_;
  
  $Response->Write("Requested via 'GET'");
};


handle post => sub {
  my ($s, $context) = @_;
  
  $Response->Write("Requested via 'POST'");
};


1;# return true:

