# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bank-Holidays.t'

#########################

use Test::More tests => 2;
use_ok(Bank::Holidays);
is($Bank::Holidays::VERSION, "0.86", "VERSION check");
