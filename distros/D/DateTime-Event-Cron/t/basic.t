use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use DateTime::Event::Cron;
$loaded++;
