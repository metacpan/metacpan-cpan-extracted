use strict;
use Test::More;

use AI::Classifier::Japanese;

my $classifier = AI::Classifier::Japanese->new();

my $CATEGORY_POSITIVE = "positive";
my $CATEGORY_NEGATIVE = "negative";

$classifier->add_training_text("たのしい", $CATEGORY_POSITIVE);

my @labels = $classifier->labels;
my $labels_num = $classifier->labels;

is($labels_num, 1);
is($labels[0], $CATEGORY_POSITIVE);

done_testing;
