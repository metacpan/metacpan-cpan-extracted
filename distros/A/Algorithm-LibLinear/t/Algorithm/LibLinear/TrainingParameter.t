use strict;
use warnings;
use Test::Exception;
use Test::Deep;
use Test::More;

BEGIN { use_ok 'Algorithm::LibLinear' }

my $tolerance = 10e-15;

{
    my $learner = new_ok 'Algorithm::LibLinear';
    cmp_methods(
        $learner,
        [
            cost => num(1, $tolerance),
            epsilon => num(0.1, $tolerance),
            is_regression_solver => bool(0),
            weights => [],
        ],
    );
}

{
    my $learner = new_ok 'Algorithm::LibLinear' => [
        cost => 10,
        epsilon => 0.42,
        loss_sensitivity => 0.84,
        solver => 'L2R_L2LOSS_SVR_DUAL',
        weights => [
            +{ label => -1, weight => 0.6, },
            +{ label => 1, weight => 0.3, },
        ],
    ];
    cmp_methods(
        $learner,
        [
            cost => num(10, $tolerance),
            epsilon => num(0.42, $tolerance),
            is_regression_solver => bool(1),
            loss_sensitivity => num(0.84, $tolerance),
            weights => [
                +{ label => -1, weight => num(0.6, $tolerance), },
                +{ label => 1, weight => num(0.3, $tolerance), },
            ],
        ],
    );
}

throws_ok {
    Algorithm::LibLinear->new(cost => 0);
} qr/C <= 0/;

throws_ok {
    Algorithm::LibLinear->new(epsilon => 0);
} qr/eps <= 0/;

throws_ok {
    Algorithm::LibLinear->new(loss_sensitivity => -1);
} qr/p < 0/;

done_testing;
