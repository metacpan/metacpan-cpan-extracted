use strict;
use warnings;
use Test::More tests => 207;
use Algorithm::BloomFilter;

my $bf = Algorithm::BloomFilter->new(33, 1);
isa_ok($bf, "Algorithm::BloomFilter");

is($bf->test("foo"), 0);
$bf->add("foo");
is($bf->test("foo"), 1);
$bf->add("foo", "bar", "baz");
is($bf->test("bar"), 1);
is($bf->test("baz"), 1);

# Large bloom filter with known case and hash function
# is known to be sufficiently accurate for these tests
# not to fail.
$bf = Algorithm::BloomFilter->new(1e6, 5);
my $n = 200;
my @d = (1..$n);

for (@d) {
  is($bf->test($_), 0, "'$_' not in");
}

for (@d) {
  $bf->add($_);
}

my $n_in = 0;
$n_in += $bf->test($_) for @d;
ok($n_in == $n, "items are in");

my $n_not_in = 0;
$n_not_in += $bf->test($_) for ($n+1 .. 2*$n);
is($n_not_in, 0, "false items are not in");
