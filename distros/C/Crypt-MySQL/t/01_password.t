use strict;
use Test::More tests => 2;

use Crypt::MySQL ();

is(Crypt::MySQL::password("foobar"), "4655c05b05f11fab");
is(Crypt::MySQL::password41("foobar"), "*9B500343BC52E2911172EB52AE5CF4847604C6E5");
