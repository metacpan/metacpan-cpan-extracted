#!perl

use Test::More tests => 3;

BEGIN {use_ok('Data::Domain', qw/:all !Date/); }

ok(Int(),         'Int was imported');
ok(!eval{Date()}, 'Date was not imported');


