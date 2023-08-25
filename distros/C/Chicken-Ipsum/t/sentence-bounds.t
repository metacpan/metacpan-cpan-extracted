#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';
use List::Util qw/ max min /;
use Chicken::Ipsum;
my $ci = Chicken::Ipsum->new;

my @sentences = $ci->sentences(100);
my @word_counts = map {
    scalar split /\s+/
} @sentences;

# Smoke test
cmp_ok(Chicken::Ipsum::MIN_SENTENCE_WORDS, '>', 0,
    'constant MIN_SENTENCE_WORDS value'
);
cmp_ok(Chicken::Ipsum::MAX_SENTENCE_WORDS, '>', Chicken::Ipsum::MIN_SENTENCE_WORDS,
    'constant MAX_SENTENCE_WORDS value'
);

cmp_ok(max(@word_counts), '<=', Chicken::Ipsum::MAX_SENTENCE_WORDS,
    'max word count from ->sentences() should not be above MAX_SENTENCE_WORDS'
);

cmp_ok(min(@word_counts), '>=', Chicken::Ipsum::MIN_SENTENCE_WORDS,
    'min word count from ->sentences() should not be below MIN_SENTENCE_WORDS'
);
