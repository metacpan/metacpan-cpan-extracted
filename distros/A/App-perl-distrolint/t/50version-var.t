#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::VersionVar;

my $check = App::perl::distrolint::Check::VersionVar->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package v1.23;
EOPERL
   [],
   'no diags from OK file using package VER' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
our $VERSION = v1.23;
EOPERL
   [ "lib/FILE.pm line 2 has an assignment to '\$VERSION'" ],
   'diag from file with assign to $VERSION' );

done_testing;
