use warnings;
use strict;

use Test::More tests => 25;

BEGIN { use_ok "Data::ID::Exim", qw(base62 base36 read_base62 read_base36); }

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

is base36(8, 1097900471), "00I5NTFB";
is base36(6, 1097900471), "I5NTFB";
is base36(4, 1097900471), "NTFB";
is base36(0, 1097900471), "";
is read_base36("00I5NTFB"), 1097900471;
is read_base36(""), 0;

is_deeply [ base36(8, 1097900471) ], [ "00I5NTFB" ];
is_deeply [ base36(6, 1097900471) ], [ "I5NTFB" ];
is_deeply [ base36(4, 1097900471) ], [ "NTFB" ];
is_deeply [ base36(0, 1097900471) ], [ "" ];
is_deeply [ read_base36("00I5NTFB") ], [ 1097900471 ];
is_deeply [ read_base36("") ], [ 0 ];

1;
