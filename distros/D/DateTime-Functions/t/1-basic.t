use strict;
use Test;

BEGIN { plan tests => 2 }

use DateTime;
use DateTime::Functions;

ok(DateTime->now, now());
ok(DateTime->today, today());

1;
