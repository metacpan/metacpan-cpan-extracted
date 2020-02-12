package CBOR::Free::X::CannotDecode64Bit;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $numbin, $offset) = @_;

    my $numhex = sprintf(
        '%02x%02x_%02x%02x_%02x%02x_%02x%02x',
        unpack( 'C*', $numbin ),
    );

    return $class->SUPER::_new( sprintf('The CBOR buffer contains a 64-bit number (0x%s) at offset %d that this system cannot decode.', $numhex, $offset) )
}

1;
