use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use DBD::SQLite2;
$loaded++;

unlink("foo", "output/foo", "output/database", "output/datbase");

