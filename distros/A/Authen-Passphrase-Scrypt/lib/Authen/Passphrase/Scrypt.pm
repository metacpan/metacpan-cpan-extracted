package Authen::Passphrase::Scrypt;

use 5.014000;
use strict;
use warnings;
use Carp;

use parent qw/Exporter Authen::Passphrase Class::Accessor::Fast/;

our @EXPORT = qw/crypto_scrypt/;
our @EXPORT_OK = @EXPORT;
our $VERSION = '0.001';

use Data::Entropy::Algorithms qw/rand_bits/;
use Digest::SHA qw/sha256 hmac_sha256/;
use MIME::Base64;

require XSLoader;
XSLoader::load('Authen::Passphrase::Scrypt', $VERSION);

__PACKAGE__->mk_accessors(qw/data logN r p salt hmac passphrase/);

sub compute_hash {
	my ($self, $passphrase) = @_;
	crypto_scrypt ($passphrase, $self->salt, (1 << $self->logN), $self->r, $self->p, 64);
}

sub truncated_sha256 {
	my $sha = sha256 shift;
	substr $sha, 0, 16
}

sub truncate_hash {
	substr shift, 32
}

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);

	$self->logN(14) unless defined $self->logN;
	$self->r(16) unless defined $self->r;
	$self->p(1) unless defined $self->p;
	croak "passphrase not set" unless defined $self->passphrase;
	$self->salt(rand_bits 256) unless $self->salt;

	my $data = "scrypt\x00" . pack 'CNNa32',
	  $self->logN, $self->r, $self->p, $self->salt;
	$data .= truncated_sha256 $data;
	$self->data($data);
	$self->hmac(hmac_sha256 $self->data, truncate_hash $self->compute_hash($self->passphrase));
	$self
}

sub from_rfc2307 {
	my ($class, $rfc2307) = @_;
	croak "Invalid Scrypt RFC2307" unless $rfc2307 =~ m,^{SCRYPT}([A-Za-z0-9+/]{128})$,;
	my $data = decode_base64 $1;
	my ($scrypt, $logN, $r, $p, $salt, $cksum, $hmac) =
	  unpack 'Z7CNNa32a16a32', $data;
	croak 'Invalid Scrypt hash: should start with "scrypt"' unless $scrypt eq 'scrypt';
	croak 'Invalid Scrypt hash: bad checksum', unless $cksum eq truncated_sha256 (substr $data, 0, 48);
	$class->SUPER::new({data => (substr $data, 0, 64), logN => $logN, r => $r, p => $p, salt => $salt, hmac => $hmac});
}

sub match {
	my ($self, $passphrase) = @_;
	my $correct_hmac = hmac_sha256 $self->data, truncate_hash $self->compute_hash($passphrase);
	$self->hmac eq $correct_hmac
}

sub as_rfc2307 {
	my ($self) = @_;
	'{SCRYPT}' . encode_base64 ($self->data . $self->hmac, '')
}

sub from_crypt {
	croak __PACKAGE__ ." does not support crypt strings, use from_rfc2307 instead";
}

sub as_crypt {
	croak __PACKAGE__ ." does not support crypt strings, use as_rfc2307 instead";
}

1;
__END__

=encoding utf-8

=head1 NAME

Authen::Passphrase::Scrypt - passphrases using Tarsnap's scrypt algorithm

=head1 SYNOPSIS

  use Authen::Passphrase::Scrypt;

  # Hash a password
  my $sc = Authen::Passphrase::Scrypt->new({
      passphrase => 'correcthorsebatterystaple'
  });
  my $hash = $sc->as_rfc2307;
  say "The given password hashes to $hash";

  # Verify a password
  $sc = Authen::Passphrase::Scrypt->from_rfc2307($hash);
  say 'The password was "correcthorsebatterystaple"'
      if $sc->match('correcthorsebatterystaple');
  say 'The password was "xkcd"' if $sc->match('xkcd');

  # Advanced hashing
  my $sc = Authen::Passphrase::Scrypt->new({
      passphrase => 'xkcd',
      logN       => 14, # General work factor
      r          => 16, # Memory work factor
      p          => 1,  # CPU (parallellism) work factor
      salt       => 'SodiumChloride && sODIUMcHLORIDE', # Must be 32 bytes
  });
  say 'The given password now hashes to ', $sc->as_rfc2307;

=head1 DESCRIPTION

B<This is experimental code, DO NOT USE in security-critical software>.

Scrypt is a key derivation function that was originally developed for
use in the Tarsnap online backup system and is designed to be far more
secure against hardware brute-force attacks than alternative functions
such as PBKDF2 or bcrypt.

Authen::Passphrase::Scrypt is a module for hashing and verifying
passphrases using scrypt. It offers the same interface as
L<Authen::Passphrase>. It is not however possible to use this module
from within L<Authen::Passphrase>. The methods are:

=over

=item Authen::Passphrase::Scrypt->B<new>(I<\%args>)

Creates a new L<Authen::Passphrase::Scrypt> from a given passphrase
and parameters. Use this to hash a passphrase. The arguments are:

=over

=item B<passphrase>

The passphrase. Mandatory.

=item B<logN>

The general work factor (affects both CPU and memory cost). Defaults to 14

=item B<r>

The blocksize (affects memory cost). Defaults to 16.

=item B<p>

The parallelization factor (affects CPU cost). Defaults to 1.

=item B<salt>

A 32-byte string used as a salt. By default it is randomly generated
using L<Data::Entropy>.

=back

All of the parameters change the result of the hash. They are all
stored in the hash, so there is no need to store them separately (or
provide them to the hash verification methods).

It is normally sufficient to only use the B<logN> parameter to control
the speed of scrypt. B<r> and B<p> are intended to be used only for
fine-tuning: if scrypt uses too much memory but not enough CPU,
decrease logN and increase p; if scrypt uses too much CPU but not
enough memory, decrease logN and increase r.

=item $sc->B<as_rfc2307>

Returns the hash of the passphrase, in RFC2307 format. This is
"{SCRYPT}" followed by the base64-encoded 96-byte result described here: L<https://security.stackexchange.com/questions/88678/why-does-node-js-scrypt-function-use-hmac-this-way/91050>

=item Authen::Passphrase::Scrypt->B<from_rfc2307>(I<$rfc2307>)

Creates a new L<Authen::Passphrase::Scrypt> from a hash in RFC2307
format. Use this to verify if a passphrase matches a hash.

=item $sc->B<match>(I<$passphrase>)

Returns true if the given passphrase matches the hash, false
otherwise.

=item Authen::Passphrase::Scrypt->from_crypt
=item $sc->as_crypt

These functions both croak. They are provided for compatibility with
the Authen::Passphrase interface.

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<https://www.tarsnap.com/scrypt.html>,
L<https://www.npmjs.com/package/scrypt>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
