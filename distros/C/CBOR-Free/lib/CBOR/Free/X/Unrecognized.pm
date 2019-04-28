package CBOR::Free::X::Unrecognized;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $alien) = @_;

    return $class->SUPER::_new("Cannot encode to CBOR: $alien");
}

1;
