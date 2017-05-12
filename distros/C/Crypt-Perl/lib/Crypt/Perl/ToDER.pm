package Crypt::Perl::ToDER;

use strict;
use warnings;

use Crypt::Format ();

#Modifies in-place.
sub ensure_der {
    if ( $_[0] =~ m<\A-> ) {
        $_[0] = Crypt::Format::pem2der($_[0]);
    }

    return;
}

1;
