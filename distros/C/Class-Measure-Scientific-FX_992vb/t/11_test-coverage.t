use strict;
use warnings;
use utf8;

use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Set $ENV{AUTHOR_TESTING} to run author tests.';
    plan( skip_all => $msg );
}

if ( !eval { require Test::TestCoverage; 1 } ) {
    plan skip_all => q{Test::TestCoverage required for testing test coverage};
}
plan tests => 1;
TODO: {
    todo_skip q{Fails on calling add_method on an immutable Moose object}, 1
      if 1;
    Test::TestCoverage::test_coverage('Class::Measure::Scientific::FX_992vb');
    Test::TestCoverage::test_coverage_except(
        'Class::Measure::Scientific::FX_992vb', 'meta' );
    my $obj = Class::Measure::Scientific::FX_992vb->new();

    Test::TestCoverage::ok_test_coverage(
        'Class::Measure::Scientific::FX_992vb');
}
