use Test::More tests => 1;
use Test::Output;

use Acme::Xyzzy;

stdout_is(\&xyzzy, "Nothing happens.\n", "Test xyzzy.");
