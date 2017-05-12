
package Apache2::ASP::ApplicationStateManager::NonPersisted;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ApplicationStateManager';

sub new
{
  return bless { }, shift;
}# end new()

*create = *retrieve = \&new;

sub save { 1 }

1;# return true:

