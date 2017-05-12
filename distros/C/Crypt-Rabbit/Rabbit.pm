package Crypt::Rabbit;

use strict;
use warnings;
require Exporter;

our @EXPORT_OK = qw(new encrypt decrypt keysize rounds);
our $VERSION = '1.0.0';
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Crypt::Rabbit', $VERSION);

# Preloaded methods go here.

sub keysize { 16 }    # 16 bytes
sub rounds { 1 }      # may be useful for some applications

sub encrypt {
    my ($class, $str) = @_;
    my $len = length $str;
    my $pad = pack "a" x ((16 - ($len % 16)) % 16), \000;
    $str .= $pad;
    my $ciphertext = rabbit_enc($class, $str);
    return substr($ciphertext, 0, $len);
}

sub decrypt {
    my ($class, $str) = @_;
    my $len = length $str;
    my $pad = pack "a" x ((16 - ($len % 16)) % 16), \000;
    $str .= $pad;
    my $ciphertext = rabbit_enc($class, $str);
    return substr($ciphertext, 0, $len);
}

1;

__END__

=head1 NAME

Crypt::Rabbit - A new stream cipher based on the properties of counter
assisted stream ciphers

=head1 SYNOPSIS

    use Crypt::Rabbit;

    $cipher = new Crypt::Rabbit $key;
    $ciphertext = $cipher->encrypt($plaintext);
    $ks = $cipher->keysize();
    $plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Rabbit is a new stream cipher based on the properties of counter
assisted stream ciphers, invented by Martin Boesgaard, Mette Vesterager,
Thomas Pedersen, Jesper Christiansen, and Ove Scavenius of Cryptico A/S.

This module supports the following methods:

=over

=item B<new()>

Initializes the internal states of Rabbit

=item B<encrypt($data)>

Encrypts the data stream B<$data>

=item B<decrypt($data)>

Decrypts the data stream B<$data>

B<decrypt($data)> is the same as B<encrypt($data)>

=item B<keysize()>

Returns the size (in bytes) of the key used (16, in this case)

=back

=head1 CAVEAT

The internal states of Rabbit are updated every time B<encrypt()> or
B<decrypt()> are called. And since encryption/decryption depends on the
internal states, a plaintext encrypted with a call to B<encrypt()> will
not decrypt to the original message by just a call to B<decrypt()>. The
proper way to decrypt a ciphertext is to re-initialize the internal
states (by calling B<new()>) first before calling B<decrypt()>.

=head1 BUG

For the sake of simplicity, the C implementation encrypts and decrypts
data in multiples of 16 bytes. If the last block of data is not a
multiple of 16 bytes, it is padded with null characters before
encryption. The resulting ciphertext is then truncated to the original
message length before being output. An undesirable consequence of this
is that encryption/decryption always starts at multiples of 16 bytes of
the pseudorandom data stream produced by Rabbit. Improvements are most
welcome. Please read contact.html for contact information.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Julius C. Duque

Copyright (C) 2003 Cryptico A/S

This library is free software; you can redistribute it and/or modify it
under the same terms as the GNU General Public License.

This implementation of the Rabbit stream cipher is derived from the
reference ANSI C code provided in the appendix of the paper, "Rabbit:
A New High-Performance Stream Cipher", by Martin Boesgaard,
Mette Vesterager, Thomas Pedersen, Jesper Christiansen, and
Ove Scavenius of Cryptico A/S.

For more information, please visit the Cryptico website at
C<http://www.cryptico.com>.

The Rabbit stream cipher is the copyrighted work of Cryptico A/S, and
use of Rabbit may only be used for non-commercial purposes. Any
reproduction or redistribution of Rabbit not in accordance with
Cryptico's license agreement is expressly prohibited by law, and may
result in severe civil and criminal penalties. Violators will be
prosecuted to the maximum extent possible.

This copyright does not prohibit distribution of any version of Perl
containing this extension under the terms of the GNU or Artistic
licenses.

