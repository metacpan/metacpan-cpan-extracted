use strict;
use warnings;

use Business::PL::NIP qw(is_valid_nip);
use Test::More tests => 2;

my ($valid_nip, $invalid_nip) = qw(1234563218 1234567890);


# functional interface

ok(is_valid_nip( $valid_nip ), "positively verifies valid nip number");

ok (!is_valid_nip( $invalid_nip ), "invalid nip detected");

