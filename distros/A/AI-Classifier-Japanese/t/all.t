use strict;
use Test::More;

use AI::Classifier::Japanese;

my $classifier = AI::Classifier::Japanese->new();

my $CATEGORY_POSITIVE = "positive";
my $CATEGORY_NEGATIVE = "negative";

$classifier->add_training_text("たのしい", $CATEGORY_POSITIVE);
$classifier->add_training_text("楽しい", $CATEGORY_POSITIVE);
$classifier->add_training_text("つらい", $CATEGORY_NEGATIVE);
$classifier->add_training_text("辛い", $CATEGORY_NEGATIVE);
$classifier->train;

my $result_ref = $classifier->predict("たのしい");
my $result_posi = $result_ref->{$CATEGORY_POSITIVE};
my $result_nega = $result_ref->{$CATEGORY_NEGATIVE};

cmp_ok($result_posi, '>', 0.85,
    "Expected to be larger than 0.85, thoguh the value was $result_nega.");
cmp_ok($result_nega, '<', 0.50,
    "Expected to be smaller than 0.50, though the value was $result_nega.");

$result_ref = $classifier->predict("つらい");
$result_posi = $result_ref->{$CATEGORY_POSITIVE};
$result_nega = $result_ref->{$CATEGORY_NEGATIVE};

cmp_ok($result_posi, '<', 0.50,
    "Expected to be smaller than 0.50, though the value was $result_posi.");
cmp_ok($result_nega, '>', 0.85,
    "Expected to be larger than 0.85, thoguh the value was $result_nega.");

done_testing;
