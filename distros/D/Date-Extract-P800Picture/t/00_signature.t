# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.014;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v1.1.7;
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
Test::More::plan 'tests' => 1;

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
