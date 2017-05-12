package Crypt::Perl::X::ASN1::Encode;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $args_ar, $error) = @_;

    return $class->SUPER::new( "Failed to encode ASN.1 data (@$args_ar): $error", { variables => $args_ar, error => $error } );
}

1;
