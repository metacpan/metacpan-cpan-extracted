use Test::More tests => 1;

use lib 't';

SKIP: {
    skip 'XXX - fix later', 1;
    eval <<'...';

package Foo;
use base 'Filter4';

...

    like $@, qr/\QClass::Spiffy must be loaded before calling 'use base'/,
        "Caught attempt to use 'base' on Class::Spiffy module before loading Class::Spiffy";
}
