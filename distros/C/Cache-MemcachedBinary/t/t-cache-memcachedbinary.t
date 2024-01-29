use strict;
use warnings;

use Test::More tests => 2;
use Cache::MemcachedBinary;

BEGIN { use_ok('Cache::MemcachedBinary') };

# create object
my $obj_mem = Cache::MemcachedBinary->new();
ok( $obj_mem, "create Cache::MemcachedBinary object" );

done_testing;