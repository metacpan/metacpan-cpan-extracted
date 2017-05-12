use strict;
use Test::More 0.98;
use Data::Dumper;

use Algorithm::SAT::Backtracking;

my $agent = Algorithm::SAT::Backtracking->new;

#Testing resolve

subtest "resolve()" => sub {
    my $t_model = { blue => 1, red => 0 };
    is( $agent->resolve( "blue", $t_model ),
        1, "'blue' in the test model should be true" );
    is( $agent->resolve( "-red", $t_model ),
        1, "'-red' in the test model should be true" );
    is( $agent->resolve( "-blue", $t_model ),
        0, "'-blue' in the test model should be false" );
    is( $agent->resolve( "-yellow", $t_model ),
        undef, "'-yellow' in the test model should be undef" );

};

#Testing Satisfiable
subtest "satisfiable()" => sub {
    my $t2_model
        = { pink => 1, purple => 0, green => 0, yellow => 1, red => 0 };
    is( $agent->satisfiable( [ 'purple', '-pink' ], $t2_model ),
        0, "Clause 'purple -pink' unsatisfiable" );
    is( $agent->satisfiable( [ 'orange', '-blue' ], $t2_model ),
        undef, "Clause 'orange -blue' satisfiable = 'undef'" );
    is( $agent->satisfiable( [ 'yellow', '-blue' ], $t2_model ),
        1, "Clause 'yellow -blue' satisfiable = 'true' " );
    is( $agent->satisfiable( [ 'pink', 'orange', '-blue' ], $t2_model ),
        1, "Clause 'pink orange -blue' = '1" );
    is( $agent->satisfiable(
            [ 'chair', 'table', 'coffee', 'satan' ], $t2_model
        ),
        undef,
        "Clause 'chair table coffee satan' satisfiable = 'undef"
    );
};

# Testing Update

subtest "update()" => sub {
    my $t_model
        = { pink => 1, red => 0, purple => 0, green => 0, yellow => 1 };
    my $new_model = $agent->update( $t_model, 'foobar', 1 );
    is( $t_model->{foobar}, undef, "old model doesn't have 'foobar'" );
    $new_model->{test} = 0;
    is( $t_model->{test}, undef, "old model it's not affected by new one" );
    is( $new_model->{foobar}, 1, "new model was updated" );
};

# Testing solve
subtest "solve()" => sub {
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    my $model = $agent->solve( $variables, $clauses );
    foreach my $c ( @{$clauses} ) {
        is( $agent->satisfiable( $c, $model ),
            1, "'@{$c}' is satisfiable against model" );
    }

    $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    $model = $agent->solve( $variables, $clauses );
    is( ref $model, "HASH", "Backtrack returned a model" );
    is_deeply(
        $model,
        { blue => 1, yellow => 1, green => 1 },
        "Testing if the returned model satisfy the boolean expression"
    );

    my $clauses = [
        [ '-foo@2.1', 'bar@2.2' ],
        [ '-foo@2.3', 'bar@2.2' ],
        [ '-baz@2.3', 'bar@2.3' ],
        [ '-baz@1.2', 'bar@2.2' ],
    ];
    $variables = [ 'foo@2.1', 'bar@2.2', 'foo@2.3', 'baz@2.3', 'bar@2.3',
        'baz@1.2' ];
    $model = $agent->solve( $variables, $clauses );
    is( ref $model, "HASH", "Backtrack returned a model" );
    is_deeply(
        $model,
        {   'foo@2.3' => 1,
            'foo@2.1' => 1,
            'baz@2.3' => 1,
            'bar@2.3' => 1,
            'bar@2.2' => 1
        },
        "Testing if the returned model satisfy the boolean expression"
    );

};
done_testing;
