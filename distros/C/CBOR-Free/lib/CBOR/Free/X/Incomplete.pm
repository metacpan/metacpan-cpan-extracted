package CBOR::Free::X::Incomplete;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $lack) = @_;

    return $class->SUPER::_new("Expected at least $lack more byte(s).");
}

1;
