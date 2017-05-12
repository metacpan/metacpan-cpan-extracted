
package
ASP4::SessionStateManager::NonPersisted;

use strict;
use warnings 'all';
use base 'ASP4::SessionStateManager';

sub new
{
  return bless { }, shift;
}# end new()

*create = *retrieve = \&new;

sub save { 1 }

1;# return true:

