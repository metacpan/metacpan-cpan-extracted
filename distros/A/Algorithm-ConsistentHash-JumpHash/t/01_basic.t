use strict;
use warnings;
use Test::More tests => 8;
use Algorithm::ConsistentHash::JumpHash;

my $hashval;
my $prev;

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_numeric(123, 1);
is($hashval, 0, "trivial case");

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_numeric(123, 1);
is($hashval, 0, "trivial case consistent");

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_numeric(121233, 12);
ok($hashval >= 0 && $hashval < 12, "output in bucket range");

$prev = $hashval;
$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_numeric(121233, 12);
is($hashval, $prev, "Consistent in the same process at least");

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_siphash("foobar", 1);
is($hashval, 0, "trivial case");

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_siphash("foobar", 1);
is($hashval, 0, "trivial case consistent");

$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_siphash("foobar", 14);
ok($hashval >= 0 && $hashval < 14, "output in bucket range");

$prev = $hashval;
$hashval = Algorithm::ConsistentHash::JumpHash::jumphash_siphash("foobar", 14);
is($hashval, $prev, "Consistent in the same process at least");

