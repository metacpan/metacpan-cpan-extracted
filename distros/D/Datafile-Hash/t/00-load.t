# t/00-load.t
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Datafile::Hash') or BAIL_OUT("Can't load Datafile::Hash");
}

done_testing;
