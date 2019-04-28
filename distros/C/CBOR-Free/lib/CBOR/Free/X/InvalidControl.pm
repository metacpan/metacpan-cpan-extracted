package CBOR::Free::X::InvalidControl;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $ord, $offset) = @_;

    return $class->SUPER::_new(sprintf 'Found invalid control byte %02x at offset %d.', $ord, $offset);
}

1;
