package Crypt::Sodium;

use 5.008000;
use strict;
use warnings;

our $VERSION;
BEGIN {
    $VERSION = '0.11';
    require XSLoader;
    XSLoader::load('Crypt::Sodium', $VERSION);
    
    my $rv = real_sodium_init();
    
    if ($rv < 0) {
        die "[fatal] error calling sodium_init() rv: $rv\n";
    }
}

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    real_crypto_stream_xor
    real_crypto_sign
    real_crypto_sign_open
    real_crypto_box
    real_crypto_hash
    real_crypto_box_open
    real_crypto_secretbox
    real_crypto_secretbox_open
    real_crypto_stream

    crypto_sign
    crypto_sign_open
    crypto_sign_detached
    crypto_sign_verify_detached
    crypto_box
    crypto_box_open
    crypto_secretbox
    crypto_secretbox_open
    crypto_hash
    crypto_generichash
    crypto_generichash_key
    crypto_generichash_init
    crypto_generichash_update
    crypto_generichash_final
    crypto_generichash_statebytes
    crypto_stream
    crypto_stream_xor
    crypto_box_keypair
    crypto_sign_keypair
    crypto_pwhash_scrypt_str
    crypto_pwhash_scrypt_str_verify
    crypto_box_nonce
    crypto_stream_key
    crypto_stream_nonce
    crypto_pwhash_salt
    crypto_pwhash_scrypt
    crypto_scalarmult_base
    crypto_scalarmult
    crypto_scalarmult_safe

    randombytes_buf
    randombytes_random
    randombytes_uniform
    box_keypair
    sign_keypair

    crypto_stream_NONCEBYTES
    crypto_stream_KEYBYTES
    crypto_box_NONCEBYTES
    crypto_box_PUBLICKEYBYTES
    crypto_box_SECRETKEYBYTES
    crypto_box_MACBYTES
    crypto_box_SEEDBYTES
    crypto_sign_PUBLICKEYBYTES
    crypto_sign_SECRETKEYBYTES
    crypto_sign_BYTES
    crypto_secretbox_MACBYTES
    crypto_secretbox_KEYBYTES
    crypto_secretbox_NONCEBYTES
    crypto_pwhash_SALTBYTES
    crypto_pwhash_OPSLIMIT
    crypto_pwhash_MEMLIMIT
    crypto_pwhash_STRBYTES
    crypto_generichash_KEYBYTES
    crypto_generichash_KEYBYTES_MIN
    crypto_generichash_KEYBYTES_MAX
    crypto_generichash_BYTES
    crypto_generichash_BYTES_MIN
    crypto_generichash_BYTES_MAX
    crypto_scalarmult_SCALARBYTES
    crypto_scalarmult_BYTES
);

use subs qw/
    crypto_stream_KEYBYTES
    crypto_stream_NONCEBYTES
    crypto_box_NONCEBYTES
    crypto_box_PUBLICKEYBYTES
    crypto_box_SECRETKEYBYTES
    crypto_box_MACBYTES
    crypto_box_SEEDBYTES
    crypto_secretbox_KEYBYTES
    crypto_secretbox_MACBYTES
    crypto_secretbox_NONCEBYTES
    crypto_sign_PUBLICKEYBYTES
    crypto_sign_SECRETKEYBYTES
    crypto_sign_BYTES
    crypto_pwhash_SALTBYTES
    crypto_pwhash_OPSLIMIT
    crypto_pwhash_MEMLIMIT
    crypto_pwhash_STRBYTES
    crypto_generichash_KEYBYTES
    crypto_generichash_KEYBYTES_MIN
    crypto_generichash_KEYBYTES_MAX
    crypto_generichash_BYTES
    crypto_generichash_BYTES_MIN
    crypto_generichash_BYTES_MAX
    crypto_scalarmult_SCALARBYTES
    crypto_scalarmult_BYTES
/;

use Crypt::Sodium::GenericHash::State;

sub crypto_box_nonce {
    return randombytes_buf(crypto_box_NONCEBYTES);
}

sub crypto_stream_key {
    return randombytes_buf(crypto_stream_KEYBYTES);
}

sub crypto_stream_nonce {
    return randombytes_buf(crypto_stream_NONCEBYTES);
}

sub crypto_scalarmult_base {
    my ($n) = @_;
    unless (length($n) == crypto_scalarmult_SCALARBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_scalarmult_SCALARBYTES . " bytes long\n";
    }
    
    return real_crypto_scalarmult_base($n);
}

sub crypto_scalarmult {
    my ($n, $p) = @_;

    unless (length($n) == crypto_scalarmult_SCALARBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_scalarmult_SCALARBYTES . " bytes long\n";
    }
    
    unless (length($p) == crypto_scalarmult_BYTES) {
        die "[fatal]: public key must be exactly " . crypto_scalarmult_BYTES . " bytes long\n";
    }
    
    return real_crypto_scalarmult($n, $p);
}

sub crypto_scalarmult_safe {
    my ($n, $p, $p2) = @_;
    
    return crypto_hash(crypto_scalarmult($n, $p) ^ $p2 ^ $p);
}

sub crypto_stream {
    my ($len, $n, $k) = @_;

    unless (length($n) == crypto_stream_NONCEBYTES) {
        die "[fatal]: nonce must be exactly " . crypto_stream_NONCEBYTES . " bytes long.\n";
    }

    unless (length($k) == crypto_stream_KEYBYTES) {
        die "[fatal]: key must be exactly " . crypto_stream_KEYBYTES . " bytes long.\n";
    }

    return real_crypto_stream($len, $n, $k);
}

sub crypto_stream_xor {
    my ($m, $n, $k) = @_;

    unless (length($n) == crypto_stream_NONCEBYTES) {
        die "[fatal]: nonce must be exactly " . crypto_stream_NONCEBYTES . " bytes long.\n";
    }

    unless (length($k) == crypto_stream_KEYBYTES) {
        die "[fatal]: key must be exactly " . crypto_stream_KEYBYTES . " bytes long.\n";
    }

    return real_crypto_stream_xor($m, length($m), $n, $k);
}

sub crypto_hash {
    my ($to_hash) = @_;
    return real_crypto_hash($to_hash, length($to_hash));
}

sub crypto_generichash {
    my ($to_hash, $outlen) = @_;

    unless (($outlen >= crypto_generichash_BYTES_MIN) &&
   	    ($outlen <= crypto_generichash_BYTES_MAX)) {
        die "[fatal]: key must be between " . crypto_generichash_BYTES_MIN . " and " . crypto_generichash_BYTES_MAX . " bytes long.\n";
    }

    no warnings 'uninitialized';

    return real_crypto_generichash($to_hash, length($to_hash), $outlen, undef, 0);
}

sub crypto_generichash_key {
    my ($to_hash, $outlen, $key) = @_;

    unless (($outlen >= crypto_generichash_BYTES_MIN) &&
   	    ($outlen <= crypto_generichash_BYTES_MAX)) {
        die "[fatal]: key must be between " . crypto_generichash_BYTES_MIN . " and " . crypto_generichash_BYTES_MAX . " bytes long.\n";
    }

    unless ((length($key) >= crypto_generichash_KEYBYTES_MIN) &&
   	    (length($key) <= crypto_generichash_KEYBYTES_MAX)) {
        die "[fatal]: key must be between " . crypto_generichash_KEYBYTES_MIN . " and " . crypto_generichash_KEYBYTES_MAX . " bytes long.\n";
    }

    return real_crypto_generichash($to_hash, length($to_hash), $outlen, $key, length($key));
}

sub crypto_generichash_init {
    my ($key, $hash_size) = @_;

    if ($key) {
        unless ((length($key) >= crypto_generichash_KEYBYTES_MIN) &&
            (length($key) <= crypto_generichash_KEYBYTES_MAX)) {
            die "[fatal]: key must be undef or between " . crypto_generichash_KEYBYTES_MIN . " and " . crypto_generichash_KEYBYTES_MAX . " bytes long.\n";
        }
    }

    $hash_size = 64 unless $hash_size;

    no warnings 'uninitialized';

    return Crypt::Sodium::GenericHash::State->new(
        state => real_crypto_generichash_init($key, length($key), $hash_size),
        outlen => $hash_size,
    );
}

sub crypto_generichash_update {
    my ($state, $to_append) = @_;
    real_crypto_generichash_update($state->{state}, $to_append, length($to_append));
}

sub crypto_generichash_final {
    my ($state) = @_;
    return real_crypto_generichash_final($state->{state}, $state->{outlen});
}

sub box_keypair {
    my $ar = crypto_box_keypair();
    return (@$ar);
}

sub sign_keypair {
    my $ar = crypto_sign_keypair();
    return (@$ar);
}

sub crypto_sign_open {
    my ($sm, $pk) = @_;

    unless (length($pk) == crypto_sign_PUBLICKEYBYTES) {
        die "[fatal]: public key must be exactly " . crypto_sign_PUBLICKEYBYTES . " bytes long.\n";
    }

    return real_crypto_sign_open($sm, length($sm), $pk);
}

sub crypto_sign {
    my ($m, $sk) = @_;

    unless (length($sk) == crypto_sign_SECRETKEYBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_sign_SECRETKEYBYTES . " bytes long.\n";
    }

    return real_crypto_sign($m, length($m), $sk);
}

sub crypto_sign_detached {
    my ($m, $sk) = @_;

    unless (length($sk) == crypto_sign_SECRETKEYBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_sign_SECRETKEYBYTES . " bytes long.\n";
    }

    return real_crypto_sign_detached($m, length($m), $sk);
}

sub crypto_sign_verify_detached {
    my ($sig, $m, $pk) = @_;

    unless (length($pk) == crypto_sign_PUBLICKEYBYTES) {
        die "[fatal]: public key must be exactly " . crypto_sign_PUBLICKEYBYTES . " bytes long.\n";
    }

    return real_crypto_sign_verify_detached($sig, $m, length($m), $pk);
}

sub crypto_box_open {
    my ($c, $n, $pk, $sk) = @_;

    unless (length($pk) == crypto_box_PUBLICKEYBYTES) {
        die "[fatal]: public key must be exactly " . crypto_box_PUBLICKEYBYTES . " bytes long.\n";
    }

    unless (length($sk) == crypto_box_SECRETKEYBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_box_SECRETKEYBYTES . " bytes long.\n";
    }

    return real_crypto_box_open($c, length($c), $n, $pk, $sk);
}

sub crypto_box {
    my ($m, $n, $pk, $sk) = @_;

    unless (length($pk) == crypto_box_PUBLICKEYBYTES) {
        die "[fatal]: public key must be exactly " . crypto_box_PUBLICKEYBYTES . " bytes long.\n";
    }

    unless (length($sk) == crypto_box_SECRETKEYBYTES) {
        die "[fatal]: secret key must be exactly " . crypto_box_SECRETKEYBYTES . " bytes long.\n";
    }

    return real_crypto_box($m, length($m), $n, $pk, $sk);
}

sub crypto_secretbox_open {
    my ($c, $n, $sk) = @_;

    unless (length($n) == crypto_secretbox_NONCEBYTES) {
        die "[fatal]: secretbox nonce must be exactly " . crypto_secretbox_NONCEBYTES . " bytes long.\n";
    }

    unless (length($sk) == crypto_secretbox_KEYBYTES) {
        die "[fatal]: secretbox key must be exactly " . crypto_secretbox_KEYBYTES . " bytes long.\n";
    }

    return real_crypto_secretbox_open($c, length($c), $n, $sk);
}

sub crypto_secretbox {
    my ($m, $n, $sk) = @_;

    unless (length($n) == crypto_secretbox_NONCEBYTES) {
        die "[fatal]: secretbox nonce must be exactly " . crypto_secretbox_NONCEBYTES . " bytes long.\n";
    }

    unless (length($sk) == crypto_secretbox_KEYBYTES) {
        die "[fatal]: secretbox key must be exactly " . crypto_secretbox_KEYBYTES . " bytes long.\n";
    }

    return real_crypto_secretbox($m, length($m), $n, $sk);
}

sub crypto_pwhash_salt {
  return randombytes_buf(crypto_pwhash_SALTBYTES);
}

sub crypto_pwhash_scrypt {
    my ($pass, $salt, $klen, $ops, $mem) = @_;

    if (length($pass) < 1) {
        die "[fatal]: supplying a zero length passphrase doesn't make any sense.\n";
    }

    if (length($salt) != crypto_pwhash_SALTBYTES) {
        die "[fatal]: salt must be exactly " . crypto_pwhash_SALTBYTES . " bytes long.\n";
    }

    $klen = crypto_box_SEEDBYTES unless $klen;
    $ops = crypto_pwhash_OPSLIMIT unless $ops;
    $mem = crypto_pwhash_MEMLIMIT unless $mem;

    return real_crypto_pwhash_scrypt($klen, $pass, $salt, $ops, $mem);
}

sub crypto_pwhash_scrypt_str {
    my ($pass, $salt, $ops, $mem) = @_;

    if (length($pass) < 1) {
        die "[fatal]: supplying a zero length passphrase doesn't make any sense.\n";
    }

    if (length($salt) != crypto_pwhash_SALTBYTES) {
        die "[fatal]: salt must be exactly " . crypto_pwhash_SALTBYTES . " bytes long.\n";
    }

    $ops = crypto_pwhash_OPSLIMIT unless $ops;
    $mem = crypto_pwhash_MEMLIMIT unless $mem;

    return real_crypto_pwhash_scrypt_str($pass, $salt, $ops, $mem);
}

sub crypto_pwhash_scrypt_str_verify {
    my ($hashed_pass, $pass) = @_;

    return real_crypto_pwhash_scrypt_str_verify($hashed_pass, $pass);
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Crypt::Sodium - Perl bindings for libsodium (NaCL) https://github.com/jedisct1/libsodium

=head1 SYNOPSIS

  use Crypt::Sodium;

  my $k = crypto_stream_key();
  my $n = crypto_stream_nonce();

  my $ciphertext = crypto_stream_xor("Hello World!", $n, $k);
  my $cleartext = crypto_stream_xor($ciphertext, $n, $k);

=head1 DESCRIPTION

  Simple wrapper around NaCL functions as provided by libsodium.  crypto_box, crypto_stream, crypto_hash,
  and crypto_sign are all present and accounted for.  None of the specific implementations are exposed, 
  only the default implementations are.

=head1 EXPORTED FUNCTIONS

=over

=item box_keypair()

   Usage: my ($public_key, $secret_key) = box_keypair();

=item sign_keypair()
   
   Usage: my ($public_key, $secret_key) = sign_keypair();

=item crypto_sign($message, $secret_key)
   
   Usage: my $signed_message = crypto_sign($m, $sk);

=item crypto_sign_open($signed_message, $public_key)
   
   Usage: my $message = crypto_sign_open($sm, $pk);

=item crypto_box($message, $nonce, $public_key, $secret_key)
   
   Usage: my $ciphertext = crypto_box($m, $n, $pk, $sk);
   
   Note:  $nonce must be at least crypto_box_NONCEBYTES long.

=item crypto_box_open($ciphertext, $nonce, $public_key, $secret_key)
   
   Usage: my $cleartext = crypto_box_open($c, $n, $pk, $sk);

=item crypto_secretbox($message, $nonce, $key);
   
   Usage: my $ciphertext = crypto_secretbox($m, $n, $k);
   
   Note:  $nonce must be at least crypto_box_NONCEBYTES long,
          $key must be at least crypto_box_SECRETKEYBYTES long.

=item crypto_secretbox_open($ciphertext, $nonce, $key);
   
   Usage: my $message = crypto_secretbox($c, $n, $k);

=item crypto_hash($to_hash)
   
   Usage: my $hash = crypto_hash($to_hash);

=item crypto_stream($length, $nonce, $key)
   
   Usage: my $stream = crypto_stream($length, $nonce, $key);
   
   Note:  $nonce must be at least crypto_stream_NONCEBYTES long, 
          $key must be at least crypto_stream_KEYBYTES long.

=item crypto_stream_xor($message, $nonce, $key)
   
   Usage: my $ciphertext = crypto_stream_xor($message, $nonce, $key);
          my $cleartext = crypto_stream_xor($ciphertext, $nonce, $key);
          
   Note:  $nonce must be at least crypto_stream_NONCEBYTES long, 
          $key must be at least crypto_stream_KEYBYTES long.

=item randombytes_buf($length)
   
   Usage: my $bytes = randombytes(24);

=item crypto_box_nonce()
   
   Usage: my $nonce = crypto_box_nonce();

=item crypto_stream_nonce()
   
   Usage: my $nonce = crypto_stream_nonce();

=item crypto_stream_key()

   Usage: my $key = crypto_stream_key();

=item crypto_pwhash_salt()
   
   Usage: my $salt = crypto_pwhash_salt();

=item crypto_pwhash_scrypt($password, $salt, $keylen, $opslimit, $memlimit)
   
   Usage: my $derivedkey = crypto_pwhash_scrypt($password, $salt, $keylen, $opslimit, $memlimit);
   
   Note:  $salt must be crypto_pwhash_SALTBYTES long, use crypto_pwhash_salt() to generate
          $keylen maybe omitted, the default is crypto_box_SEEDBYTES
          $opslimit maybe omitted, the default is crypto_pwhash_OPSLIMIT
          $memlimit maybe omitted, the default is crypto_pwhash_MEMLIMIT
          See L<http://doc.libsodium.org/password_hashing/README.html> for details>.

=item crypto_pwhash_scrypt_str($password, $salt, $opslimit, $memlimit)
   
   Usage: my $hash_string = crypto_pwhash_scrypt_str($password, $salt);
   
   Note:  like the crypto_pwhash_scrypt function, this function can also take an opslimit and memlimit
          value.  The default opslimit is exported into your namespace as crypto_pwhash_OPSLIMIT and the
          default memlimit is exported as crypto_pwhash_MEMLIMIT, if you have a really important password
          to hash and don't mind using 1GB of ram and 10s+ of CPU time on an i7-class CPU, you can use 
          crypto_pwhash_OPSLIMIT_SENSITIVE and crypto_pwhash_MEMLIMIT_SENSITIVE instead.

=item crypto_scalarmult_base()
   
   Usage: my $pk = crypto_scalarmult_base($sk);

=item crypto_scalarmult()
   
   Usage: my $shared_secret = crypto_scalarmult($alice_secret, $bob_public);
   
=item crypto_scalarmult_safe()

   Usage: my $shared_secret = crypto_scalarmult_safe($alice_secret, $bob_public, $alice_public);
   
   Note:  The shared secret generated is a hash of the output of crypto_scalarmult xor'd with the two public 
          keys as outlined here L<https://download.libsodium.org/doc/advanced/scalar_multiplication.html>.

=back

=head1 EXPORTED CONSTANTS

 crypto_stream_KEYBYTES
 crypto_stream_NONCEBYTES
 crypto_box_NONCEBYTES
 crypto_box_PUBLICKEYBYTES
 crypto_box_SECRETKEYBYTES
 crypto_box_MACBYTES
 crypto_box_SEEDBYTES
 crypto_secretbox_MACBYTES
 crypto_secretbox_KEYBYTES
 crypto_secretbox_NONCEBYTES
 crypto_sign_PUBLICKEYBYTES
 crypto_sign_SECRETKEYBYTES
 crypto_pwhash_SALTBYTES
 crypto_pwhash_OPSLIMIT
 crypto_pwhash_MEMLIMIT
 crypto_pwhash_STRBYTES

=head1 SEE ALSO

 https://github.com/jedisct1/libsodium
 http://nacl.cr.yp.to/

=head1 DEPENDENCIES

 libsodium 1.0.0 or higher

=head1 AUTHOR

Michael Gregorowicz, E<lt>mike@mg2.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Michael Gregorowicz

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.18 or, at your option, any later version of Perl 5 you may have available.

=cut
