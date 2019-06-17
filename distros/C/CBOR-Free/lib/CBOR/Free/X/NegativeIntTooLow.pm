package CBOR::Free::X::NegativeIntTooLow;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

use CBOR::Free::AddOne;

sub _new {
    my ($class, $abs, $offset) = @_;

    $abs = CBOR::Free::AddOne::to_nonnegative_integer($abs);

    return $class->SUPER::_new( sprintf('The CBOR buffer contains a negative number (-%s) at offset %u that is too low for this build of Perl to understand.', $abs, $offset) )
}

1;
