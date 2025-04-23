# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.016;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v0.0.7;
if ( !eval { require Test::TestCoverage; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Test::TestCoverage required for testing test coverage};
}
Test::More::plan 'tests' => 1;
TODO: {
    Test::More::todo_skip
      q{Fails on calling add_method on an immutable Moose object}, 1;
    Test::TestCoverage::test_coverage('Class::Measure::Scientific::FX_992vb');
    Test::TestCoverage::test_coverage_except(
        'Class::Measure::Scientific::FX_992vb', 'meta' );
## no critic (RequireExplicitInclusion)
    my $fx = Class::Measure::Scientific::FX_992vb->new();

    Test::TestCoverage::ok_test_coverage(
        'Class::Measure::Scientific::FX_992vb', );
## use critic
}
