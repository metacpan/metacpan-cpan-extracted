package Crypt::FPE::FF1;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);

# Public constructor
sub new {
  my ($class, %opt) = @_;
  my $radix = $opt{radix} // 10;

  # Prefer hex inputs; if caller gave raw bytes, convert to hex
  my $key_hex   = defined $opt{key_hex}   ? $opt{key_hex}
                 : defined $opt{key}      ? _as_hex($opt{key})
                 : die "key or key_hex required";

  my $tweak_hex = defined $opt{tweak_hex} ? $opt{tweak_hex}
                 : defined $opt{tweak}    ? _as_hex($opt{tweak})
                 : '';

  # ! pass the class as first arg; XS signature is (class, key, tweak, radix)
  my $self = $class->__create_key($key_hex, $tweak_hex, $radix);
  return $self;
}

sub _as_hex {
  my ($x) = @_;
  return $x if $x =~ /\A[0-9A-Fa-f]+\z/ && (length($x) % 2 == 0); # already hex
  return unpack('H*', $x);                                        # bytes -> hex
}

# The C layer's internal split (u = floor(n/2)) degenerates for n < 2
# (A and B end up aliasing the same buffer), which previously crashed the
# whole process via a C-level assert. This check is never optional.
sub _check_min_length {
  my ($self, $s) = @_;
  my $n = length $s;
  die "FF1: input length must be >= 2 (got " . $n . ")\n" if $n < 2;
}

# NIST SP 800-38G requires radix^length >= 1,000,000. Below this, FF1's
# security guarantees don't hold (small domains are brute-forceable).
# Unlike _check_min_length, callers that have explicitly acknowledged the
# weaker guarantee (see Crypt::FPE::FF1::Format's 'permissive' mode) may
# skip this check; it is never skipped by default.
sub _check_nist_floor {
  my ($self, $s) = @_;
  my $radix = $self->__radix;
  my $n = length $s;

  my $domain = 1;
  for (1 .. $n) {
    $domain *= $radix;
    last if $domain >= 1_000_000;
  }
  die "FF1: radix^length must be >= 1,000,000 per NIST SP 800-38G "
    . "(radix=$radix, length=$n)\n" if $domain < 1_000_000;
}

# map_chars() in the C layer silently reinterprets any character outside
# 0-9/a-z/A-Z as str[i]-'0', and never checks the result against radix,
# so out-of-alphabet or out-of-radix input is corrupted rather than
# rejected (and the corruption isn't invertible on decrypt).
sub _check_alphabet {
  my ($self, $s) = @_;
  my $radix = $self->__radix;
  for my $c (split //, $s) {
    my $v = $c =~ /[0-9]/ ? ord($c) - ord('0')
          : $c =~ /[a-z]/ ? ord($c) - ord('a') + 10
          : $c =~ /[A-Z]/ ? ord($c) - ord('A') + 36
          : die "FF1: character '$c' is not a valid digit for radix $radix\n";
    die "FF1: character '$c' is not a valid digit for radix $radix\n"
      if $v >= $radix;
  }
}

sub encrypt {
  my ($self, $plaintext) = @_;
  $self->_check_min_length($plaintext);
  $self->_check_nist_floor($plaintext);
  $self->_check_alphabet($plaintext);
  $self->__encrypt($plaintext);  # XS
}

sub decrypt {
  my ($self, $ciphertext) = @_;
  $self->_check_min_length($ciphertext);
  $self->_check_nist_floor($ciphertext);
  $self->_check_alphabet($ciphertext);
  $self->__decrypt($ciphertext); # XS
}

# For callers that have explicitly and knowingly accepted a domain below
# NIST's minimum (e.g. Crypt::FPE::FF1::Format's 'permissive' mode) but
# still need the non-negotiable safety checks that prevent a process
# crash or silent, non-invertible corruption in the C layer.
sub _encrypt_below_floor {
  my ($self, $plaintext) = @_;
  $self->_check_min_length($plaintext);
  $self->_check_alphabet($plaintext);
  $self->__encrypt($plaintext);
}

sub _decrypt_below_floor {
  my ($self, $ciphertext) = @_;
  $self->_check_min_length($ciphertext);
  $self->_check_alphabet($ciphertext);
  $self->__decrypt($ciphertext);
}

1;
