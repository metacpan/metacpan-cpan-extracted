package CBOR::Free::X::Recursion;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $max_recursion) = @_;

    return $class->SUPER::_new("Refuse to encode() more than $max_recursion times at once!");
}

1;
