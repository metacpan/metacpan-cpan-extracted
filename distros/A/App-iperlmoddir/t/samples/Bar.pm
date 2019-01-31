package Bar;

use lib '.';
use parent 'Foo';
use Carp;
use Cwd;

sub abc {
    return 2 * 2;
}

sub print_info {
    print 'Some info';
}

1;
