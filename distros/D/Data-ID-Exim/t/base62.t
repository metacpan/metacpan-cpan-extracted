use warnings;
use strict;

use Test::More tests => 13;

BEGIN { use_ok "Data::ID::Exim", qw(base62 read_base62); }

is base62(8, 1097900471), "001CIg47";
is base62(6, 1097900471), "1CIg47";
is base62(4, 1097900471), "Ig47";
is base62(0, 1097900471), "";
is read_base62("001CIg47"), 1097900471;
is read_base62(""), 0;

is_deeply [ base62(8, 1097900471) ], [ "001CIg47" ];
is_deeply [ base62(6, 1097900471) ], [ "1CIg47" ];
is_deeply [ base62(4, 1097900471) ], [ "Ig47" ];
is_deeply [ base62(0, 1097900471) ], [ "" ];
is_deeply [ read_base62("001CIg47") ], [ 1097900471 ];
is_deeply [ read_base62("") ], [ 0 ];

1;
