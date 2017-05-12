#!perl -T

use Algorithm::Bayesian;
use Test::More;

my %hash;
my $s = Algorithm::Bayesian->new(\%hash);

is($s->getHam, 0);
is($s->getSpam, 0);

is($s->testWord('test'), 0.5);
is($s->test, 0.5);

done_testing;
