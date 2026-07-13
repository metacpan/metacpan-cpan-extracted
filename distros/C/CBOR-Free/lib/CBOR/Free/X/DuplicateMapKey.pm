package CBOR::Free::X::DuplicateMapKey;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $offset) = @_;

    return $class->SUPER::_new("Received a duplicate CBOR map key at offset $offset.");
}

1;
