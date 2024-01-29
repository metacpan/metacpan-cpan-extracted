# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage)
use 5.014;
use strict;
use warnings;
use utf8;
use English qw(-no_match_vars);

use Test::More;
use DateTime;
use Test::Compile;

use Readonly;
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $BROKEN_VERSION => v5.6.2;

our $VERSION = v1.1.7;

BEGIN {
## no critic (RequireExplicitInclusion)
    @MAIN::METHODS = qw(extract filename);
    @MAIN::SCRIPTS = qw(bin/p800date bin/p800exif);
    ## no critic (ProhibitCallsToUnexportedSubs)
    Readonly::Scalar my $BASE_TESTS => 7;
    Test::More::plan 'tests' =>
      ( $BASE_TESTS + @MAIN::METHODS + 2 + @MAIN::SCRIPTS );
## use critic
    Test::More::ok(1);
    Test::More::use_ok('Date::Extract::P800Picture');
}
my $parser = Test::More::new_ok('Date::Extract::P800Picture');

## no critic (RequireExplicitInclusion)
@Date::Extract::P800Picture::Sub::ISA = qw(Date::Extract::P800Picture);
my $parser_sub = Test::More::new_ok('Date::Extract::P800Picture::Sub');

## no critic (RequireExplicitInclusion)
foreach my $method (@MAIN::METHODS) {
## use critic
    Test::More::can_ok( 'Date::Extract::P800Picture', $method );
}
my $datetime        = $parser->extract(q{8B421234.JPG});
my $datetime_master = DateTime->new(
    'year'      => 2008,
    'month'     => 12,
    'day'       => 5,
    'hour'      => 2,
    'time_zone' => 'UTC',
);
Test::More::is(
    ref $datetime,
    ref $datetime_master,
    'extract method returns DateTime object',
);

SKIP: {
    if ( $PERL_VERSION <= $BROKEN_VERSION ) {
        Test::More::skip 'is_deeply() has bogus fail on 5.6.2', 1;
    }
    Test::More::is_deeply( $datetime, $datetime_master,
        'extract method returns DateTime object with correct values' );
}

$parser = Date::Extract::P800Picture->new();
## no critic (RequireCheckingReturnValueOfEval)
Test::More::is( eval { $parser->extract(); },
    undef, 'unset filename error catch' );

my $test = Test::Compile->new();
$test->all_files_ok();
## no critic (RequireExplicitInclusion RequireEndWithOne)
for my $script (@MAIN::SCRIPTS) {
    $test->pl_file_compiles($script);
}
## use critic
