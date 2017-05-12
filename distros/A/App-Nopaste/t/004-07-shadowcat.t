use strict;
use warnings;

use Test::More 0.88;

use App::Nopaste::Service::Shadowcat;

is(App::Nopaste::Service::Shadowcat->uri, 'http://paste.scsys.co.uk');

done_testing;
