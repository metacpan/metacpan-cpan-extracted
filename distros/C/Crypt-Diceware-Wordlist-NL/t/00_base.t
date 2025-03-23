# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.016;
use strict;
use warnings;
use utf8;
use Readonly;

use Test::More;
my $test_warnings = $ENV{'AUTHOR_TESTING'} && eval { require Test::NoWarnings };

our $VERSION = v0.0.1;

BEGIN {
## no critic (RequireExplicitInclusion)
    @MAIN::METHODS = qw();
## no critic (RequireExplicitInclusion ProhibitCallsToUnexportedSubs)
    Readonly::Scalar my $BASE_TESTS => 2;
    Test::More::plan 'tests' => ( $BASE_TESTS + @MAIN::METHODS ) + 1;
    Test::More::ok(1);
    Test::More::use_ok('Crypt::Diceware::Wordlist::NL');
}
Test::More::diag(
    q{Testing Crypt::Diceware::Wordlist::NL }
## no critic (ProhibitCallsToUnexportedSubs RequireExplicitInclusion)
      . $Crypt::Diceware::Wordlist::NL::VERSION,
);

## no critic (RequireExplicitInclusion)
@Crypt::Diceware::Wordlist::NL::Sub::ISA = qw(Crypt::Diceware::Wordlist::NL);

## no critic (RequireInterpolationOfMetachars)
my $msg = q{Author test. Install Test::NoWarnings and set }
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
SKIP: {
    if ( !$test_warnings ) {
        Test::More::skip $msg, 1;
    }
}
$test_warnings && Test::NoWarnings::had_no_warnings();
