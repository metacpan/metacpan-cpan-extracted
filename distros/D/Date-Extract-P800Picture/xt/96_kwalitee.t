# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage RequireEndWithOne)
use 5.014;
use strict;
use warnings;
use utf8;

use Test::More;

our $VERSION = v1.1.7;
if ( !eval { require Test::Kwalitee; 1 } ) {
    Test::More::plan( 'skip_all' => 'Test::Kwalitee not installed; skipping' );
}
Test::Kwalitee->import( 'tests' => [qw( -has_meta_yml)] );
