package Crypt::Age::Keys;
# ABSTRACT: Key generation and Bech32 encoding for age encryption
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use Crypt::PK::X25519;
use namespace::clean;


# Bech32 character set
my $BECH32_CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
my %BECH32_CHAR_TO_VAL = map { substr($BECH32_CHARSET, $_, 1) => $_ } 0..31;

# Human-readable parts
my $HRP_PUBLIC  = 'age';
my $HRP_SECRET  = 'age-secret-key-';

sub generate_keypair {
    my ($class) = @_;

    my $pk = Crypt::PK::X25519->new;
    $pk->generate_key;

    my $secret_bytes = $pk->export_key_raw('private');
    my $public_bytes = $pk->export_key_raw('public');

    my $public_key = $class->encode_public_key($public_bytes);
    my $secret_key = $class->encode_secret_key($secret_bytes);

    return ($public_key, $secret_key);
}


sub encode_public_key {
    my ($class, $bytes) = @_;
    croak "Public key must be 32 bytes" unless length($bytes) == 32;
    return $class->bech32_encode($HRP_PUBLIC, $bytes);
}


sub decode_public_key {
    my ($class, $encoded) = @_;
    my ($hrp, $bytes) = $class->bech32_decode($encoded);
    # $hrp is caller material, not a value from this module: bech32_decode
    # returns everything before the last "1" of the string it was handed. For
    # a real key of the other kind that is only the other type prefix, but a
    # string whose HRP carries key characters reaches here too, so nothing of
    # it is quoted. The check is against a single constant, so naming the
    # expected value says everything the caller needs. Written out in full at
    # decode_secret_key, where the same value is a secret; both read the same
    # way on purpose.
    croak 'Invalid public key HRP: expected the literal '.$HRP_PUBLIC
        .' prefix, pass an age recipient rather than an identity or some '
        .'other Bech32 string'
        unless lc($hrp) eq $HRP_PUBLIC;
    croak "Invalid public key length" unless length($bytes) == 32;
    return $bytes;
}


sub encode_secret_key {
    my ($class, $bytes) = @_;
    croak "Secret key must be 32 bytes" unless length($bytes) == 32;
    return uc($class->bech32_encode($HRP_SECRET, $bytes));
}


sub decode_secret_key {
    my ($class, $encoded) = @_;
    my ($hrp, $bytes) = $class->bech32_decode($encoded);
    # The same croak as in decode_public_key, and the half where the quoted
    # value could be a secret. $hrp is everything before the last "1" of the
    # caller's string, so it is a prefix of what arrived.
    #
    # Reaching this croak takes a Bech32 string whose checksum verifies over
    # the wrong HRP, which bounds it but does not make it safe. Measured on
    # this module: a real key truncated anywhere dies earlier at "Invalid
    # bech32: no separator", "Invalid bech32: empty data" or "Invalid bech32
    # checksum", and one with trailing junk at "Invalid bech32 checksum" --
    # none of those quote anything. So the string that gets here is
    # constructed rather than mistyped; and a string constructed with the
    # opening characters of a real identity as its HRP is precisely how those
    # characters would be read back out of an exception, from inside this
    # module, into a log the caller can no longer redact.
    #
    # As at the version-line croak in Crypt::Age::Header, the clause after the
    # colon carries the requirement and the fix rather than a description of
    # what arrived. The expected HRP is a constant of the format and is named.
    croak 'Invalid secret key HRP: expected the literal '.$HRP_SECRET
        .' prefix, pass an age identity rather than a recipient or some '
        .'other Bech32 string'
        unless lc($hrp) eq $HRP_SECRET;
    croak "Invalid secret key length" unless length($bytes) == 32;
    return $bytes;
}


sub public_key_from_secret {
    my ($class, $secret_key) = @_;
    my $secret_bytes = $class->decode_secret_key($secret_key);
    my $pk = Crypt::PK::X25519->new;
    $pk->import_key_raw($secret_bytes, 'private');
    my $public_bytes = $pk->export_key_raw('public');
    return $class->encode_public_key($public_bytes);
}



# Bech32 implementation (BIP-173)

sub bech32_polymod {
    my ($values) = @_;
    my @GEN = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);
    my $chk = 1;
    for my $v (@$values) {
        my $b = $chk >> 25;
        $chk = (($chk & 0x1ffffff) << 5) ^ $v;
        for my $i (0..4) {
            $chk ^= (($b >> $i) & 1) ? $GEN[$i] : 0;
        }
    }
    return $chk;
}

sub bech32_hrp_expand {
    my ($hrp) = @_;
    my @result;
    for my $c (split //, $hrp) {
        push @result, ord($c) >> 5;
    }
    push @result, 0;
    for my $c (split //, $hrp) {
        push @result, ord($c) & 31;
    }
    return \@result;
}

sub bech32_create_checksum {
    my ($hrp, $data) = @_;
    my @values = (@{bech32_hrp_expand($hrp)}, @$data, 0, 0, 0, 0, 0, 0);
    my $polymod = bech32_polymod(\@values) ^ 1;
    my @checksum;
    for my $i (0..5) {
        push @checksum, ($polymod >> (5 * (5 - $i))) & 31;
    }
    return \@checksum;
}

sub bech32_verify_checksum {
    my ($hrp, $data) = @_;
    return bech32_polymod([@{bech32_hrp_expand($hrp)}, @$data]) == 1;
}

sub bech32_encode {
    my ($class, $hrp, $bytes) = @_;

    # Convert 8-bit bytes to 5-bit groups
    my $data = $class->_convert_bits([unpack('C*', $bytes)], 8, 5, 1);

    my $checksum = bech32_create_checksum($hrp, $data);
    my @combined = (@$data, @$checksum);

    my $result = $hrp . '1';
    for my $d (@combined) {
        $result .= substr($BECH32_CHARSET, $d, 1);
    }

    return $result;
}


sub bech32_decode {
    my ($class, $str) = @_;

    # BIP-173: "Decoders MUST NOT accept strings where some characters are
    # uppercase and some are lowercase". The checksum is computed over the
    # lowercase form either way, so a mixed-case string would otherwise verify
    # and decode; both age 1.2.1 and rage 0.12.1 reject it.
    croak "Invalid bech32: mixed case"
        if $str =~ /[a-z]/ && $str =~ /[A-Z]/;

    # Find separator
    my $sep_pos = rindex($str, '1');
    croak "Invalid bech32: no separator" if $sep_pos < 1;
    croak "Invalid bech32: empty data" if $sep_pos + 1 >= length($str);

    my $hrp = substr($str, 0, $sep_pos);
    my $data_part = substr($str, $sep_pos + 1);

    # Decode data part. The offending character is located, never quoted: no
    # character of an encoded age key can reach this branch (every one of them
    # is inside the charset by construction), so the only thing that could be
    # copied into the exception is one byte of some other secret handed to this
    # public method by mistake -- a passphrase, say. The offset counts from the
    # start of $str rather than from the start of the data part, because $str
    # is what the caller holds: substr($str, $N, 1) then lands on the character
    # without the caller re-deriving where the separator was. Lowercasing one
    # character at a time keeps that offset exact even where lc() of a single
    # character is not a single character.
    my @data;
    for my $i (0 .. length($data_part) - 1) {
        my $c = lc(substr($data_part, $i, 1));
        croak "Invalid bech32 character at offset ".($sep_pos + 1 + $i)
            .": expected a character of the Bech32 charset"
            unless exists $BECH32_CHAR_TO_VAL{$c};
        push @data, $BECH32_CHAR_TO_VAL{$c};
    }

    croak "Invalid bech32 checksum"
        unless bech32_verify_checksum(lc($hrp), \@data);

    # Remove checksum (last 6 values)
    splice(@data, -6);

    # Convert 5-bit groups back to 8-bit bytes
    my $bytes = $class->_convert_bits(\@data, 5, 8, 0);

    return ($hrp, pack('C*', @$bytes));
}


sub _convert_bits {
    my ($class, $data, $from_bits, $to_bits, $pad) = @_;

    my $acc = 0;
    my $bits = 0;
    my @result;
    my $maxv = (1 << $to_bits) - 1;

    for my $v (@$data) {
        $acc = ($acc << $from_bits) | $v;
        $bits += $from_bits;
        while ($bits >= $to_bits) {
            $bits -= $to_bits;
            push @result, ($acc >> $bits) & $maxv;
        }
    }

    if ($pad) {
        if ($bits > 0) {
            push @result, ($acc << ($to_bits - $bits)) & $maxv;
        }
    } else {
        croak "Invalid padding" if $bits >= $from_bits;
        croak "Non-zero padding" if (($acc << ($to_bits - $bits)) & $maxv);
    }

    return \@result;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Age::Keys - Key generation and Bech32 encoding for age encryption

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Crypt::Age::Keys;

    # Generate keypair
    my ($public, $secret) = Crypt::Age::Keys->generate_keypair();

    # Encode/decode public keys
    my $encoded_public = Crypt::Age::Keys->encode_public_key($public_bytes);
    my $public_bytes = Crypt::Age::Keys->decode_public_key('age1...');

    # Encode/decode secret keys
    my $encoded_secret = Crypt::Age::Keys->encode_secret_key($secret_bytes);
    my $secret_bytes = Crypt::Age::Keys->decode_secret_key('AGE-SECRET-KEY-1...');

    # Derive public key from secret key
    my $public = Crypt::Age::Keys->public_key_from_secret($secret);

=head1 DESCRIPTION

This module provides key generation and Bech32 encoding/decoding for age encryption.

age uses X25519 (Curve25519 Diffie-Hellman) for key agreement. Keys are encoded
using Bech32, the same encoding used for Bitcoin SegWit addresses (BIP-173).

Public keys use the human-readable part C<age> and are lowercase. Secret keys
use the human-readable part C<age-secret-key-> and are uppercase.

This is an internal module used by L<Crypt::Age>.

=head2 generate_keypair

    my ($public_key, $secret_key) = Crypt::Age::Keys->generate_keypair();

Generates a new X25519 keypair.

Returns a list of two Bech32-encoded strings:

=over 4

=item * C<$public_key> - Starts with C<age1>, lowercase

=item * C<$secret_key> - Starts with C<AGE-SECRET-KEY-1>, uppercase

=back

=head2 encode_public_key

    my $encoded = Crypt::Age::Keys->encode_public_key($public_bytes);

Encodes a 32-byte X25519 public key as a Bech32 string with HRP C<age>.

Returns a lowercase string starting with C<age1>.

=head2 decode_public_key

    my $public_bytes = Crypt::Age::Keys->decode_public_key('age1...');

Decodes a Bech32-encoded age public key to raw bytes.

Dies if the HRP is not C<age>, if the decoded data is not 32 bytes, or if the
string mixes upper- and lowercase; see L</bech32_decode>. The HRP is compared
case-insensitively, so an all-uppercase C<AGE1...> key is accepted as well.

The HRP mismatch is reported as C<"Invalid public key HRP: expected the
literal age prefix, pass an age recipient rather than an identity or some
other Bech32 string">. It names the expected HRP, which is a constant of the
format, and B<not> the one that arrived: the received HRP is everything before
the last C<1> of the string that was passed in, so it is a prefix of the
caller's own material. Here that material is a public key and no secret is at
stake, but the message reads the same as L</decode_secret_key>'s, where it is.
Callers matching on the old C<"expected 'age', got '...'"> wording see the new
message instead.

=head2 encode_secret_key

    my $encoded = Crypt::Age::Keys->encode_secret_key($secret_bytes);

Encodes a 32-byte X25519 secret key as a Bech32 string with HRP C<age-secret-key->.

Returns an uppercase string starting with C<AGE-SECRET-KEY-1>.

=head2 decode_secret_key

    my $secret_bytes = Crypt::Age::Keys->decode_secret_key('AGE-SECRET-KEY-1...');

Decodes a Bech32-encoded age secret key to raw bytes.

Dies if the HRP is not C<age-secret-key->, if the decoded data is not 32 bytes,
or if the string mixes upper- and lowercase; see L</bech32_decode>. The HRP is
compared case-insensitively, so an all-lowercase C<age-secret-key-1...> key is
accepted as well as the uppercase form L</encode_secret_key> emits.

The HRP mismatch is reported as C<"Invalid secret key HRP: expected the literal
age-secret-key- prefix, pass an age identity rather than a recipient or some
other Bech32 string">, and quotes no part of what arrived. The received HRP is
everything before the last C<1> of the caller's string, so a string whose HRP
is the opening characters of a real identity would have had those characters
written into an exception raised inside this module, where the caller can no
longer redact them.

Reaching that croak needs a Bech32 string whose checksum verifies over the
wrong HRP, so it is a constructed input rather than a mistyped one: a key
truncated anywhere dies first with C<"Invalid bech32: no separator">,
C<"Invalid bech32: empty data"> or C<"Invalid bech32 checksum">, and one with
trailing junk with C<"Invalid bech32 checksum">, none of which quote anything
either. The everyday way to reach it -- passing a public key here, or an
identity to L</decode_public_key> -- puts only the other type's prefix in that
position. Callers matching on the old C<"expected 'age-secret-key-', got
'...'"> wording see the new message instead.

=head2 public_key_from_secret

    my $public_key = Crypt::Age::Keys->public_key_from_secret($secret_key);

Derives the public key from a secret key.

Takes a Bech32-encoded secret key and returns the corresponding Bech32-encoded
public key. This is useful for when you have a secret key and need to know
what public key it corresponds to.

=head1 IMPLEMENTATION NOTES

C<bech32_polymod>, C<bech32_hrp_expand>, C<bech32_create_checksum> and
C<bech32_verify_checksum> below implement the checksum algorithm from BIP-173.
They are called only by L</bech32_encode> and L</bech32_decode> in this same
class, as plain functions rather than through the C<< $class->method(...) >>
convention the rest of this module uses, and are not documented individually
here.

=head2 bech32_encode

    my $encoded = Crypt::Age::Keys->bech32_encode($hrp, $bytes);

Encodes C<$bytes> as Bech32 (BIP-173) with the given human-readable part
C<$hrp>: converts the bytes from 8-bit to 5-bit groups, computes the checksum,
and joins C<$hrp>, the C<1> separator, the data and the checksum through the
Bech32 charset.

This is the generic codec L</encode_public_key> and L</encode_secret_key> call;
most callers want those instead, since they also know the age HRPs and enforce
the 32-byte key length that this method does not.

=head2 bech32_decode

    my ($hrp, $bytes) = Crypt::Age::Keys->bech32_decode($encoded);

Decodes a Bech32 (BIP-173) string, verifying its checksum. Returns the
human-readable part exactly as it appeared in C<$encoded> (not lowercased) and
the decoded data as raw bytes.

This is the generic codec L</decode_public_key> and L</decode_secret_key> call;
most callers want those instead, since they also check the HRP and the decoded
length.

Dies if there is no C<1> separator, if the data part is empty, if it contains a
character outside the Bech32 charset, or if the checksum does not verify.

The charset failure names the position rather than the character: C<Invalid
bech32 character at offset N>, where C<N> is a 0-based offset into the string
that was passed in -- not into the data part after the separator -- so
C<substr($encoded, $N, 1)> is the character it rejected. Withholding the
character is deliberate. Anything a caller passes reaches here, and a string
that is not an age key at all -- a passphrase handed to this method by mistake
-- would otherwise have one of its own bytes quoted back in an exception that
tends to end up in a log. No byte of an actual key is at stake either way:
every character of an encoded key is inside the charset, so none of them can
reach this failure.

BIP-173 also requires an encoding to be entirely uppercase or entirely
lowercase, and this method enforces that: a string mixing the two dies with
C<Invalid bech32: mixed case> before the separator is even looked for. An
all-uppercase and an all-lowercase string are both accepted, and decode to the
same bytes -- the checksum is verified against the lowercased HRP, since
BIP-173 defines it over the lowercase form regardless of how the string is
written.

=head1 SEE ALSO

=over 4

=item * L<Crypt::Age> - Main age encryption module

=item * L<Crypt::PK::X25519> - X25519 key handling from L<CryptX>

=item * L<https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki> - Bech32 specification

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-crypt-age/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
