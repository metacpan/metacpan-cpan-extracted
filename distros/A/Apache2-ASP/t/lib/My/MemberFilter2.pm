
package My::MemberFilter2;

use strict;
use warnings 'all';
use base 'My::MemberFilter';
use vars __PACKAGE__->VARS;

sub run
{
  my $s = shift;
  
#  warn "$s";
  return $Response->Declined;
}# end run()

1;# return true:

