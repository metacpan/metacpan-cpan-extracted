
package My::Filter;

use strict;
use warnings 'all';
use base 'ASP4::RequestFilter';
use vars __PACKAGE__->VARS;

sub run {
  my ($s, $context) = @_;
  
#  warn "Filtering: $s";
  return $Response->Declined;
}

1;# return true:

