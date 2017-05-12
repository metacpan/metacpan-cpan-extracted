use strict;

use Test::More tests => 1;

require_ok('AnyEvent::Timer::Cron')
    || BAIL_OUT("Stopping due to compile failure!");
