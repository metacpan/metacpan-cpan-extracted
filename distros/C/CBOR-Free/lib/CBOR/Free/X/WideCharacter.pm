package CBOR::Free::X::WideCharacter;

use strict;
use warnings;

use parent qw( CBOR::Free::X::Base );

use Text::Control ();

sub _new {
    my ($class, $value) = @_;

    my $hex = Text::Control::to_hex($value);

    $hex = _escape_multibyte($hex);

    return $class->SUPER::_new("Cannot encode wide character(s): “$hex”");
}

sub _escape_multibyte {
    my ($value) = @_;

    for my $i ( reverse 0 .. (length($value) - 1) ) {
        my $chr = substr( $value, $i, 1 );

        if (ord $chr > 0xff) {
            substr( $value, $i, 1, sprintf "\\x{%x}", ord $chr );
        }
    }

    utf8::encode($value);

    return "$value";
}

1;
