# t/00-load.t
use strict;
use warnings;
use Test::More tests => 2;
use Test::NoWarnings 'had_no_warnings';

BEGIN {
    use_ok('CLI::Cmdline') or BAIL_OUT("Can't load CLI::Cmdline");
}

had_no_warnings();
done_testing;
