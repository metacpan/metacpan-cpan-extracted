# 00_compile.t - Just make sure Acme::AutoLoad compiles

use Test::More tests => 1;
BEGIN { use_ok('Acme::AutoLoad') };
