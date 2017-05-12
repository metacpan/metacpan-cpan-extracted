use strict;
use warnings;
use Cache::Tester;
use Carp;

$SIG{__DIE__} = sub { confess @_; };

BEGIN { plan tests => 2 + $CACHE_TESTS }

use_ok('Cache::Memory');

# Test basic get/set and remove

my $cache = Cache::Memory->new();
ok($cache, 'Cache returned');

run_cache_tests($cache);
