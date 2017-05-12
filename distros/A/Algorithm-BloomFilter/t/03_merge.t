use strict;
use warnings;
use Test::More tests => 40;
use Algorithm::BloomFilter;

my $bf  = Algorithm::BloomFilter->new(128, 4);
my $bf1 = Algorithm::BloomFilter->new(128, 4);
my $bf2 = Algorithm::BloomFilter->new(128, 4);

$bf->add(1..20);

$bf1->add(1..10);
$bf2->add(11..20);

$bf1->merge($bf2);

is($bf1->test($_), $bf->test($_)) for 1..40;

