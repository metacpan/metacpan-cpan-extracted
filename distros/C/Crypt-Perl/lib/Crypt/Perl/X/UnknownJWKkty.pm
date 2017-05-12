package Crypt::Perl::X::UnknownJWKkty;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $kty) = @_;

    return $class->SUPER::new( "Unknown JWK “kty”: “$kty”", { kty => $kty } );
}

1;
