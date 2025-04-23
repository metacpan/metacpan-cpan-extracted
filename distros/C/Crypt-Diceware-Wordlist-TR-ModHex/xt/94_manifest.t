# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage)
use 5.016;
use strict;
use warnings;
use utf8;

use Test::More 'tests' => 2;

our $VERSION = v0.0.7;
if ( !eval { require ExtUtils::Manifest; 1 } ) {
    Test::More::plan 'skip_all' =>
      q{ExtUtils::Manifest required to check manifest};
}
use ExtUtils::Manifest;
## no critic (ProhibitCallsToUnexportedSubs RequireEndWithOne)
Test::More::is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
Test::More::is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
## use critic
