use strict;
use warnings;
use Test::More;

use Devel::Peek;
use Cache::utLRU;

my $cache = Cache::utLRU->new();

# Prepare the key SV. Concatenation is to make sure that string is not marked
# copy-on-write, and perl can grow the buffer when we modify it below.
my $key = "foo" . "bar";
# Dump($key);

# Cache will store the PV pointer and length in the internal hash structure.
$cache->add($key, "value");

# Append to the string. This causes buffer to be re-allocated, leaving the key
# pointer in the hash dangling.
$key .= "straw that broke the camel's back";
# Dump($key);

# On lookup we locate the bucket, but key check in cache_find() will read from
# the freed memory when checking the key. This does not cause a crash on my
# machine, but is caught by valgrind.
my $val = $cache->find("foobar");
is $val, "value", "value was found";

done_testing;
