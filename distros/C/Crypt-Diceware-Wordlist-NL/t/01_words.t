#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use 5.016;
use utf8;
use Readonly;

use Test::More;
my $test_warnings = $ENV{'AUTHOR_TESTING'} && eval { require Test::NoWarnings };

our $VERSION = v0.0.1;

BEGIN {
## no critic (RequireExplicitInclusion ProhibitCallsToUnexportedSubs)
    Readonly::Scalar my $TESTS => 2;
## use critic
    Test::More::plan 'tests' => ( $TESTS + 1 );
    Test::More::use_ok('Crypt::Diceware::Wordlist::NL');
}

## no critic (RequireExplicitInclusion ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $REQUIRED_WORDS => 6**5;
Readonly::Scalar my $PACKAGE        => q{Crypt::Diceware::Wordlist::NL::Words};
## use critic

my $words = do {
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    ## use critic
    \@{$PACKAGE};
};
Test::More::is(
    scalar @{$words},
    $REQUIRED_WORDS, qq{List contains $REQUIRED_WORDS words},
);

my $msg = q{Author test. Install Test::NoWarnings and set }
## no critic (RequireInterpolationOfMetachars)
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
## use critic
SKIP: {
    if ( !$test_warnings ) {
        Test::More::skip $msg, 1;
    }
}
$test_warnings && Test::NoWarnings::had_no_warnings();
