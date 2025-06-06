# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.016;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v0.0.7;
if ( !eval { require Test::Pod; 1 } ) {
    Test::More::plan 'skip_all' => q{Test::Pod required for testing POD};
}
## no critic (ProhibitCallsToUnexportedSubs)
Test::Pod::all_pod_files_ok();
## use critic
