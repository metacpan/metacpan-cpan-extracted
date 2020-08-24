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

my $data_set = Algorithm::LibLinear::DataSet->new(data_set => [
    +{ feature => +{}, label => 1 },
]);

my @cases = (
    +{ constructor_params => [ cost => 0 ], error_pattern => qr/C <= 0/ },
    +{ constructor_params => [ epsilon => 0 ], error_pattern => qr/eps <= 0/ },
    +{
        constructor_params => [ loss_sensitivity => -1 ],
        error_pattern => qr/p < 0/,
    },
);
for my $case (@cases) {
    my $learner = Algorithm::LibLinear->new(@{ $case->{constructor_params} });
    throws_ok {
        $learner->train(data_set => $data_set);
    } $case->{error_pattern};
    throws_ok {
        $learner->cross_validation(data_set => $data_set, num_folds => 5);
    } $case->{error_pattern};
}

done_testing;
