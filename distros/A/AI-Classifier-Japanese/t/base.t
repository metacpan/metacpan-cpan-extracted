use strict;
use Test::More;

use_ok $_ for qw(
    AI::Classifier::Japanese
);

my $classifier = AI::Classifier::Japanese->new();

isa_ok($classifier, 'AI::Classifier::Japanese');

can_ok($classifier, $_) for qw(
    train
    predict
    add_training_text
    save_state
    restore_state
);

done_testing;
