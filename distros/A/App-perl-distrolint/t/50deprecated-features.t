#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::DeprecatedFeatures;

my $check = App::perl::distrolint::Check::DeprecatedFeatures->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use feature 'say', "try";
EOPERL
   [],
   'no diags from OK file' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use feature "switch";
EOPERL
   [ "lib/FILE.pm line 1 uses feature 'switch'" ],
   'diag from use feature switch' );

done_testing;
