use strict;
use Test::More tests => 2;
use Acme::NumericMethod;

is one_hundred(), 100, "One_hundred";
is one_million_forty_two(), 1000042, "One million and 42";
