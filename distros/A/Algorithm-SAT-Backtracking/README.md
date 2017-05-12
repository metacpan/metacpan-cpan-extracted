[![Build Status](https://travis-ci.org/mudler/Algorithm-Sat-Backtracking.svg?branch=master)](https://travis-ci.org/mudler/Algorithm-Sat-Backtracking)
# NAME

Algorithm::SAT::Backtracking - A simple Backtracking SAT solver written in pure Perl

# SYNOPSIS

    # You can use it with Algorithm::SAT::Expression
    use Algorithm::SAT::Expression;

    my $expr = Algorithm::SAT::Expression->new->with("Algorithm::SAT::Backtracking"); #Uses Algorithm::SAT::Backtracking by default, so with() it's not necessary in this case
    $expr->or( '-foo@2.1', 'bar@2.2' );
    $expr->or( '-foo@2.3', 'bar@2.2' );
    $expr->or( '-baz@2.3', 'bar@2.3' );
    $expr->or( '-baz@1.2', 'bar@2.2' );
    my $model = $exp->solve();

    # Or you can use it directly:
    use Algorithm::SAT::Backtracking;
    my $solver = Algorithm::SAT::Backtracking->new;
    my $variables = [ 'blue', 'green', 'yellow', 'pink', 'purple' ];
    my $clauses = [
        [ 'blue',  'green',  '-yellow' ],
        [ '-blue', '-green', 'yellow' ],
        [ 'pink', 'purple', 'green', 'blue', '-yellow' ]
    ];

    my $model = $solver->solve( $variables, $clauses );

# DESCRIPTION

Algorithm::SAT::Backtracking is a pure Perl implementation of a simple SAT Backtracking solver.

In computer science, the Boolean Satisfiability Problem (sometimes called Propositional Satisfiability Problem and abbreviated as _SATISFIABILITY_ or _SAT_) is the problem of determining if there exists an interpretation that satisfies a given Boolean formula. In other words, it asks whether the variables of a given Boolean formula can be consistently replaced by the values **TRUE** or **FALSE** in such a way that the formula evaluates to **TRUE**. If this is the case, the formula is called satisfiable. On the other hand, if no such assignment exists, the function expressed by the formula is identically **FALSE** for all possible variable assignments and the formula is unsatisfiable.

For example, the formula "a AND NOT b" is satisfiable because one can find the values a = **TRUE** and b = **FALSE**, which make (a AND NOT b) = TRUE. In contrast, "a AND NOT a" is unsatisfiable. More: [https://en.wikipedia.org/wiki/Boolean\_satisfiability\_problem](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem) .

Have a look also at the tests file for an example of usage.

[Algorithm::SAT::Expression](https://metacpan.org/pod/Algorithm::SAT::Expression) use this module to solve Boolean expressions.

# METHODS

## solve()

The input consists of a boolean expression in Conjunctive Normal Form.
This means it looks something like this:

    `(blue OR green) AND (green OR NOT yellow)`

    We encode this as an array of strings with a `-` in front for negation:

       `[['blue', 'green'], ['green', '-yellow']]`

Hence, each row means an **AND**, while a list groups two or more **OR** clauses.

Returns 0 if the expression can't be solved with the given clauses, the model otherwise in form of a hash .

Have a look at [Algorithm::SAT::Expression](https://metacpan.org/pod/Algorithm::SAT::Expression) to see how to use it in a less painful way.

## resolve()

Uses the model to resolve some variable to its actual value, or undefined if not present.

    my $model = { blue => 1, red => 0 };
    my $a=$solver->resolve( "blue", $model );
    #$a = 1

## satisfiable()

Determines whether a clause is satisfiable given a certain model.

    my $model
        = { pink => 1, purple => 0, green => 0, yellow => 1, red => 0 };
    my $a=$solver->satisfiable( [ 'purple', '-pink' ], $model );
    #$a = 0

## update()

Copies the model, then sets \`choice\` = \`value\` in the model, and returns it.

    my $model
        = { pink => 1, red => 0, purple => 0, green => 0, yellow => 1 };
    my $new_model = $solver->update( $model, 'foobar', 1 );
    # now $new_model->{foobar} is 1

# LICENSE

Copyright (C) mudler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mudler <mudler@dark-lab.net>

# SEE ALSO

[Algorithm::SAT::Expression](https://metacpan.org/pod/Algorithm::SAT::Expression), [Algorithm::SAT::Backtracking::DPLL](https://metacpan.org/pod/Algorithm::SAT::Backtracking::DPLL), [Algorithm::SAT::Backtracking::Ordered](https://metacpan.org/pod/Algorithm::SAT::Backtracking::Ordered), [Algorithm::SAT::Backtracking::Ordered::DPLL](https://metacpan.org/pod/Algorithm::SAT::Backtracking::Ordered::DPLL)
