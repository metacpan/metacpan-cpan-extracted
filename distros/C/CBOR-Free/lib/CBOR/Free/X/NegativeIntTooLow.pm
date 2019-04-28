package CBOR::Free::X::NegativeIntTooLow;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

sub _new {
    my ($class, $abs, $offset) = @_;

    return $class->SUPER::_new( sprintf('The CBOR buffer contains a negative number (-%u) at offset %u that is too low for this build of Perl to understand.', $abs, $offset) )
}

1;
