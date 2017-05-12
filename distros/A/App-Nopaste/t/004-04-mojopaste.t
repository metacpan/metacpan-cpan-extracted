use strict;
use warnings;

use Test::More 0.88;

use App::Nopaste::Service::Mojopaste;

is(App::Nopaste::Service::Mojopaste->uri, 'https://ssl.thorsen.pm/paste');

done_testing;
