package CBOR::Free::X::InvalidUTF8;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

use Text::Control ();

sub _new {
    my ($class, $bin) = @_;

    $bin = Text::Control::to_hex($bin);

    return $class->SUPER::_new("Received an invalid UTF-8 string: “$bin”");
}

1;

