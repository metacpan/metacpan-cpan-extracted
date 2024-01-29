# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage)
use 5.014;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v1.1.7;
if ( !eval { require Test::TestCoverage; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Test::TestCoverage required for testing test coverage};
}
Test::More::plan 'tests' => 1;
Test::TestCoverage::test_coverage('Date::Extract::P800Picture');
Test::TestCoverage::test_coverage_except( 'Date::Extract::P800Picture',
    'meta' );
## no critic (RequireExplicitInclusion)
my $pic = Date::Extract::P800Picture->new();
$pic->filename(q{8B481234.JPG});
$pic->extract();

## no critic (ProhibitCallsToUnexportedSubs RequireEndWithOne)
Test::TestCoverage::ok_test_coverage('Date::Extract::P800Picture');
## use critic
