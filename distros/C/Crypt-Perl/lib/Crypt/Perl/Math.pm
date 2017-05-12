package Crypt::Perl::Math;

use strict;
use warnings;

use Crypt::Perl::BigInt ();
use Crypt::Perl::RNG ();

sub ceil {
    return int($_[0]) if $_[0] <= 0;

    return int($_[0]) + int( !!($_[0] - int $_[0]) );
}

#limit is inclusive
#cf. Python’s random.randint()
sub randint {
    my ($limit) = @_;

    my $limit_bit_count;
    if (ref($limit) && (ref $limit)->isa('Math::BigInt')) {
        $limit_bit_count = length($limit->as_bin()) - 2;
    }

    #Is this ever needed??
    else {
        $limit_bit_count = length sprintf '%b', $limit;
    }

    my $rand;
    do {
        $rand = Crypt::Perl::BigInt->from_bin( Crypt::Perl::RNG::bit_string($limit_bit_count) );
    } while $rand > $limit;

    return $rand;
}

1;
