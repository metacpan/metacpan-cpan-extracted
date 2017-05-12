use strict;
use Test::More tests => 1;

use Date::Japanese::Holiday;

my $d = Date::Japanese::Holiday->new(2002, 5, 4);
ok($d->is_holiday);

