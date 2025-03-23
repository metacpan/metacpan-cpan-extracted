# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.016;
use strict;
use warnings;

use Test::More;
my $test_warnings = $ENV{'AUTHOR_TESTING'} && eval { require Test::NoWarnings };

our $VERSION = v0.0.7;
if ( !$ENV{'TEST_SIGNATURE'} ) {
    Test::More::plan 'skip_all' =>
      q{Set the environment variable TEST_SIGNATURE to enable this test.};
}
if ( !eval { require Module::Signature; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{Next time around, consider installing Module::Signature, }
      . q{so you can verify the integrity of this distribution.};
}
if ( !-e 'SIGNATURE' ) {
    Test::More::plan 'skip_all' => q{SIGNATURE not found};
}
if ( -s 'SIGNATURE' == 0 ) {
    Test::More::plan 'skip_all' => q{SIGNATURE file empty};
}
if ( !eval { require Socket; Socket::inet_aton('pgp.mit.edu') } ) {
    Test::More::plan 'skip_all' =>
      q{Cannot connect to the keyserver to check module } . q{signature};
}
Test::More::plan 'tests' => 1 + 1;

my $ret = Module::Signature::verify();

SKIP: {
## no critic (ProhibitCallsToUnexportedSubs)
    if ( $ret eq Module::Signature::CANNOT_VERIFY() ) {
## use critic
        Test::More::skip q{Module::Signature cannot verify}, 1;
    }
    Test::More::cmp_ok $ret, q{==}, Module::Signature::SIGNATURE_OK(),
      q{Valid signature};
}

## no critic (RequireInterpolationOfMetachars)
my $msg = q{Author test. Install Test::NoWarnings and set }
  . q{$ENV{AUTHOR_TESTING} to a true value to run.};
SKIP: {
    if ( !$test_warnings ) {
        Test::More::skip $msg, 1;
    }
}
$test_warnings && Test::NoWarnings::had_no_warnings();
