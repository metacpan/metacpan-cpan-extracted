use strict;
use Test::More 0.98;

BEGIN {
    use_ok 'Cache::Redis';
}

diag "Testing Cache::Redis/$Cache::Redis::VERSION";

done_testing;
