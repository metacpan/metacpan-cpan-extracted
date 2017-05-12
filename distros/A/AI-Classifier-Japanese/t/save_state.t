use strict;
use Test::More;
use Test::File;

use AI::Classifier::Japanese;

my $classifier = AI::Classifier::Japanese->new();

my $PARAMS_PATH = "param_dummy.dat";
my $CATEGORY_POSITIVE = "positive";
my $CATEGORY_NEGATIVE = "negative";

$classifier->add_training_text("たのしい", $CATEGORY_POSITIVE);
$classifier->add_training_text("つらい", $CATEGORY_NEGATIVE);
$classifier->train;

$classifier->save_state($PARAMS_PATH);

file_exists_ok($PARAMS_PATH);

$classifier->restore_state($PARAMS_PATH);

my $result_ref = $classifier->predict("学校は明日あるよ");
print "Positive :" . $result_ref->{positive} . "\n";
print "Negative :" . $result_ref->{negative} . "\n";
$result_ref = $classifier->predict("学校に昨日行ったよ");
print "Positive :" . $result_ref->{positive} . "\n";
print "Negative :" . $result_ref->{negative} . "\n";

done_testing;

