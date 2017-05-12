package MyService::Member::Basic;
use strict;
use base qw/MyService::Member/;
sub is_free { 0 }
sub monthly_cost { 500 }

1;

