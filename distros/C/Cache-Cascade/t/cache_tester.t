use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "Cache::Tester is required for this test" unless eval { require Cache::Tester; Cache::Tester->import; 1 };
	plan 'no_plan'; # tests => 1 + $CACHE_TESTS;
}

use ok "Cache::Cascade";

use Cache::Memory;

my $cache = Cache::Cascade->new( caches => [ Cache::Memory->new ] );

run_cache_tests($cache);


