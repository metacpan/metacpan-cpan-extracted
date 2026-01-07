# t/00-load.t
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('CLI::Cmdline') or BAIL_OUT("Can't load CLI::Cmdline");
}

done_testing;
