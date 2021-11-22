package Crypt::Perl::X::InvalidJWK;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, @key_parts) = @_;

    return $class->SUPER::new( "Invalid JWK: [@key_parts]", { jwk => { @key_parts } } );
}

1;
