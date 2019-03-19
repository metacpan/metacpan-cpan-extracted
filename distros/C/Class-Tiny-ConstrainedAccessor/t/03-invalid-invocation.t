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
}
my $constraint = SuperSimpleConstraint->new;

# An object that does not support check() or any of the other assertion
# routines we know how to use.
{
    package NotAConstraint;
    use Class::Tiny { dummy => 0xdeadbeef };
}
my $nonconstraint = NotAConstraint->new;

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
);

foreach my $test (keys %tests) {
    dies_ok {
        package T1;
        Class::Tiny::ConstrainedAccessor->import(@{$tests{$test}});
    } $test;
}

done_testing();
