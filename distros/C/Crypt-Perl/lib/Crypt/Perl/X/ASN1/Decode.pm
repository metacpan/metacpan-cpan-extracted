package Crypt::Perl::X::ASN1::Decode;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $pdu, $error) = @_;

    return $class->SUPER::new( "Failed to decode ASN.1 data ($pdu): $error", { pdu => $pdu, error => $error } );
}

1;
