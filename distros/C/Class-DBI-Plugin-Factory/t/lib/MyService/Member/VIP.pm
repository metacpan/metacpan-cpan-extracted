package MyService::Member::VIP;
use strict;
use base qw/MyService::Member/;
sub is_free { 0 }
sub monthly_cost { 250 }
1;

