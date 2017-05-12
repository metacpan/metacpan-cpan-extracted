use Test::More tests => 1;

BEGIN{
   local $ENV{PLOCK_PASSWORD} = "test";
}

use_ok App::PerlXLock;
