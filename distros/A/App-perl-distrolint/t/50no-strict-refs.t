#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::NoStrictRefs;

my $check = App::perl::distrolint::Check::NoStrictRefs->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use strict;
no strict 'vars';
EOPERL
   [],
   'no diags from OK file' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use strict;
no strict 'refs';
EOPERL
   [ "lib/FILE.pm line 2 has 'no strict 'refs';'" ],
   'diag from no strict refs' );

done_testing;
