use strict;
use Test::More tests => 2;

use Date::Japanese::Holiday qw(is_japanese_holiday);

ok(is_japanese_holiday(2000, 1, 1));
ok(is_japanese_holiday(2002, 11, 23));
