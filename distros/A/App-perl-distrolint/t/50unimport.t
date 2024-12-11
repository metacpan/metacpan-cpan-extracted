#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::Unimport;

my $check = App::perl::distrolint::Check::Unimport->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
sub import {}
sub unimport {}
EOPERL
   [],
   'no diags from OK file with import+unimport' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
sub elsewise {}
EOPERL
   [],
   'no diags from OK file with neither' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
sub import {}
EOPERL
   [ "lib/FILE.pm has sub import but no sub unimport" ],
   'diag from file without unimport' );

done_testing;
