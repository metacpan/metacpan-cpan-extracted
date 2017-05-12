use strict; use warnings;
package Acme::Math::XS;
# our $VERSION = 'x.x.x';

use Exporter 'import';
our @EXPORT = qw(
    add
    subtract
);

use Acme::Math::XS::Inline CPP => <<'...';
long add(long a, long b) {
    return a + b;
}

long subtract(long a, long b) {
    return a - b;
}
...

1;
