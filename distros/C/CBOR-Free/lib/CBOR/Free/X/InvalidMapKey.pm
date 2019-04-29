package CBOR::Free::X::InvalidMapKey;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

use Text::Control ();

sub _new {
    my ($class, $what, $offset) = @_;

    return $class->SUPER::_new("Received CBOR $what as a map key (offset: $offset), which Perl doesn’t understand.");
}

1;
