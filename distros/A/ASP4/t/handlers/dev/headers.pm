
package dev::headers;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  $Response->ContentType("text/x-test");
  $Response->Expires( 500 );
  $Response->AddHeader("content-length" => 3000);
  $Response->Write( "X"x3000 );
  $Response->Flush;
}# end run()

1;# return true:

