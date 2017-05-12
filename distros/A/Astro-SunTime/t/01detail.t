
use strict;
use Test;

BEGIN { plan tests => 16, todo => [] }

use Astro::SunTime;

# use of the "date" parameter requires the use of Time::ParseDate by the module

ok(sun_time(type => 'rise', latitude => 40, longitude => -77, time_zone => -5, date => '1 Jan 1970'), '7:30');
ok(sun_time(type => 'set',  latitude => 40, longitude => -77, time_zone => -5, date => '1 Jan 1970'), '16:54');
ok(sun_time(type => 'rise', latitude => 40, longitude => -77, time_zone => -4, date => '1 Sep 1970'), '6:35');
ok(sun_time(type => 'set',  latitude => 40, longitude => -77, time_zone => -4, date => '1 Sep 1970'), '19:40');
ok(sun_time(type => 'rise', latitude => 40, longitude => -77, time_zone => -5, date => '1 Jan 2020'), '7:30');
ok(sun_time(type => 'set',  latitude => 40, longitude => -77, time_zone => -5, date => '1 Jan 2020'), '16:54');
ok(sun_time(type => 'rise', latitude => 40, longitude => -77, time_zone => -4, date => '1 Sep 2020'), '6:36');
ok(sun_time(type => 'set',  latitude => 40, longitude => -77, time_zone => -4, date => '1 Sep 2020'), '19:38');

ok(sun_time(type => 'rise', latitude => -45, longitude => 170, time_zone => 12, date => '1 Jan 1970'), '4:57');
ok(sun_time(type => 'set',  latitude => -45, longitude => 170, time_zone => 12, date => '1 Jan 1970'), '20:30');
ok(sun_time(type => 'rise', latitude => -45, longitude => 170, time_zone => 12, date => '1 Sep 1970'), '7:10');
ok(sun_time(type => 'set',  latitude => -45, longitude => 170, time_zone => 12, date => '1 Sep 1970'), '18:11');
ok(sun_time(type => 'rise', latitude => -45, longitude => 170, time_zone => 12, date => '1 Jan 2020'), '4:57');
ok(sun_time(type => 'set',  latitude => -45, longitude => 170, time_zone => 12, date => '1 Jan 2020'), '20:30');
ok(sun_time(type => 'rise', latitude => -45, longitude => 170, time_zone => 12, date => '1 Sep 2020'), '7:08');
ok(sun_time(type => 'set',  latitude => -45, longitude => 170, time_zone => 12, date => '1 Sep 2020'), '18:12');


