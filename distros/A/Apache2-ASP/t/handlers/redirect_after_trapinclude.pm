
package redirect_after_trapinclude;

use strict;
use warnings 'all';
use base 'Apache2::ASP::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  my $html = $Response->TrapInclude(
    $Server->MapPath('/index.asp')
  );
  
  return $Response->Redirect('/index.asp');
}# end run()

1;# return true:

