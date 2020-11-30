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
Test::TestCoverage::test_coverage('Date::Extract::P800Picture');
Test::TestCoverage::test_coverage_except( 'Date::Extract::P800Picture', 'meta' );
my $obj = Date::Extract::P800Picture->new();
$obj->filename("8B481234.JPG");
$obj->extract();

Test::TestCoverage::ok_test_coverage('Date::Extract::P800Picture');
