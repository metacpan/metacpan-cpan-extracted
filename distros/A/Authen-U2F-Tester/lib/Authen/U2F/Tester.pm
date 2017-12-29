#
# This file is part of Authen-U2F-Tester
#
# This software is copyright (c) 2017 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Authen::U2F::Tester;
$Authen::U2F::Tester::VERSION = '0.01';
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


has keypair => (
    is       => 'ro',
    isa      => 'Crypt::PK::ECC',
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
            $args{keypair} = Crypt::PK::ECC->new($keyfile);
        }

        if (my $certfile = delete $args{cert_file}) {
            $args{certificate} = Crypt::OpenSSL::X509->new_from_file($certfile);
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
        if ($self->is_known_handle($registered)) {
            return Authen::U2F::Tester::Error->new(DEVICE_INELIGIBLE);
        }
    }

    # generate a new keypair for this application
    my $keypair = Authen::U2F::Tester::Keypair->new;
    my $handle  = $self->keypair->encrypt($keypair->private_key, 'SHA256');
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

    my $signature = $self->keypair->sign_hash(sha256($sign_data));

    my $response = pack 'a a65 C/a* a* a*',
        chr(0x05), $keypair->public_key, $handle, $cert, $signature;

    return Authen::U2F::Tester::RegisterResponse->new(
        error_code  => OK,
        response    => $response,
        client_data => encode_base64url($client_data));
}


sub sign {
    my ($self, $app_id, $challenge, @handles) = @_;

    my $handle = first { $self->is_known_handle($_) } @handles;

    unless (defined $handle) {
        return Authen::U2F::Tester::Error->new(DEVICE_INELIGIBLE);
    }

    my %client_data = (
        typ        => 'navigator.id.getAssertion',
        challenge  => $challenge,
        origin     => $app_id,
        cid_pubkey => 'unused');

    my $client_data = encode_json(\%client_data);

    # the handle is a wrapped private key, which for this library simply means
    # is the private key, encrypted using our own secret key.  We know the
    # handle will decrypt because is_knonwn_handle() already checked that.
    my $private_key = $self->keypair->decrypt(decode_base64url($handle));
    my $pkec = Crypt::PK::ECC->new;
    $pkec->import_key_raw($private_key, 'nistp256');

    my $counter = ++$COUNTER;

    # generate the signature
    my $sign_data = pack 'a32 a N a32',
        sha256($app_id),            # 32 byte SHA256 application parameter
        chr(0x00),                  # 1 byte user presence
        $counter,                   # 4 byte counter
        sha256($client_data);       # 32 byte SHA256 of client data JSON

    my $signature = $pkec->sign_hash(sha256($sign_data));

    my $response = pack 'a N a*',
        chr(0x00),
        $counter,
        $signature;

    return Authen::U2F::Tester::SignResponse->new(
        error_code  => OK,
        response    => $response,
        key_handle  => $handle,
        client_data => encode_base64url($client_data));
}


sub is_known_handle {
    my ($self, $handle) = @_;

    $handle = decode_base64url($handle);

    if (eval { $self->keypair->decrypt($handle); 1 }) {
        return 1;
    }
    else {
        return 0;
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Authen::U2F::Tester - FIDO/U2F Authentication Test Client

=head1 VERSION

version 0.01

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

keypair

An L<Crypt::PK::ECC> object.

=item *

certificate

An L<Crypt::OpenSSL::X509> object.

=back

In order to create and use the tester, you will need both an Elliptic Curve
keypair, and a SSL X.509 certificate.  The key can be generated using OpenSSL:

 % openssl ecparam -name secp256r1 -genkey -noout -out key.pem

Then this key can be used to generate a self signed X.509 certificate:

 % openssl req -key key.pem -x509 -days 3560 -sh256 \
     -subj '/C=US/ST=Texas/O=Untrusted U2F Org/CN=virtual-u2f' \
     -out cert.pem

=head2 keypair(): Crypt::PK::ECC

Get the private keypair for this tester.

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

=head2 is_known_handle($handle): bool

Return true if the given C<$handle> was generated by this tester.  C<$handle>
is a string containing a potential keyhandle, in Base64 URL format.

=for Pod::Coverage OK DEVICE_INELIGIBLE

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/perl-authen-u2f-tester>
and may be cloned from L<git://github.com/mschout/perl-authen-u2f-tester.git>

=head1 BUGS

Please report any bugs or feature requests to bug-authen-u2f-tester@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Authen-U2F-Tester

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
