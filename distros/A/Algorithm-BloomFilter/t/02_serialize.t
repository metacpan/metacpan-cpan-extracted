use strict;
use warnings;
use Test::More tests => 12;
use Algorithm::BloomFilter;

my $bf = Algorithm::BloomFilter->new(2000, 3);
isa_ok($bf, "Algorithm::BloomFilter");

$bf->add(qw(foo bar baz));
is($bf->test($_), 1) for qw(foo bar baz);

my $blob = $bf->serialize;
ok(defined $blob);

$bf = Algorithm::BloomFilter->deserialize($blob);
isa_ok($bf, "Algorithm::BloomFilter");
is($bf->test($_), 1) for qw(foo bar baz);
is($bf->test($_), 0) for qw(foo1 bar1 baz1);

