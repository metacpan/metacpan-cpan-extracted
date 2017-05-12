package MyService::Member::Free;
use strict;
use base qw/MyService::Member/;
sub is_free { 1 }
sub monthly_cost{ 0 }
1;

