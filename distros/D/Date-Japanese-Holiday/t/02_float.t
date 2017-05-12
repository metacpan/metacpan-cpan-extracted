use strict;
use Test::More tests => 6;

use Date::Japanese::Holiday;

ok(Date::Japanese::Holiday->new(2002, 1, 14)->is_holiday);
ok(Date::Japanese::Holiday->new(2003, 7, 21)->is_holiday);
ok(Date::Japanese::Holiday->new(2003, 9, 15)->is_holiday);
ok(Date::Japanese::Holiday->new(2003, 10, 13)->is_holiday);
ok(Date::Japanese::Holiday->new(1999, 1, 15)->is_holiday);
ok(!Date::Japanese::Holiday->new(1999, 1, 11)->is_holiday);


