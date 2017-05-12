package Crypt::Perl::JWK;

use strict;
use warnings;

use MIME::Base64 ();

use Crypt::Perl::BigInt ();

sub jwk_num_to_bigint {
    return Crypt::Perl::BigInt->from_bytes( MIME::Base64::decode_base64url($_[0]));
}

1;
