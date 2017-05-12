
package Apache2::ASP::SessionStateManager::NonPersisted;

use strict;
use warnings 'all';
use base 'Apache2::ASP::SessionStateManager';

sub new
{
  return bless { }, shift;
}# end new()

*create = *retrieve = \&new;

sub save { 1 }

1;# return true:

