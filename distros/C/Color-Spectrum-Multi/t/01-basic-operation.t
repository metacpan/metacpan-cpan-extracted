#!perl -T

use strict;
use Color::Spectrum::Multi;
use Test::More;

# Tests to perform.  Each consists of a set of parameters to pass, and a list of
# colours we expect to receive.
my @tests = (
    [
        [ 5, '#FF0000', '#00FF00' ],
        [ split /\s+/, '#FF0000 #E85500 #AAAA00 #55E800 #00FF00' ],
    ],
    [
        [7, '#FF0000', '#00FF00', '#0000FF'],
        [ split /\s+/, '#FF0000 #AAAA00 #00FF00 #00E855 #00AAAA #0055E8 #0000FF' ],
    ],
);

# Declare the number of tests we expect to run.  For each set of test data, we
# will run a set of 4 tests, twice.
plan tests => ( 2 * 4 ) * @tests;


# For each test, call the module both ways, and check the result looks as we
# expect (overkill, but doesn't hurt):
for my $test (@tests) {
    # Do this test procedurally:
    my @result = Color::Spectrum::Multi::generate(@{ $test->[0] });
    _check_result(\@result, $test->[1]);

    # And now OO-style:
    my $spectrum = Color::Spectrum::Multi->new;
    @result = $spectrum->generate(@{ $test->[0] });
    _check_result(\@result, $test->[1]);
}


# Ensure the result of a test looks good.
sub _check_result {
    my ($result, $test_expects) = @_;
    ok(ref $result eq 'ARRAY', "Got an array from this test");
    ok(@$result > 2, "Array contains at least two colours");
    is(@$result, @$test_expects, "Correct number of colours");
    is_deeply($result, $test_expects, "Got the colours we expected");
}


