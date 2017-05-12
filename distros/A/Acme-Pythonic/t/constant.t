BEGIN { if ($^V && $^V ge v5.8.0) { eval "use Test::More 'no_plan'; use Acme::Pythonic;" } else { eval "use Test::More skip_all => 'This test needs at least 5.8.0'; exit" }}

use constant FOO => 0
use constant BAR => 1

use constant {BAZ => 2,
              MOO => 3,
              ZOO => 4,}

$foo = 5

is FOO, 0
is BAR, 1
is BAZ, 2
is MOO, 3
is ZOO, 4
is $foo, 5
