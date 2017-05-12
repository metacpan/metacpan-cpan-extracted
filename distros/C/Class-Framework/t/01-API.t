use warnings;
use strict;

use Test::More tests=>8;

our $CMV = "Class::MethodVars"; # Name is not yet set in stone.
our $CU = "Class::Framework"; # Ditto.

ok eval qq{require $CMV; 1},"Load $CMV";
ok eval qq{require $CU; 1},"Load $CU";

ok $CMV->can("import"),"$CMV has an import facility";
ok $CU->can("import"),"$CU has an import facility";

ok eval '$'.$CMV.'::VERSION' >= 1.0,"$CMV version looks valid";
ok eval '$'.$CU.'::VERSION' >= 1.0,"$CU version looks valid";

ok $CMV->can("Method"),"$CMV has a Method definition";
ok $CMV->can("ClassMethod"),"$CU has a ClassMethod definition";
