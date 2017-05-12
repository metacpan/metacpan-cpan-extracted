package Crypt::Perl::X::TooLongToSign;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $key_bits, $signee_bits) = @_;

    return $class->SUPER::new( "A $key_bits-bit key cannot sign a $signee_bits-bit payload!", { key_bits => $key_bits, payload_bits => $signee_bits } );
}

1;
