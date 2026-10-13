package Crypt::Age::Simple::Common;
use v5.24;
use warnings;
use experimental qw< signatures >;
use English;
{ our $VERSION = '0.001' }

use Crypt::Age::Primitives;
use Crypt::Age::Stanza;
use Crypt::KeyDerivation qw< scrypt_pbkdf >;

use constant {
   CHUNK_SIZE => 64 * 1024,
   NONCE_SIZE => 16,
   SCRYPT_SALT_PREFIX => 'age-encryption.org/v1/scrypt',
   TAG_SIZE   => 16,
   VERSION_LINE => 'age-encryption.org/v1',
};

use Exporter qw< import >;
our %EXPORT_TAGS = (
   constants => [qw<
      CHUNK_SIZE
      NONCE_SIZE
      SCRYPT_SALT_PREFIX
      TAG_SIZE
      VERSION_LINE
   >],
   misc => [qw<
      age_base64_multiline
      age_primitives_make_nonce 
      buffer
   >],
   scrypt => [qw<
      age_scrypt_decrypter
      age_scrypt_encrypter
      age_scrypt_unwrap_file_key
      age_scrypt_wrap_key
   >],
   x25519 => [qw<
      age_x25519_decrypter
      age_x25519_encrypter
   >],
);

our @EXPORT_OK = (
   qw<
   >,
   ( map { $_->@* } values(%EXPORT_TAGS) ),
);

$EXPORT_TAGS{all} = [ @EXPORT_OK ];

sub age_base64_multiline ($data) {
   my $data64 = Crypt::Age::Stanza::encode_base64_no_padding($data);
   my @lines;
   push @lines, substr($data64, 0, 64, '') while length($data64) > 64;
   return join("\x{0a}", @lines, $data64);
}

# copied from Crypt::Age::Primitives 0.002 because it's a private method
# there...
sub age_primitives_make_nonce ($counter, $is_final) {
    # 11 bytes counter (big-endian) + 1 byte final flag
    my $nonce = pack('x3 N N', ($counter >> 32) & 0xFFFFFFFF, $counter & 0xFFFFFFFF);
    # Actually, the nonce is: 11-byte big-endian counter || 1-byte last-block flag
    # Let's be more precise:
    $nonce = "\x00" x 3;  # First 3 bytes zero
    $nonce .= pack('N', ($counter >> 32) & 0xFFFFFFFF);  # Next 4 bytes
    $nonce .= pack('N', $counter & 0xFFFFFFFF);          # Next 4 bytes
    $nonce .= pack('C', $is_final ? 1 : 0);              # Last byte: final flag

    return $nonce;
}

sub age_scrypt_decrypter ($password) {
   return Crypt::Age::Simple::Decrypt->new(
      identity => { scrypt => $password },
      max_header_length => 150,
   );
}

sub age_scrypt_encrypter ($password) {
   Crypt::Age::Simple::Encrypt->new(recipients => { scrypt => $password });
}

sub age_scrypt_unwrap_file_key ($stanza, $password) {
   my ($salt64, $Nlog2) = $stanza->args->@*;
   my $salt = Crypt::Age::Stanza::decode_base64_no_padding($salt64);
   my $wrap_key = age_scrypt_wrap_key($password, $salt, $Nlog2);
   my $body = $stanza->body;
   my $file_key = eval {
      Crypt::Age::Primitives->unwrap_file_key($wrap_key, $body);
   };
   return $file_key;
}

sub age_scrypt_wrap_key ($password, $salt, $Nlog2) {
   my $full_salt = SCRYPT_SALT_PREFIX . $salt;
   my $N = 2 ** $Nlog2;
   my $r = 8;
   my $p = 1;
   my $len = 32;
   return scrypt_pbkdf($password, $full_salt, $N, $r, $p, $len);
}

sub age_x25519_decrypter ($id) {
   return Crypt::Age::Simple::Decrypt->new(
      identity => { x25519 => $id },
      max_header_length => CHUNK_SIZE, # should be pretty generous
   );
}

sub age_x25519_encrypter ($rec) {
   $rec = [ $rec ] unless ref($rec) eq 'ARRAY';
   Crypt::Age::Simple::Encrypt->new(recipients => { x25519 => $rec });
}

sub buffer ($x) {
   return undef unless defined($x);
   return $x if blessed($x);
   $x = { input => $x } unless ref($x) eq 'HASH';
   return Crypt::Age::Simple::Buffer->new($x);
}

1;
