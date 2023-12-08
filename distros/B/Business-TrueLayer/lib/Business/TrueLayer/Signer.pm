package Business::TrueLayer::Signer;

=head1 NAME

Business::TrueLayer::Signer - Class to handle request signing TrueLayer
requests as described by https://github.com/TrueLayer/truelayer-signing/blob/main/request-signing-v2.md

=head1 DESCRIPTION

To use the TrueLayer Payments API v3, you need a public and private key
pair. You can generate these however you want, but we recommend OpenSSL
on Windows or LibreSSL on macOS or Linux. These methods are usually
available on these operating systems by default.

To generate your private key, run the following command in your terminal.
The keys you generate will save to your current directory.

    openssl ecparam -genkey -name secp521r1 -noout -out ec512-private-key.pem

Then, to generate your public key, run this command in your terminal.

    openssl ec -in ec512-private-key.pem -pubout -out ec512-public-key.pem

You then need to upload the public key to the TrueLayer console.

Having done that you can supply the path to your private key when using
the main L<Business::TrueLayer> module. You shouldn't need to do anything
else here, the distribution will handle signing when creating requests.

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Types;

use Crypt::JWT qw/ encode_jwt /;

has 'kid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'private_key' => (
    is       => 'ro',
    isa      => 'EC512:PrivateKey',
    coerce   => 1,
    required => 1,
);

sub sign_request (
    $self,
    $http_verb,
    $absolute_path,
    $idempotency_key,
    $serialized_http_request_body = undef,
) {
    $http_verb = uc( $http_verb );

    my $jws_token = encode_jwt(
        alg        => 'ES512',
        key        => $self->private_key,

        extra_headers => {
            kid        => $self->kid,
            tl_version => "2",
            tl_headers => "Idempotency-Key",
        },

        payload    => join(
            "\n",grep { defined }
                "$http_verb $absolute_path",
               "Idempotency-Key: $idempotency_key",
                $serialized_http_request_body
        ),
    );

    # we need to "detach" the payload from the JWS, so basically remove
    # the middle bit
    my ( $header,$payload,$signature) = split( /\./,$jws_token );
    my $jws_token_with_detached_payload = join( '..',$header,$signature );

    return (
        $jws_token_with_detached_payload,
        $jws_token
    );
}

1;

# vim: ts=4:sw=4:et
