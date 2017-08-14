use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Data::ID::Exim", qw(exim_mid_time exim_mid36_time); }

is exim_mid_time(1097900471), "1CIg47";
is_deeply [ exim_mid_time(1097900471) ], [ "1CIg47" ];

is exim_mid36_time(1097900471), "I5NTFB";
is_deeply [ exim_mid36_time(1097900471) ], [ "I5NTFB" ];

1;
