use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Data::ID::Exim", qw(read_exim_mid); }

is_deeply([read_exim_mid("1CIg47-0003u7-18")],
	[1097900471, 35000, 15011]);
is_deeply([read_exim_mid("1CIg47-0003u7-3L", 1)],
	[1097900471, 35000, 15011, 1]);

1;
