#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::PerlVersionVar;

my $check = App::perl::distrolint::Check::PerlVersionVar->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
my $ok = $] >= 5.036;
EOPERL
   [],
   'no diags from OK file' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
my $ok = $] ge 5.036;
EOPERL
   [ "lib/FILE.pm line 1 applies stringy comparison operator to '\$]'" ],
   'diag from $] lhs of ge' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
my $ok = 5.036 lt $];
EOPERL
   [ "lib/FILE.pm line 1 applies stringy comparison operator to '\$]'" ],
   'diag from $] rhs of ge' );

done_testing;
