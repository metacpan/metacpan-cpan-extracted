#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::StrictAndWarnings;

my $check = App::perl::distrolint::Check::StrictAndWarnings->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
use strict;
use warnings;
my $five = 5;
EOPERL
   [],
   'no diags from OK file using strict+warnings' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
use v5.36;
my $five = 5;
EOPERL
   [],
   'no diags from OK file using VERSION' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
package My::Package;
my $five = 5;
EOPERL
   [ "lib/FILE.pm line 2 has a statement before use strict",
     "lib/FILE.pm line 2 has a statement before use warnings", ],
   'diag from file without strict/warnings' );

done_testing;
