use strict;
use Test2::V0;
use BettingStrategy::MonteCarlo;

subtest 'magnification => valid' => sub {

    # new
    my $strategy = BettingStrategy::MonteCarlo->new(+{magnification => 3});
    isa_ok $strategy, 'BettingStrategy::MonteCarlo';

    # array
    {
        my $got      = $strategy->array;
        my $expected = +[qw{1 2 3}];
        is $got, $expected;
    }

    # bet
    {
        my $got      = $strategy->bet;
        my $expected = 4;
        is $got, $expected;
    }

    # won
    {
        $strategy->won;
        my $got      = $strategy->array;
        my $expected = +[];
        is $got, $expected;
    }

    # is_finished
    ok $strategy->is_finished;
};

subtest 'magnification => invalid' => sub {
    like dies { BettingStrategy::MonteCarlo->new(+{magnification => 4}) },     qr{\Qmagnification is 2 or 3\E};
    like dies { BettingStrategy::MonteCarlo->new(+{magnification => ''}) },    qr{\Qinvalid magnification\E};
    like dies { BettingStrategy::MonteCarlo->new(+{magnification => undef}) }, qr{\Qinvalid magnification\E};
};

subtest 'magnification => valid 2' => sub {

    # new
    my $strategy = BettingStrategy::MonteCarlo->new(+{magnification => 3});
    isa_ok $strategy, 'BettingStrategy::MonteCarlo';

    is $strategy->bet, 4;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 4];
    ok !$strategy->is_finished;

    is $strategy->bet, 5;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 4, 5];
    ok !$strategy->is_finished;

    is $strategy->bet, 6;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 4, 5, 6];
    ok !$strategy->is_finished;

    is $strategy->bet, 7;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 4, 5, 6, 7];
    ok !$strategy->is_finished;

    is $strategy->bet, 8;
    $strategy->lost;
    is $strategy->array, +[1, 2, 3, 4, 5, 6, 7, 8];
    ok !$strategy->is_finished;

    is $strategy->bet, 9;
    $strategy->won;
    is $strategy->array, +[3, 4, 5, 6];
    ok !$strategy->is_finished;

    is $strategy->bet, 9;
    $strategy->lost;
    is $strategy->array, +[3, 4, 5, 6, 9];
    ok !$strategy->is_finished;

    is $strategy->bet, 12;
    $strategy->won;
    is $strategy->array, +[5];
    ok $strategy->is_finished;

    like dies { $strategy->bet },  qr{\Qfinished\E};
    like dies { $strategy->won },  qr{\Qfinished\E};
    like dies { $strategy->lost }, qr{\Qfinished\E};
};

done_testing;
__END__
