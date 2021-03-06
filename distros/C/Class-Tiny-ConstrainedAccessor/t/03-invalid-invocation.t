#!perl
use 5.006;
use strict;
use warnings;
use lib::relative '.';
use MY::Kit;

require Class::Tiny::ConstrainedAccessor;

# A dummy placeholder constraint
{
    package SuperSimpleConstraint;
    use Class::Tiny { dummy => 0xdeadbeef };
    sub check { 1 }
    sub name { __PACKAGE__ }    # For coverage testing
}
my $constraint = SuperSimpleConstraint->new;

# An object that does not support check() or any of the other assertion
# routines we know how to use.
{
    package NotAConstraint;
    use Class::Tiny { dummy => 0xdeadbeef };
    sub description { __PACKAGE__ }     # For coverage testing
}
my $nonconstraint = NotAConstraint->new;

# An object that supports inline_check() for a non-inlineable type.
# This is for coverage.
{
    package NonInlineableConstraint;
    use Class::Tiny { dummy => 0xdeadbeef };
    sub inline_check { '@invalid syntax!' }
    sub name { "" }     # For coverage testing - a falsy value
}
my $niconstraint = NonInlineableConstraint->new;

# Tests to run: description => [arguments to use()]
my %tests = (
    'Rejects one argument' => ['foo'],
    'Rejects three arguments' => ['foo', $constraint, 'bar'],
    'Rejects undef constraint' => ['foo', undef],
    'Rejects undef constraint as part of several' => ['foo', undef, 1, $constraint],
    'Rejects scalar constraint' => ['foo', 42],
    'Rejects scalar constraint' => ['foo', 'wow'],
    'Rejects non-blessed constraint' => ['foo', {}],
    'Rejects constraint that cannot assert_valid' => ['foo', $nonconstraint],
    'Rejects non-inlineable constraint' => ['foo', $niconstraint],
    'Rejects glob' => ['foo', \*STDOUT],

    'Rejects custom constraint with empty array' => ['foo', []],
    'Rejects custom constraint with array too large' => ['foo', [1..3]],
    'Rejects custom constraint with non-coderef checker' =>
        ['foo', [0, sub{}]],
    'Rejects custom constraint with non-coderef get_message' =>
        ['foo', [sub{}, 0]],
);

foreach my $test (keys %tests) {
    dies_ok {
        package T1;
        Class::Tiny::ConstrainedAccessor->import(@{$tests{$test}});
    } $test;
}

done_testing();
