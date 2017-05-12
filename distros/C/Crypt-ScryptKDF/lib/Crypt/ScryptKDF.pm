package Crypt::ScryptKDF;

use strict;
use warnings ;

our $VERSION = '0.010';

use MIME::Base64 qw(decode_base64 encode_base64);
use Exporter 'import';
our %EXPORT_TAGS = ( all => [qw(scrypt_raw scrypt_hex scrypt_b64 scrypt_hash scrypt_hash_verify random_bytes)] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

require XSLoader;
XSLoader::load('Crypt::ScryptKDF', $VERSION);

sub random_bytes {
  my $length = shift || 32;
  my $rv;

  if (eval {require Crypt::PRNG}) {
    $rv = Crypt::PRNG::random_bytes($length);
  }
  elsif (eval {require Crypt::OpenSSL::Random}) {
    if (Crypt::OpenSSL::Random::random_status()) {
      $rv = Crypt::OpenSSL::Random::random_bytes($length);
    }
  }
  elsif (eval {require Net::SSLeay}) {
    if (Net::SSLeay::RAND_status() == 1) {
      if (Net::SSLeay::RAND_bytes($rv, $length) != 1) {
        $rv = undef;
      }
    }
  }
  elsif (eval {require Crypt::Random}) {
    $rv = Crypt::Random::makerandom_octet(Length=>$length);
  }
  elsif (eval {require Bytes::Random::Secure}) {
    $rv = Bytes::Random::Secure::random_bytes(32);
  }

  if (!defined $rv)  {
    warn "WARNING: Generating random bytes via insecure rand()\n";
    $rv = pack('C*', map(int(rand(256)), 1..$length));
  }

  return $rv
}

sub scrypt_raw {
  warn "scrypt_raw: 2 or 6 parameters required\n" and return undef unless @_ == 2 || @_ == 6;
  my $key = _scrypt_extra(@_);
  return $key;
}

sub scrypt_b64 {
  warn "scrypt_b64: 2 or 6 parameters required\n" and return undef unless @_ == 2 || @_ == 6;
  my $key = _scrypt_extra(@_);
  return undef unless defined $key;
  return encode_base64($key, '');
}

sub scrypt_hex {
  warn "scrypt_hex: 2 or 6 parameters required\n" and return undef unless @_ == 2 || @_ == 6;
  my $key = _scrypt_extra(@_);
  return undef unless defined $key;
  return unpack("H*", $key);
}

sub scrypt_hash {
  my ($key, $salt, $N, $r, $p) = _scrypt_extra(@_);
  return undef unless defined $key && defined $salt && defined $N && defined $r && defined $p;
  return "SCRYPT:$N:$r:$p:" . MIME::Base64::encode($salt, "") . ":" . MIME::Base64::encode($key, "");
}

sub scrypt_hash_verify {
  my ($passwd, $string) = @_;
  return 0 unless $string;
  return 0 unless defined $passwd;
  my ($alg, $N, $r, $p, $salt, $hash) = ($string =~ /^(SCRYPT):(\d+):(\d+):(\d+):([^\:]+):([^\:]+)$/);
  return 0 unless defined $salt && defined $hash;
  $salt = MIME::Base64::decode($salt);
  $hash = MIME::Base64::decode($hash);
  return 0 unless defined $salt && defined $hash;
  return 0 unless length($hash) > 0;
  return 0 unless $N > 0 && $r >= 0 && $p >= 0;
  #XXX-TODO utf8::encode($passwd) if utf8::is_utf8($passwd);
  my $key = _scrypt($passwd, $salt, $N, $r, $p, length($hash));
  return 0 unless defined $key;
  return 0 unless _slow_eq($key, $hash);
  return 1;
}

sub _get_scrypt_defaults {
  # (N=2^14, r=8, p=1, len=32)
  return (16384, 8, 1, 32);
}

sub _scrypt_extra {
  my $salt;
  my @args;
  if (@_ == 1) {        # ... ($passwd)
    ($salt, @args) = (random_bytes(32), _get_scrypt_defaults);
  }
  elsif (@_ == 2) {     # ... ($passwd, $salt)
    ($salt, @args) = ($_[1], _get_scrypt_defaults);
  }
  elsif (@_ == 5) {     # ... ($passwd, $N, $r, $p, $dklen)
    ($salt, @args) = (random_bytes(32), $_[1], $_[2], $_[3], $_[4]);
  }
  elsif (@_ == 6) {     # ... ($passwd, $salt, $N, $r, $p, $dklen)
    (undef, $salt, @args) = @_;
  }
  else {
    warn "ERROR: scrypt() invalid number of arguments\n";
    return;
  }
  #check @args
  my $N = $args[0];
  if ( ($N <= 0) || (($N&($N-1)) != 0) ) { warn "ERROR: invalid 'N'\n"; return }
  if ($args[1] < 1)  { warn "ERROR: invalid 'r'\n"; return }
  if ($args[2] < 1)  { warn "ERROR: invalid 'p'\n"; return }
  if ($args[3] < 1)  { warn "ERROR: invalid 'len'\n"; return }
  #XXX-TODO utf8::encode($_[0]) if utf8::is_utf8($_[0]);
  $salt = random_bytes($$salt) if ref $salt eq 'SCALAR' && $$salt =~ /^\d+$/;
  my $key = _scrypt($_[0], $salt, @args);
  return wantarray ? ($key, $salt, $args[0], $args[1], $args[2]) : $key;
}

sub _slow_eq {
  my ($a, $b) = @_;
  return unless defined $a && defined $b;
  my $diff = length $a ^ length $b;
  for(my $i = 0; $i < length $a && $i < length $b; $i++) {
    $diff |= ord(substr $a, $i) ^ ord(substr $b, $i);
  }
  return $diff == 0;
}

1;

__END__

=head1 NAME

Crypt::ScryptKDF - Scrypt password based key derivation function

=head1 SYNOPSIS

Creating / verifying scrypt-based password hash:

 use Crypt::ScryptKDF qw(scrypt_hash scrypt_hash_verify);

 my $hash1 = scrypt_hash("secret password");
 # .. later
 die "Invalid password" unless scrypt_hash_verify("secret password", $hash1);

 #or by specifying Scrypt parameters
 my $hash2 = scrypt_hash("secret password", \32, 16384, 8, 1, 32);
 # .. later
 die "Invalid password" unless scrypt_hash_verify("secret password", $hash2);

Creating raw scrypt-based derived key:

 use Crypt::ScryptKDF qw(scrypt_raw scrypt_hex scrypt_b64);

 my $binary_buffer = scrypt_raw($password, $salt, $N, $r, $p, $len);
 my $hexadecimal_string = scrypt_hex($password, $salt, $N, $r, $p, $len);
 my $base64_string = scrypt_b64($password, $salt, $N, $r, $p, $len);

=head1 DESCRIPTION

Scrypt is a password-based key derivation function (like for example PBKDF2). Scrypt was designed to be "memory-hard"
algorithm in order to make it expensive to perform large scale custom hardware attacks.

It can be used for:

=over

=item * deriving cryptographic keys from low-entropy password (like PBKDF2)

=item * creating (+validating) password hashes (like PBKDF2 or Bcrypt)

=back

More details about Scrypt: L<http://www.tarsnap.com/scrypt/scrypt.pdf> and L<https://tools.ietf.org/html/draft-josefsson-scrypt-kdf>

B<IMPORTANT:> This module needs a cryptographically strong random
number generator. It tries to use one of the following:

=over

=item * L<Crypt::PRNG> - random_bytes()

=item * L<Crypt::OpenSSL::Random> - random_bytes()

=item * L<Net::SSLeay> - RAND_bytes()

=item * L<Crypt::Random> - makerandom_octet()

=item * L<Bytes::Random::Secure> - random_bytes()

=item * As an B<unsecure> fallback it uses built-in rand()

=back

=head1 FUNCTIONS

=over

=item * scrypt_raw

Derive a key from given C<password> and C<salt> (+ optional params).

 my $derived_key_raw_bytes = scrypt_raw($password, $salt, $N, $r, $p, $len);
 #or
 my $derived_key_raw_bytes = scrypt_raw($password, $salt);

 #  $password - low-entropy secret (bytes)
 #  $salt - raw octects (bytes) with a salt
 #  $N - CPU/memory cost (has to be power of 2 and >1) DEFAULT: 2^14 = 16384
 #  $r - block size parameter                          DEFAULT: 8
 #  $p - parallelization parameter                     DEFAULT: 1
 #  $len - length of derived key (in bytes)            DEFAULT: 32
 #returns:
 #  $derived_key .. raw bytes of length $len

=item * scrypt_hex

Similar to scrypt_raw only the return value is encoded as hexadecimal value.

 my $derived_key_hex_string = scrypt_hex($password, $salt, $N, $r, $p, $len);
 #or
 my $derived_key_hex_string = scrypt_hex($password, $salt);

=item * scrypt_b64

Similar to scrypt_raw only the return value is BASE64 encoded.

 my $derived_key_base64_string = scrypt_b64($password, $salt, $N, $r, $p, $len);
 #or
 my $derived_key_base64_string = scrypt_b64($password, $salt);

=item * scrypt_hash

Create a password hash for given C<password>.

 my $hash = scrypt_hash($password, $salt, $N, $r, $p, $len);

 #  params same as by scrypt_raw, the $salt can also be a scalar ref with salt
 #  length e.g. $salt=\24 means that salt will be 24 randomly generated bytes
 #returns:
 #  string with password hash (suitable for storing in DB) e.g.
 #  'SCRYPT:16384:8:1:BK8jkrqgm3BEtMh/g+WGL+k8ZeoAo=:YsEnQWld4UK8EqRZ9JuGbQnnlkXaM='

Some of the parameters are optional:

 # 1 arg variant
 my $hash = scrypt_hash($password); # generate random salt (32 bytes)

 # 2 args variant
 my $hash = scrypt_hash($password, $salt); # use given $salt
 my $hash = scrypt_hash($password, \20);   # generate random salt (20 bytes)

 # 5 args variant
 my $hash = scrypt_hash($password, $N, $r, $p, $len); # random salt (32 bytes)

=item * scrypt_hash_verify

Verify a password hash created with C<scrypt_hash()>

 my $is_valid = scrypt_hash_verify($password, $hash);
 #  $password - password to be verified
 #  $hash - hash previously created via scrypt_hash
 #returns:
 #  1 (ok) or 0 (fail)

=item * random_bytes

Generate random bytes of given length.

 my $salt = random_bytes($len);
 #  $len - number of random bytes
 #returns:
 #  $len random octets

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (c) 2013-2015 DCIT, a.s. L<http://www.dcit.cz> / Karel Miko
