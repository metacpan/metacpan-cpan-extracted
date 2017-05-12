use strict;
use Test::More tests => 3;

use Date::Japanese::Holiday;

my $d = Date::Japanese::Holiday->new(2003, 11, 23);
my $d2 = Date::Japanese::Holiday->new(2003, 11, 24);
ok($d->is_holiday);
is($d->day_of_week, 7);
ok($d2->is_holiday);

