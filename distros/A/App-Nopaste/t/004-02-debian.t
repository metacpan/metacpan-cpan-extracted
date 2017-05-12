use strict;
use warnings;

use Test::More 0.88;

use App::Nopaste::Service::Debian;

is(App::Nopaste::Service::Debian->uri, 'https://paste.debian.net/');

done_testing;
