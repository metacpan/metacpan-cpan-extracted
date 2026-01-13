#!/usr/bin/perl

use v5.36;

use Test2::V0;

use lib 't/lib';
use TestCheck;

use App::perl::distrolint::Check::PostfixDeref;

my $check = App::perl::distrolint::Check::PostfixDeref->new;

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
${ scalarvar };
${ scalarreffunc() };

@{ arrayvar };
@{ arrayreffunc() };

%{ hashvar };
%{ hashreffunc() };
EOPERL
   [],
   'no diags from derefs in empty scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.24;

${ scalarvar };
${ scalarreffunc() };

@{ arrayvar };
@{ arrayreffunc() };

%{ hashvar };
%{ hashreffunc() };
EOPERL
   [ "lib/FILE.pm line 4 dereferences SCALAR without postfix-deref",
     "lib/FILE.pm line 7 dereferences ARRAY without postfix-deref",
     "lib/FILE.pm line 10 dereferences HASH without postfix-deref" ],
   'diags from derefs in v5.24 scope' );

is( [ diags_from_treesitter( $check, <<'EOPERL' ) ],
use v5.24;

${'Some::Package::VAR'};
${"Some::Package::VAR"};
@{'Some::Package::VAR'};
@{"Some::Package::VAR"};
%{'Some::Package::VAR'};
%{"Some::Package::VAR"};
EOPERL
   [],
   'Symbolic references do not cause diags in v5.24 scope' );

done_testing;
