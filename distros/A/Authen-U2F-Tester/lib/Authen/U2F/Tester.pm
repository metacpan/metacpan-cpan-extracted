#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester;
$Authen::U2F::Tester::VERSION = '0.03';
# ABSTRACT: FIDO/U2F Authentication Test Client

use Moose;

use strictures 2;
use Authen::U2F::Tester::Const qw(OK DEVICE_INELIGIBLE);
use Authen::U2F::Tester::Error;
use Authen::U2F::Tester::Keypair;
use Authen::U2F::Tester::RegisterResponse;
use Authen::U2F::Tester::SignResponse;
use Crypt::OpenSSL::X509;
use Crypt::PK::ECC;
use Digest::SHA qw(sha256);
use JSON::MaybeXS qw(encode_json);
use List::Util qw(first);
use MIME::Base64 qw(encode_base64url decode_base64url);
use namespace::autoclean;

my $COUNTER = 0;


has key => (
    is       => 'ro',
    isa      => 'Crypt::PK::ECC',
    required => 1);


has keystore => (
    is       => 'ro',
    does     => 'Authen::U2F::Tester::Role::Keystore',
    required => 1);


has certificate => (
    is       => 'ro',
    isa      => 'Crypt::OpenSSL::X509',
    required => 1);

around BUILDARGS => sub {
    my ($orig, $self) = splice @_, 0, 2;

    if (@_ > 1) {
        my %args = @_;

        if (my $keyfile = delete $args{key_file}) {
            $args{key} = Crypt::PK::ECC->new($keyfile);
        }

        if (my $certfile = delete $args{cert_file}) {
            $args{certificate} = Crypt::OpenSSL::X509->new_from_file($certfile);
        }

        # if no keystore was given, use the wrapped keystore
        unless (defined $args{keystore}) {
            require Authen::U2F::Tester::Keystore::Wrapped;
            $args{keystore} = Authen::U2F::Tester::Keystore::Wrapped->new(key => $args{key});
        }

        return $self->$orig(%args);
    }
    else {
        return $self->$orig(@_);
    }
};


sub register {
    my ($self, $app_id, $challenge, @registered_handles) = @_;

    # check if this device has already been registered
    for my $registered (@registered_handles) {
        if ($self->keystore->exists($registered)) {
            return Authen::U2F::Tester::Error->new(DEVICE_INELIGIBLE);
        }
    }

    # generate a new keypair for this application
    my $keypair = Authen::U2F::Tester::Keypair->new;
    my $handle  = $self->keystore->put($keypair->private_key);
    my $cert    = $self->certificate->as_string(Crypt::OpenSSL::X509::FORMAT_ASN1);

    my %client_data = (
        typ        => 'navigator.id.finishEnrollment',
        challenge  => $challenge,
        origin     => $app_id,
        cid_pubkey => 'unused');

    my $client_data = encode_json(\%client_data);

    my $sign_data = pack 'x a32 a32 a* a65',
        sha256($app_id),
        sha256($client_data),
        $handle,
        $keypair->public_key;

    my $signature = $self->key->sign_hash(sha256($sign_data));

    my $response = pack 'a a65 C/a* a* a*',
        chr(0x05), $keypair->public_key, $handle, $cert, $signature;

    return Authen::U2F::Tester::RegisterResponse->new(
        error_code  => OK,
        response    => $response,
        client_data => encode_base64url($client_data));
}


sub sign {
    my ($self, $app_id, $challenge, @handles) = @_;

    my $handle = first { $self->keystore->exists($_) } @handles;

    unless (defined $handle) {
        return Authen::U2F::Tester::Error->new(DEVICE_INELIGIBLE);
    }

    my %client_data = (
        typ        => 'navigator.id.getAssertion',
        challenge  => $challenge,
        origin     => $app_id,
        cid_pubkey => 'unused');

    my $client_data = encode_json(\%client_data);

    my $pkec = $self->keystore->get($handle);

    my $counter = ++$COUNTER;

    # generate the signature
    my $sign_data = pack 'a32 a N a32',
        sha256($app_id),            # 32 byte SHA256 application parameter
        chr(0x01),                  # 1 byte user presence
        $counter,                   # 4 byte counter
        sha256($client_data);       # 32 byte SHA256 of client data JSON

    my $signature = $pkec->sign_hash(sha256($sign_data));

    my $response = pack 'a N a*',
        chr(0x01),
        $counter,
        $signature;

    return Authen::U2F::Tester::SignResponse->new(
        error_code  => OK,
        response    => $response,
        key_handle  => $handle,
        client_data => encode_base64url($client_data));
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester - FIDO/U2F Authentication Test Client

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 my $tester = Authen::U2F::Tester->new(
     cert_file => $certfile,
     key_file  => $keyfile);

 #
 # Test a U2F registration
 #
 my $app_id = 'https://www.example.com';
 my $challenge = Authen::U2F->challenge;

 my $r = $tester->register($app_id, $challenge);

 unless ($r->is_success) {
     die $r->error_message;
 }

 print $res->client_data;
 print $res->registration_data;

 # the fields in $res can be used to verify the registration using
 # Authen::U2F
 my ($handle, $key) = Authen::U2F->registration_verify(
     challenge         => $challenge,
     app_id            => $app_id,
     origin            => $origin,
     registration_data => $res->registration_data,
     client_data       => $res->client_data);

 #
 # Test a U2F Signing request
 #
 $r = $tester->sign($app_id, $challenge, $handle);

 unless ($r->is_success) {
     die $r->error_message;
 }

 print $res->client_data;
 print $res->signature_data;

 # verify the signing request with Authen::U2F
 Authen::U2F->signature_verify(
     challenge      => $challenge,
     app_id         => $app_id,
     origin         => $app_id,
     key_handle     => $handle,
     key            => $key,
     signature_data => $r->signature_data,
     client_data    => $r->client_data);

=head1 DESCRIPTION

This module implements a FIDO/U2F tester that can be used for testing web
applications that support FIDO/U2F.  Think of this module as a "virtual" U2F
security key.

=head1 METHODS

=head2 new(%args)

Constructor.

The following arguments are required:

=over 4

=item *

key_file

The location of the private key file.

=item *

cert_file

The location of the C<X.509> certificate file.

=back

Alternatively, the key and certificate can be passed in directly as objects:

=over 4

=item *

key

An L<Crypt::PK::ECC> object.

=item *

certificate

An L<Crypt::OpenSSL::X509> object.

=back

In order to create and use the tester, you will need both an Elliptic Curve
key, and a SSL X.509 certificate.  The key can be generated using OpenSSL:

 % openssl ecparam -name secp256r1 -genkey -noout -out key.pem

Then this key can be used to generate a self signed X.509 certificate:

 % openssl req -key key.pem -x509 -days 3560 -sha256 \
     -subj '/C=US/ST=Texas/O=Untrusted U2F Org/CN=virtual-u2f' \
     -out cert.pem

Note that this key is also used to encrypt key handles that the tester
generates for registration requests.

=head2 key(): Crypt::PK::ECC

Get the key for this tester.

=head2 keystore(): Authen::U2F::Tester::Role::Keystore

This returns the key store instance that the tester uses.  The default key
store is a "wrapped" key store as described in the FIDO/U2F specs.  What this
means is it does not actually store anything, but instead encrypts the private
key using the tester's private key, and returns that as the key handle. This
key store will accept any encrypted private key as a valid key handle so long
as it can be decrypted by the tester's private key.  This is similar to how
many physical U2F devices work in the real world.  See
L<Authen::U2F::Tester::Keystore::Wrapped> for more information.

=head2 certificate(): Crypt::OpenSSL::X509

Get the SSL certificate that this tester uses.

=head2 register($app_id, $challenge, @keyhandles): Authen::U2F::Tester::RegisterResponse

Complete a registration request.

Returns a L<Authen::U2F::Tester::RegisterResponse> on success, or an
L<Authen::U2F::Error> object on failure.

Arguments are:

=over 4

=item *

app_id: string

The application id

=item *

challenge: string

The challenge parameter, in Base64 URL encoded format

=item *

keyhandles: list (optional)

List of already registered keyhandles for the current user, in Base64 URL format.

=back

Example:

 my $app_id = 'https://www.example.com';
 my $challenge = Authen::U2F->challenge;

 my $res = $tester->register($app_id, $challenge);

 unless ($res->is_success) {
     die $res->error_message;
 }

=head2 sign($app_id, $challenge, @keyhandles)

Complete a U2F signing request.  Returns a L<Authen::U2F::Tester::SignResponse>
object on success, L<Authen::U2F::Error> object otherwise.

Arguments are:

=over 4

=item *

app_id

The appId value

=item *

challenge

The challenge parameter, in Base64 URL encoded format

=item *

keyhandles

List of possible keyhandles, in Base64 URL encoded format

=back

Example:

 my $app_id = 'https://www.example.com';
 my $challenge = Authen::U2F->challenge;

 my $res = $tester->sign($app_id, $challenge, $keyhandle);

 unless ($res->is_success) {
     die $res->error_message;
 }

 # signature and client data, which should be sent to relaying party for
 # verification.
 print $res->signature_data;
 print $res->client_data;

=for Pod::Coverage OK DEVICE_INELIGIBLE

=head1 SOURCE

The development version is on github at L<http://https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://https://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-authen-u2f-tester/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
