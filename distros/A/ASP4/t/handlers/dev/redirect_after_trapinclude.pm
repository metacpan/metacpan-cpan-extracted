
package dev::redirect_after_trapinclude;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  my $html = $Response->TrapInclude(
    $Server->MapPath("/index.asp")
  );
  $context->{did_send_headers} = 0;
  
  return $Response->Redirect("/static.txt");
}# end run()

1;# return true:

