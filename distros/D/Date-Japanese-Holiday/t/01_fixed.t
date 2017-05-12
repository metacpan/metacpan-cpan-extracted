use strict;
use Test::More tests => 12;

use Date::Japanese::Holiday;

ok(Date::Japanese::Holiday->new(2000, 1, 1)->is_holiday);
ok(Date::Japanese::Holiday->new(1999, 1, 15)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 2, 11)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 4, 29)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 5, 3)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 5, 5)->is_holiday);
ok(Date::Japanese::Holiday->new(1997, 7, 20)->is_holiday);
ok(Date::Japanese::Holiday->new(1997, 9, 15)->is_holiday);
ok(Date::Japanese::Holiday->new(1997, 10, 10)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 11, 3)->is_holiday);
ok(Date::Japanese::Holiday->new(2002, 11, 23)->is_holiday);
ok(Date::Japanese::Holiday->new(1997, 10, 10)->is_holiday);

