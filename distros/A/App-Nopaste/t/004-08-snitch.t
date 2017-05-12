use strict;
use warnings;

use Test::More 0.88;

use App::Nopaste::Service::Snitch;

is(App::Nopaste::Service::Snitch->uri, 'http://nopaste.snit.ch');

done_testing;
