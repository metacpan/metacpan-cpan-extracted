use strict;
use warnings;
use Test::More;

use Devel::Peek;
use Cache::utLRU;

my $cache = Cache::utLRU->new();

# Prepare the key SV. Concatenation is to make sure the PV buffer is not marked
# as copy-on-write, and assignment below modifies the buffer itself, instead of
# changing the PV pointer.
my $key = "foo"."bar";
# Dump($key);

# Cache will store the PV pointer and length in the internal hash structure.
$cache->add($key, "value");

# Change the buffer. This will change the memory that internal key pointer is
# pointing to. PV pointer should have the same address as before in this dump.
$key = "baz";
# Dump($key);

# On lookup, we can locate the bucket, but since the memory at the keyptr has changed,
# we don't get the match.
my $val = $cache->find("foobar");
is $val, "value", "value found";

done_testing;
