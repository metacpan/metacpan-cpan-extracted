# t/00-load.t
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Datafile::Array') or BAIL_OUT("Can't load Datafile::Array");
}

done_testing;
