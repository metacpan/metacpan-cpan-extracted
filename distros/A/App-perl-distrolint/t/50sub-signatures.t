#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::SubSignatures;

my $check = App::perl::distrolint::Check::SubSignatures->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
sub ok { }
EOPERL
   [],
   'no diags from nonsig sub in empty scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.36;
sub ok ($x) { }
EOPERL
   [],
   'no diags from sig sub in v5.36 scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use feature 'signatures';
sub ok ($x) { }
EOPERL
   [],
   'no diags from sig sub in use-feature-signatures scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.36;
sub ok1 () { }
sub ok2 ( ) { }
EOPERL
   [],
   'Empty () counts as a signature' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.36;
sub ok1 ($) { }
sub ok2 ( $ ) { }
sub ok3 (@) { }
sub ok4 (%) { }
EOPERL
   [],
   'Single ($), (@) or (%) counts as a signature' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.36;
sub notok { ... }
my $code = sub { ... };
EOPERL
   [ "lib/FILE.pm line 2 declares a sub without signature",
     "lib/FILE.pm line 3 declares a sub without signature" ],
   'diag from nonsig sub in v5.36 scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use feature 'signatures';
sub notok { ... }
my $code = sub { ... };
EOPERL
   [ "lib/FILE.pm line 2 declares a sub without signature",
     "lib/FILE.pm line 3 declares a sub without signature" ],
   'diag from nonsig sub in use-feature-signatures scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use feature 'signatures';
{
   no feature 'signatures';
   sub inner1 {}
}
sub outer {
   no feature 'signatures';
   sub inner2 {}
}
EOPERL
   [ "lib/FILE.pm line 6 declares a sub without signature" ],
   'SubSignatures understands nested scopes' );

done_testing;
