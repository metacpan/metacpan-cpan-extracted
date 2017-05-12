use strict; use warnings;
package Acme::Math::XS;
our $VERSION = '0.0.5';

use Exporter 'import';
our @EXPORT = qw(
    add
    subtract
);

use Acme::Math::XS::Inline C => <<'...';
long add(long a, long b) {
    return a + b;
}

long subtract(long a, long b) {
    return a - b;
}
...

1;
