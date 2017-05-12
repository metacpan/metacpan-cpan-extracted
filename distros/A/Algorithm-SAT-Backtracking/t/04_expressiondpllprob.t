use strict;
use Test::More 0.98;
use Algorithm::SAT::Backtracking;

#plan skip_all   => 'Still experimental';
use Algorithm::SAT::Expression;
use Algorithm::SAT::Backtracking::DPLLProb;

subtest "and()" => sub {
    my $expr = Algorithm::SAT::Expression->new->with(
        "Algorithm::SAT::Backtracking::DPLLProb");
    $expr->and( "blue", "green" );
    $expr->and('pink');
    ok( defined $expr->{_literals}->{pink},
        'expression contains a clause [pink]'
    );
    ok( defined $expr->{_literals}->{blue},
        'expression contains a clause [blue]'
    );

    ok( defined $expr->{_literals}->{green},
        'expression contains a clause [green]'
    );
    ok( !!grep { "@{$_}" eq "pink" } @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq "blue" } @{ $expr->{_expr} } );
};

subtest "or()" => sub {
    my $expr = Algorithm::SAT::Expression->new->with(
        "Algorithm::SAT::Backtracking::DPLLProb");
    $expr->or( "blue", "green" );
    $expr->or('pink');
    $expr->or( 'purple', '-yellow', 'green' );
    ok( !!grep { "@{$_}" eq "blue green" } @{ $expr->{_expr} } );
    $expr = Algorithm::SAT::Expression->new->with(
        "Algorithm::SAT::Backtracking::DPLLProb");
    my $prob = Algorithm::SAT::Backtracking::DPLLProb->new;
    $expr->or( '-foo@2.1', 'bar@2.2' );
    $expr->or( '-foo@2.3', 'bar@2.2' );
    $expr->or( '-baz@2.3', 'bar@2.3' );
    $expr->or( '-baz@1.2', 'bar@2.2' );
    ok( !!grep { "@{$_}" eq join( " ", '-foo@2.1', 'bar@2.2' ) }
            @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq join( " ", '-foo@2.3', 'bar@2.2' ) }
            @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq join( " ", '-baz@2.3', 'bar@2.3' ) }
            @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq join( " ", '-baz@1.2', 'bar@2.2' ) }
            @{ $expr->{_expr} } );
    my $model = $expr->solve;
     #XXX: ?
    foreach my $clause ( @{ $expr->{_expr} } ) {
        is( $prob->satisfiable( $clause, $model ),
            1, "@{$clause} is satisfiable against the model" );
    }

};

subtest "xor()" => sub {
    my $expr = Algorithm::SAT::Expression->new->with(
        "Algorithm::SAT::Backtracking::DPLLProb");
    $expr->xor( "foo", "bar" );
    ok( !!grep { "@{$_}" eq "-foo -bar" } @{ $expr->{_expr} } );
    $expr->xor( "foo", "bar", "baz" );
    ok( !!grep { "@{$_}" eq "foo bar baz" } @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq "-foo -bar" } @{ $expr->{_expr} } );
    ok( !!grep { "@{$_}" eq "-bar -baz" } @{ $expr->{_expr} } );
};

subtest "solve()" => sub {
    my $exp = Algorithm::SAT::Expression->new->with(
        "Algorithm::SAT::Backtracking::DPLLProb");
    my $backtrack = Algorithm::SAT::Backtracking->new;
    $exp->or( 'blue',  'green',  '-yellow' );
    $exp->or( '-blue', '-green', 'yellow' );
    $exp->or( 'pink',  'purple', 'green', 'blue', '-yellow' );
    my $model = $exp->solve();
    foreach my $clause ( @{ $exp->{_expr} } ) {
        is( $backtrack->satisfiable( $clause, $model ),
            1, "@{$clause} is satisfiable against the model" );
    }
};

subtest "_pure()" => sub {
    my $agent = Algorithm::SAT::Backtracking::DPLLProb->new;

    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple', 'z' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];

    my $model = $agent->solve( $variables, $clauses );
    is( $agent->_pure("yellow"), 0, "yellow is impure" );
    is( $agent->_pure("green"),  0, "green is impure" );
    is( $agent->_pure("pink"),   1, "pink is pure" );
    is( $agent->_pure("z"),      0, "z is impure" );

};

#todo: testfiles for _remove_literal , _up and _pure
subtest "_remove_literal()" => sub {
    my $agent = Algorithm::SAT::Backtracking::DPLLProb->new;

    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink',  'purple', 'green', 'blue', '-yellow', 'blue' ], ['-z']
    ];

    $agent->_remove_literal( "blue", $clauses );

    is_deeply(
        $clauses,
        [   [ 'green', '-yellow' ],
            [ '-blue', '-green', 'yellow' ],
            [ 'pink', 'purple', 'green', '-yellow' ],
            ['-z']
        ],
        "removing blue from the model"
    );

};

subtest "_up()" => sub {
    my $agent     = Algorithm::SAT::Backtracking::DPLLProb->new;
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple', 'z' ];
    my $clauses   = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink',  'purple', 'green', 'blue', '-yellow', 'z' ], ['-z']
    ];

    my $model = $agent->_up( $variables, $clauses );
    is( $model->{z}, 0, "z is false" );
    is_deeply( $model, { z => 0 }, "model is correct" );
    is_deeply(
        $clauses,
        [   [ 'blue',  'green',  '-yellow' ],
            [ '-blue', '-green', 'yellow' ],
            [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
            ['-z']
        ],
        "z is removed from OR clauses"
    );
};

subtest "_pure()" => sub {
    my $agent = Algorithm::SAT::Backtracking::DPLLProb->new;

    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple', 'z' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];

    my $model = $agent->solve( $variables, $clauses );
    is( $agent->_pure("yellow"), 0, "yellow is impure" );
    is( $agent->_pure("green"),  0, "green is impure" );
    is( $agent->_pure("pink"),   1, "pink is pure" );
    is( $agent->_pure("z"),      0, "z is impure" );

};

subtest "_remove_clause_if_contains()" => sub {
    my $agent = Algorithm::SAT::Backtracking::DPLLProb->new;

    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple', 'z' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];

    $agent->_remove_clause_if_contains( "yellow", $clauses );
    is_deeply(
        $clauses,
        [   [ 'blue', 'green', '-yellow' ],
            [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
            ['-z']
        ],
        "clauses containing yellow were removed"
    );

    $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];
    $agent->_remove_clause_if_contains( "green", $clauses );
    is_deeply(
        $clauses,
        [ [ '-blue', '-green', 'yellow' ], ['-z'] ],
        "clauses containing green were removed"
    );

    $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];
    $agent->_remove_clause_if_contains( "-green", $clauses );
    is_deeply(
        $clauses,
        [   [ 'blue', 'green', '-yellow' ],
            [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
            ['-z']
        ],
        "clauses containing -green were removed"
    );
    $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ['-z']
    ];
    $agent->_remove_clause_if_contains( "-z", $clauses );
    is_deeply(
        $clauses,
        [   [ 'blue',  'green',  '-yellow' ],
            [ '-blue', '-green', 'yellow' ],
            [ 'pink', 'purple', 'green', 'blue', '-yellow' ],
        ],
        "clauses containing -z were removed"
    );

};
done_testing;
