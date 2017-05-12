#!perl

# sanity test

use Date::Extract::ID;
use Test::More 0.98;

my $dt = Date::Extract::ID->extract("28 feb 2011");
is($dt->ymd, "2011-02-28");
done_testing;
