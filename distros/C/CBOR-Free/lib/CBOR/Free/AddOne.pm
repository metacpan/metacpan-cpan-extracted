package CBOR::Free::AddOne;

use strict;
use warnings;

# Hard to believe there’s not some simple module out there
# that already does this.

sub to_nonnegative_integer {
    my @digits = unpack '(a)*', shift();

    my $done;

    my $carry = 1;

    for my $d ( reverse( 0 .. $#digits ) ) {
        $digits[$d] += $carry;
        $carry = 0;

        if ($digits[$d] > 9) {
            $carry = $digits[$d] - 9;
            $digits[$d] = 0;
        }

        last if !$carry;
    }

    return join( q<>, $carry || (), @digits );
}

1;
