use strict;
use Test::More;

use AI::Classifier::Japanese;

my $classifier = AI::Classifier::Japanese->new();

my $CATEGORY_POSITIVE = "positive";
my $CATEGORY_NEGATIVE = "negative";

# nothing
$classifier->add_training_text("", $CATEGORY_POSITIVE);

# space
$classifier->add_training_text(" ", $CATEGORY_POSITIVE);

# normal text
$classifier->add_training_text("大学　社畜", $CATEGORY_NEGATIVE);

# english
$classifier->add_training_text("university corporate slave", $CATEGORY_NEGATIVE);

isnt($classifier->train, undef);

done_testing;
