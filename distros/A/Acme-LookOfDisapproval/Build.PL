use 5.016;
use Module::Build::Tiny 0.030;
Build_PL();

use File::Spec::Functions;
use utf8;
rename catfile(qw(lib Acme o_o.pm)), catfile(qw(lib Acme ಠ_ಠ.pm));
