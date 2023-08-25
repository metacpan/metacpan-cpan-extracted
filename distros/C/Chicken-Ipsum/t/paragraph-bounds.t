#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';
use List::Util qw/ max min /;
use Chicken::Ipsum;
my $ci = Chicken::Ipsum->new;

my @paragraphs = $ci->paragraphs(100);
my $separator = join '|', map { quotemeta } @{+Chicken::Ipsum::PUNCTUATIONS};
my @sentence_counts = map {
    scalar split /(?:$separator)+\s*/
} @paragraphs;

# Smoke test
cmp_ok(Chicken::Ipsum::MIN_PARAGRAPH_SENTENCES, '>', 0,
    'constant MIN_PARAGRAPH_SENTENCES value'
);
cmp_ok(Chicken::Ipsum::MAX_PARAGRAPH_SENTENCES, '>', Chicken::Ipsum::MIN_PARAGRAPH_SENTENCES,
    'constant MAX_PARAGRAPH_SENTENCES value'
);

cmp_ok(max(@sentence_counts), '<=', Chicken::Ipsum::MAX_PARAGRAPH_SENTENCES,
    'max sentence count from ->paragraphs() should not be above MAX_PARAGRAPH_SENTENCES'
);

cmp_ok(min(@sentence_counts), '>=', Chicken::Ipsum::MIN_PARAGRAPH_SENTENCES,
    'min sentence count from ->paragraphs() should not be below MIN_PARAGRAPH_SENTENCES'
);
