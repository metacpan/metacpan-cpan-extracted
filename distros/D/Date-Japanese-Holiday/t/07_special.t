use strict;
use Test::More tests => 3;

use Date::Japanese::Holiday;

my $d = Date::Japanese::Holiday->new(1989, 2, 24);
ok($d->is_holiday);
my $d2 = Date::Japanese::Holiday->new(1990, 11, 12);
ok($d2->is_holiday);
my $d3 = Date::Japanese::Holiday->new(1993, 6, 9);
ok($d3->is_holiday);

