use strict;
use Test2::V0;
use BettingStrategy::MonteCarlo;

subtest 'array' => sub {

    # new
    my $strategy = BettingStrategy::MonteCarlo->new(+{array => +[1, 2, 3, 5, 8]});
    isa_ok $strategy, 'BettingStrategy::MonteCarlo';

    is $strategy->bet, 9;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 5, 8, 9];
    ok !$strategy->is_finished;

    is $strategy->bet, 10;
    $strategy->won;
    is $strategy->array, +[2, 3, 5, 8];
    ok !$strategy->is_finished;

    is $strategy->bet, 10;
    $strategy->lost;
    is $strategy->array, +[2, 3, 5, 8, 10];
    ok !$strategy->is_finished;

    is $strategy->bet, 12;
    $strategy->won;
    is $strategy->array, +[3, 5, 8];
    ok !$strategy->is_finished;

    is $strategy->bet, 11;
    $strategy->lost;
    is $strategy->array, +[3, 5, 8, 11];
    ok !$strategy->is_finished;

    is $strategy->bet, 14;
    $strategy->won;
    is $strategy->array, +[5, 8];
    ok !$strategy->is_finished;

    is $strategy->bet, 13;
    $strategy->lost;
    is $strategy->array, +[5, 8, 13];
    ok !$strategy->is_finished;

    is $strategy->bet, 18;
    $strategy->won;
    is $strategy->array, +[8];
    ok $strategy->is_finished;

    like dies { $strategy->bet },  qr{\Qfinished\E};
    like dies { $strategy->won },  qr{\Qfinished\E};
    like dies { $strategy->lost }, qr{\Qfinished\E};
};

done_testing;
__END__
