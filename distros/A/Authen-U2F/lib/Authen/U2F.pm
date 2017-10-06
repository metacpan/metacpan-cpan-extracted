package Authen::U2F;
$Authen::U2F::VERSION = '0.003';
# ABSTRACT: FIDO U2F library

use warnings;
use strict;

use namespace::autoclean;

use Types::Standard -types, qw(slurpy);
use Type::Params qw(compile);
use Try::Tiny;
use Carp qw(croak);

use Math::Random::Secure qw(irand);
use MIME::Base64 3.11 qw(encode_base64url decode_base64url);
use Crypt::OpenSSL::X509 1.806;
use CryptX 0.034;
use Crypt::PK::ECC;
use Digest::SHA qw(sha256);
use JSON qw(decode_json);

use parent 'Exporter::Tiny';
our @EXPORT_OK = qw(u2f_challenge u2f_registration_verify u2f_signature_verify);

sub u2f_challenge           { __PACKAGE__->challenge(@_) }
sub u2f_registration_verify { __PACKAGE__->registration_verify(@_) }
sub u2f_signature_verify    { __PACKAGE__->signature_verify(@_) }

# Param checks
my $challenge_check;
my $registration_check;
my $signature_check;

sub challenge {
  $challenge_check ||= compile(
    ClassName,
  );
  my ($class) = $challenge_check->(@_);

  my $raw = pack "L*", map { irand } 1..8;
  my $challenge = encode_base64url($raw);
  return $challenge;
}

sub registration_verify {
  $registration_check ||= compile(
    ClassName,
    slurpy Dict[
      challenge         => Str,
      app_id            => Str,
      origin            => Str,
      registration_data => Str,
      client_data       => Str,
    ],
  );
  my ($class, $args) = $registration_check->(@_);

  my $client_data = decode_base64url($args->{client_data});
  croak "couldn't decode client data; not valid Base64-URL?"
    unless $client_data;

  {
    my $data = decode_json($client_data);
    croak "invalid client data (challenge doesn't match)"
      unless $data->{challenge} eq $args->{challenge};
    croak "invalid client data (origin doesn't match)"
      unless $data->{origin} eq $args->{origin};
  }

  my $reg_data = decode_base64url($args->{registration_data});
  croak "couldn't decode registration data; not valid Base64-URL?"
    unless $reg_data;

  # $reg_data is packed like so:
  #
  # 1-byte  reserved (0x05)
  # 65-byte public key
  # 1-byte  key handle length
  #         key handle
  #         attestation cert
  #           2-byte DER type
  #           2-byte DER length
  #           DER payload
  #         signature

  my ($reserved, $key, $handle, $certtype, $certlen, $certsig) = unpack 'a a65 C/a n n a*', $reg_data;

  croak "invalid registration data (reserved byte != 0x05)"
    unless $reserved eq chr(0x05);

  croak "invalid registration data (key length != 65)"
    unless length($key) == 65;

  # extract the cert payload from the trailing data and repack
  my $certraw = substr $certsig, 0, $certlen;
  croak "invalid registration data (incorrect cert length)"
    unless length($certraw) == $certlen;
  my $cert = pack "n n a*", $certtype, $certlen, $certraw;

  # signature at end of the trailing data
  my $sig  = substr $certsig, $certlen;

  my $x509 = try {
    Crypt::OpenSSL::X509->new_from_string($cert, Crypt::OpenSSL::X509::FORMAT_ASN1);
  }
  catch {
    croak "invalid registration data (certificate parse failure: $_)";
  };

  my $pkec = try {
    Crypt::PK::ECC->new(\$x509->pubkey);
  }
  catch {
    croak "invalid registration data (certificate public key parse failure: $_)";
  };

  # signature data. sha256 of:
  #
  # 1-byte  reserved (0x00)
  # 32-byte sha256(app ID)                      (application parameter)
  # 32-byte sha256(client data (JSON-encoded))  (challenge parameter)
  #         key handle
  # 65-byte key

  my $app_id_sha = sha256($args->{app_id});
  my $challenge_sha = sha256($client_data);

  my $sigdata = pack "x a32 a32 a* a65", $app_id_sha, $challenge_sha, $handle, $key;
  my $sigdata_sha = sha256($sigdata);

  $pkec->verify_hash($sig, $sigdata_sha)
    or croak "invalid registration data (signature verification failed)";

  my $enc_key = encode_base64url($key);
  my $enc_handle = encode_base64url($handle);

  return ($enc_handle, $enc_key);
}

sub signature_verify {
  $signature_check ||= compile(
    ClassName,
    slurpy Dict[
      challenge      => Str,
      app_id         => Str,
      origin         => Str,
      key_handle     => Str,
      key            => Str,
      signature_data => Str,
      client_data    => Str,
    ],
  );
  my ($class, $args) = $signature_check->(@_);

  my $key = decode_base64url($args->{key});
  croak "couldn't decode key; not valid Base64-URL?"
    unless $key;

  my $pkec = Crypt::PK::ECC->new;
  try {
    $pkec->import_key_raw($key, "nistp256");
  }
  catch {
    croak "invalid key argument (parse failure: $_)";
  };

  my $client_data = decode_base64url($args->{client_data});
  croak "couldn't decode client data; not valid Base64-URL?"
    unless $client_data;

  {
    my $data = decode_json($client_data);
    croak "invalid client data (challenge doesn't match)"
      unless $data->{challenge} eq $args->{challenge};
    croak "invalid client data (origin doesn't match)"
      unless $data->{origin} eq $args->{origin};
  }

  my $sign_data = decode_base64url($args->{signature_data});
  croak "couldn't decode signature data; not valid Base64-URL?"
    unless $sign_data;

  # $sig_data is packed like so
  #
  # 1-byte  user presence
  # 4-byte  counter (big-endian)
  #         signature

  my ($presence, $counter, $sig) = unpack 'a N a*', $sign_data;

  # XXX presence check

  # XXX counter check

  # signature data. sha256 of:
  #
  # 32-byte sha256(app ID)                      (application parameter)
  # 1-byte  user presence
  # 4-byte  counter (big endian)
  # 32-byte sha256(client data (JSON-encoded))  (challenge parameter)

  my $app_id_sha = sha256($args->{app_id});
  my $challenge_sha = sha256($client_data);

  my $sigdata = pack "a32 a N a32", $app_id_sha, $presence, $counter, $challenge_sha;
  my $sigdata_sha = sha256($sigdata);

  $pkec->verify_hash($sig, $sigdata_sha)
    or croak "invalid signature data (signature verification failed)";

  return;
}

1;
__END__

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Authen-U2F.png)](http://travis-ci.org/robn/Authen-U2F)

=head1 NAME

Authen-U2F - FIDO U2F library

=head1 SYNOPSIS

    use Authen::U2F qw(
      u2f_challenge
      u2f_registration_verify
      u2f_signature_verify);

    # Create a challenge to send to the U2F host
    my $challenge = u2f_challenge;

    # Process a registration response from the U2F host
    my ($key_handle, $key) = u2f_registration_verify(
      challenge         => $challenge,
      app_id            => $app_id,
      origin            => $origin,
      registration_data => $registration_data,
      client_data       => $client_data,
    );

    # Process a signing (authentication) response from the U2F host
    u2f_signature_verify(
      challenge      => $challenge,
      app_id         => $app_id,
      origin         => $origin,
      key_handle     => $key_handle,
      key            => $key,
      signature_data => $signature_data,
      client_data    => $client_data,
    );

    # Or, if you don't like to clutter up your namespace
    my $challenge = Authen::U2F->challenge;
    my ($key_handle, $key) = Authen::U2F->registration_verify(...);
    Authen::U2F->signature_verify(...);

=head1 DESCRIPTION

This module provides the tools you need to add support for U2F in your
application.

It's expected that you know the basics of U2F. More information about this can
be found at L<Yubico|https://www.yubico.com/about/background/fido/> and
L<FIDO|https://fidoalliance.org/specifications/overview/>.

This module does not handle the wire encoding of U2F challenges and response,
as these are different depending on the U2F host you're using and the style of
your application. In the C<examples> dir there are scripts that implement the
1.0 wire format, used by L<Yubico's libu2f-host|https://developers.yubico.com/libu2f-host/>,
and a Plack application that works with
L<Google's JavaScript module|https://github.com/google/u2f-ref-code/blob/master/u2f-gae-demo/war/js/u2f-api.js>.

Sadly, the documentation around U2F is rather more confusing than it should be,
and this short description is probably not making things better. Please improve
this or write something about U2F so we can improve application security
everywhere.

=head1 FUNCTIONS

There are three functions: One for generating challenges for the host to sign,
and one for processing the responses from the two types of signing requests U2F
supports.

There's straight function interface and a class method interface. Both do
exactly the same thing; which you use depends onhow much verbosity you like vs
how much namespace clutter you like. Only the functional interface is mentioned
in this section; see the L<SYNOPSIS> for the details.

=head2 u2f_challenge

    my $challenge = u2f_challenge;

Creates a challenge. A challenge is 256 cryptographically-secure random bits.

=head2 u2f_registration_verify

Verify a registration response from the host against the challenge. If the
verification is successful, returns the key handle and public key of the device
that signed the challenge. If it fails, this function croaks with an error.

Takes the following options, all required:

=over 4

=item challenge

The challenge originally given to the host.

=item app_id

The application ID.

=item origin

The browser location origin. This is typically the same as the application ID.

=item registration_data

The registration data blob from the host.

=item client_data

The client data blob from the host.

=back

=head2 u2f_signature_verify

Verify a signature (authentication) response from the host against the
challenge. If the verification is successful, the user has presented a valid
device and is now authenticated. If the verification fails, this function
croaks with an error.

Takes the following options, all required.

=over 4

=item challenge

The challenge originally given to the host.

=item app_id

The application ID.

=item origin

The browser location origin. This is typically the same as the application ID.

=item key_handle

The handle of the key that was used to sign the challenge.

=item key

The stored public key associated with the handle.

=item signature_data

The signature data blob from the host.

=item client_data

The client data blob from the host.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Authen-U2F/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Authen-U2F>

  git clone https://github.com/robn/Authen-U2F.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
