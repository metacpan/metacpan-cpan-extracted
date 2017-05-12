package Crypt::Skip32;

use 5.008000;
use strict;
use warnings;
use Carp qw(croak);

if (not $ENV{CRYPT_SKIP32_PP} and eval 'use Crypt::Skip32::XS; 1') {
  eval q(sub Crypt::Skip32 () { 'Crypt::Skip32::XS' });
}

our $VERSION = '0.18';

eval <<'EOP' if not defined &new;

# Number of bytes in the 4 byte (32-bit) block.
sub blocksize {
  return 4;
}

# Number of bytes in the 10 byte (80-bit) key.
sub keysize {
  return 10;
}

# New cipher constructor
sub new {
  my ($class, $key) = @_;

  my @key_bytes = unpack('C*', $key);
  croak "key must be 10 bytes long"
    unless scalar @key_bytes == 10;

  my $self = {
    key       => $key,
    key_bytes => \@key_bytes,
  };
  bless $self, $class;

  return $self;
}

# Encrypt a 4 byte (32-bit) block
sub encrypt {
  my ($self, $plaintext) = @_;

  my @input_bytes  = unpack('C*', $plaintext);
  croak "plaintext must be 4 bytes long"
    unless scalar @input_bytes == 4;
  my @output_bytes = _skip32($self->{key_bytes}, \@input_bytes, 1);
  my $cipher_text  = pack('C*', @output_bytes);

  return $cipher_text;
}

# Decrypt a 4 byte (32-bit) block
sub decrypt {
  my ($self, $ciphertext) = @_;

  my @input_bytes  = unpack('C*', $ciphertext);
  croak "ciphertext must be 4 bytes long"
    unless scalar @input_bytes == 4;
  my @output_bytes = _skip32($self->{key_bytes}, \@input_bytes, 0);
  my $plain_text   = pack('C*', @output_bytes);

  return $plain_text;
}

# Remaining Perl code is a direct translation of the SKIP32 C implementation

my @FTABLE =
(
0xa3,0xd7,0x09,0x83,0xf8,0x48,0xf6,0xf4,0xb3,0x21,0x15,0x78,0x99,0xb1,0xaf,0xf9,
0xe7,0x2d,0x4d,0x8a,0xce,0x4c,0xca,0x2e,0x52,0x95,0xd9,0x1e,0x4e,0x38,0x44,0x28,
0x0a,0xdf,0x02,0xa0,0x17,0xf1,0x60,0x68,0x12,0xb7,0x7a,0xc3,0xe9,0xfa,0x3d,0x53,
0x96,0x84,0x6b,0xba,0xf2,0x63,0x9a,0x19,0x7c,0xae,0xe5,0xf5,0xf7,0x16,0x6a,0xa2,
0x39,0xb6,0x7b,0x0f,0xc1,0x93,0x81,0x1b,0xee,0xb4,0x1a,0xea,0xd0,0x91,0x2f,0xb8,
0x55,0xb9,0xda,0x85,0x3f,0x41,0xbf,0xe0,0x5a,0x58,0x80,0x5f,0x66,0x0b,0xd8,0x90,
0x35,0xd5,0xc0,0xa7,0x33,0x06,0x65,0x69,0x45,0x00,0x94,0x56,0x6d,0x98,0x9b,0x76,
0x97,0xfc,0xb2,0xc2,0xb0,0xfe,0xdb,0x20,0xe1,0xeb,0xd6,0xe4,0xdd,0x47,0x4a,0x1d,
0x42,0xed,0x9e,0x6e,0x49,0x3c,0xcd,0x43,0x27,0xd2,0x07,0xd4,0xde,0xc7,0x67,0x18,
0x89,0xcb,0x30,0x1f,0x8d,0xc6,0x8f,0xaa,0xc8,0x74,0xdc,0xc9,0x5d,0x5c,0x31,0xa4,
0x70,0x88,0x61,0x2c,0x9f,0x0d,0x2b,0x87,0x50,0x82,0x54,0x64,0x26,0x7d,0x03,0x40,
0x34,0x4b,0x1c,0x73,0xd1,0xc4,0xfd,0x3b,0xcc,0xfb,0x7f,0xab,0xe6,0x3e,0x5b,0xa5,
0xad,0x04,0x23,0x9c,0x14,0x51,0x22,0xf0,0x29,0x79,0x71,0x7e,0xff,0x8c,0x0e,0xe2,
0x0c,0xef,0xbc,0x72,0x75,0x6f,0x37,0xa1,0xec,0xd3,0x8e,0x62,0x8b,0x86,0x10,0xe8,
0x08,0x77,0x11,0xbe,0x92,0x4f,0x24,0xc5,0x32,0x36,0x9d,0xcf,0xf3,0xa6,0xbb,0xac,
0x5e,0x6c,0xa9,0x13,0x57,0x25,0xb5,0xe3,0xbd,0xa8,0x3a,0x01,0x05,0x59,0x2a,0x46
);

sub _g {
  my ($rkey, $k, $w) = @_;
  my @key = @$rkey;

  my $g1 = ($w>>8)&0xff;
  my $g2 = $w&0xff;
  my $g3 = $FTABLE[$g2 ^ $key[(4*$k)%10]] ^ $g1;
  my $g4 = $FTABLE[$g3 ^ $key[(4*$k+1)%10]] ^ $g2;
  my $g5 = $FTABLE[$g4 ^ $key[(4*$k+2)%10]] ^ $g3;
  my $g6 = $FTABLE[$g5 ^ $key[(4*$k+3)%10]] ^ $g4;

  return (($g5<<8) + $g6);
}

sub _skip32 {
  my ($rkey, $rbuf, $encrypt) = @_;
  my @buf = @$rbuf;

  my $k; # round number
  my $i; # round counter
  my $kstep;
  my $wl;
  my $wr;

  # sort out direction
  if ($encrypt) {
    $kstep = 1;
    $k = 0;
  }
  else {
    $kstep = -1;
    $k = 23;
  }

  # pack into words
  $wl = ($buf[0] << 8) + $buf[1];
  $wr = ($buf[2] << 8) + $buf[3];

  # 24 feistel rounds, doubled up
  for ($i = 0; $i < 24/2; ++$i) {
    $wr ^= _g($rkey, $k, $wl) ^ $k;
    $k += $kstep;
    $wl ^= _g($rkey, $k, $wr) ^ $k;
    $k += $kstep;
  }

  # implicitly swap halves while unpacking
  $buf[0] = $wr >> 8;
  $buf[1] = $wr & 0xFF;
  $buf[2] = $wl >> 8;
  $buf[3] = $wl & 0xFF;

  return @buf;
}

EOP

1;

__END__

=head1 NAME

Crypt::Skip32 - 32-bit block cipher based on Skipjack

=head1 SYNOPSIS

  use Crypt::Skip32;

  my $cipher     = new Crypt::Skip32 $key;
  my $ciphertext = $cipher->encrypt($plaintext);
  my $plaintext  = $cipher->decrypt($ciphertext);
  my $blocksize  = $cipher->blocksize;
  my $keysize    = $cipher->keysize;

=head1 DESCRIPTION

SKIP32 is a 80-bit key, 32-bit block cipher based on Skipjack.  The
Perl code for the algorithm is a direct translation from C to Perl of
skip32.c by Greg Rose found here:

  http://www.qualcomm.com.au/PublicationsDocs/skip32.c

This cipher can be handy for scrambling small (32-bit) values when you
would like to obscure them while keeping the encrypted output size
small (also only 32 bits).

One example where Crypt::Skip32 has been useful: You have numeric
database record ids which increment sequentially. You would like to
use them in URLs, but you don't want to make it obvious how many X's
you have in the database by putting the ids directly in the URLs.

You can use Crypt::Skip32 to scramble ids and put the resulting 32-bit
value in URLs (perhaps as 8 hex digits or some other shorter
encoding).  When a user requests a URL, you can unscramble the id to
retrieve the object from the database.

Warning: A 32-bit value can only go a little over 4 billion
(American).  Plan ahead if what you need to encrypt might eventually
go over this limit.

=head1 FUNCTIONS

=over 4

=item new

  my $cipher = new Crypt::Skip32 $key;

Creates a new Crypt::Skip32 block cipher object, using $key, where
$key is a key of C<keysize> bytes (10).

=item encrypt

  my $ciphertext = $cipher->encrypt($plaintext);

Encrypt $plaintext and return the $ciphertext.  The $plaintext must be
of C<blocksize> bytes (4).

See the EXAMPLE below for hints on how to take a plain integer,
encrypt it, and encode it for use in URLs and other non-binary
formats.

=item decrypt

  my $plaintext = $cipher->decrypt($ciphertext);

Decrypt $ciphertext and return the $plaintext.  The $ciphertext must
be of C<blocksize> bytes (4).

=item blocksize

  my $blocksize = $cipher->blocksize;
  my $blocksize = Crypt::Skip32->blocksize;

Returns the size (in bytes) of the block cipher.  This is always 4
bytes (for 32 bits).

=item keysize

  my $keysize = $cipher->keysize;
  my $keysize = Crypt::Skip32->keysize;

Returns the size (in bytes) of the key.  This is always 10 bytes (for
80 bits).

=back

=head1 NOTES

If L<Crypt::Skip32::XS> is installed, this module will use it and the
constructor will return an object of that type, though the interface is
identical.  You can stick with the pure Perl version by setting the
CRYPT_SKIP32_PP environment variable before using this module.

If reporting a bug, please try to determine (if possible) if it is this module
or the XS one, and report it to the corresponding maintainer.

=head1 EXAMPLE

This sample code demonstrates how Crypt::Skip32 can be used to encrypt
unsigned integers and encode them for use in web URLs, form values,
and other places where short encrypted text might be useful.

  use Crypt::Skip32;

  # Create a cipher. Change the long hex string to your secret key.
  my $key         = pack("H20", "112233445566778899AA");
  my $cipher      = new Crypt::Skip32 $key; # Always 10 bytes!

  # Encrypt an unsigned integer (under 2^32) into an 8-digit hex string.
  my $number      = 3493209676;
  my $plaintext   = pack("N", $number);
  my $ciphertext  = $cipher->encrypt($plaintext); # Always 4 bytes!
  my $cipherhex   = unpack("H8", $ciphertext);
  print "$number encrypted and converted to hex: $cipherhex\n";

  # Decrypt an encrypted, hexified unsigned integer.
  my $ciphertext2 = pack("H8", $cipherhex);
  my $plaintext2  = $cipher->decrypt($ciphertext2); # Always 4 bytes!
  my $number2     = unpack("N", $plaintext2);
  print "$cipherhex converted back and decrypted: $number2\n";

The above code generates the output:

  3493209676 encrypted and converted to hex: 6da27100
  6da27100 converted back and decrypted: 3493209676

=head1 CAVEATS

This initial alpha Perl implementation of Crypt::Skip32 has not been
extentively reviewed by cryptographic experts, nor has it been tested
extensively on many different platforms.  It is recommended that this
code not be used for applications which require a high level of
security.

Reviewers and testers welcomed.

Though this module has been coded to follow a Crypt::CBC usable
interface, it is not intended for use in encrypting long chunks of
text.  For those purposes, it is suggested you use another high
quality, proven cipher with a longer block size.

=head1 INSTALLATION

If your Linux distro does not have a prepared package for this module,
then the preferred method for installation is directly from the CPAN
using a command like:

    sudo cpan Crypt::Skip32

=head1 SOURCE

The source for this module is being maintained on github:

    https://github.com/alestic/Crypt-Skip32

Forks and patches will be reviewed, but please be aware that the
targeted functionality of this particular module is very narrow.

Feel free to build other abstractions on top of this module if you
want to make it easier to use or to create a particular application
for its use.

=head1 BUGS

Problems and feature requests can be submitted through the github
"issues" link:

    https://github.com/alestic/Crypt-Skip32/issues

A gentle reminder sent directly to the author (below) may also help
increase awareness and attention.

=head1 SEE ALSO

The original SKIP32 implementation in C by Greg Rose:
http://www.qualcomm.com.au/PublicationsDocs/skip32.c

The 80-bit key, 64-bit block Skipjack cipher created by the NSA (Perl
code maintained by Julius C. Duque): B<Crypt::Skipjack>

B<Crypt::Skip32::XS>

=head1 AUTHOR

Perl code maintained by Eric Hammond
E<lt>eric-cpan-2@thinksome.comE<gt>
http://www.anvilon.com

Original SKIP32 C code written 1999-04-27 by Greg Rose, based on an
implementation of the Skipjack algorithm written by Panu Rissanen.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2011 Eric Hammond E<lt>eric-cpan-2@thinksome.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

The original C version of SKIP32 by Greg Rose (see below) is
explicitly "not copyright, no rights reserved".  Even so, permission
was requested and granted to make a Perl version available on the
CPAN.

=head1 ORIGINAL C SOURCE

 /*
    SKIP32 -- 32 bit block cipher based on SKIPJACK.
    Written by Greg Rose, QUALCOMM Australia, 1999/04/27.

    In common: F-table, G-permutation, key schedule.
    Different: 24 round feistel structure.
    Based on:  Unoptimized test implementation of SKIPJACK algorithm
	       Panu Rissanen <bande@lut.fi>

    SKIPJACK and KEA Algorithm Specifications
    Version 2.0
    29 May 1998

    Not copyright, no rights reserved.
 */

 typedef unsigned char   BYTE; /* 8 bits */
 typedef unsigned short  WORD; /* 16 bits */

 const BYTE ftable[256] = {
 0xa3,0xd7,0x09,0x83,0xf8,0x48,0xf6,0xf4,0xb3,0x21,0x15,0x78,0x99,0xb1,0xaf,0xf9,
 0xe7,0x2d,0x4d,0x8a,0xce,0x4c,0xca,0x2e,0x52,0x95,0xd9,0x1e,0x4e,0x38,0x44,0x28,
 0x0a,0xdf,0x02,0xa0,0x17,0xf1,0x60,0x68,0x12,0xb7,0x7a,0xc3,0xe9,0xfa,0x3d,0x53,
 0x96,0x84,0x6b,0xba,0xf2,0x63,0x9a,0x19,0x7c,0xae,0xe5,0xf5,0xf7,0x16,0x6a,0xa2,
 0x39,0xb6,0x7b,0x0f,0xc1,0x93,0x81,0x1b,0xee,0xb4,0x1a,0xea,0xd0,0x91,0x2f,0xb8,
 0x55,0xb9,0xda,0x85,0x3f,0x41,0xbf,0xe0,0x5a,0x58,0x80,0x5f,0x66,0x0b,0xd8,0x90,
 0x35,0xd5,0xc0,0xa7,0x33,0x06,0x65,0x69,0x45,0x00,0x94,0x56,0x6d,0x98,0x9b,0x76,
 0x97,0xfc,0xb2,0xc2,0xb0,0xfe,0xdb,0x20,0xe1,0xeb,0xd6,0xe4,0xdd,0x47,0x4a,0x1d,
 0x42,0xed,0x9e,0x6e,0x49,0x3c,0xcd,0x43,0x27,0xd2,0x07,0xd4,0xde,0xc7,0x67,0x18,
 0x89,0xcb,0x30,0x1f,0x8d,0xc6,0x8f,0xaa,0xc8,0x74,0xdc,0xc9,0x5d,0x5c,0x31,0xa4,
 0x70,0x88,0x61,0x2c,0x9f,0x0d,0x2b,0x87,0x50,0x82,0x54,0x64,0x26,0x7d,0x03,0x40,
 0x34,0x4b,0x1c,0x73,0xd1,0xc4,0xfd,0x3b,0xcc,0xfb,0x7f,0xab,0xe6,0x3e,0x5b,0xa5,
 0xad,0x04,0x23,0x9c,0x14,0x51,0x22,0xf0,0x29,0x79,0x71,0x7e,0xff,0x8c,0x0e,0xe2,
 0x0c,0xef,0xbc,0x72,0x75,0x6f,0x37,0xa1,0xec,0xd3,0x8e,0x62,0x8b,0x86,0x10,0xe8,
 0x08,0x77,0x11,0xbe,0x92,0x4f,0x24,0xc5,0x32,0x36,0x9d,0xcf,0xf3,0xa6,0xbb,0xac,
 0x5e,0x6c,0xa9,0x13,0x57,0x25,0xb5,0xe3,0xbd,0xa8,0x3a,0x01,0x05,0x59,0x2a,0x46
 };

 WORD
 g(BYTE *key, int k, WORD w)
 {
     BYTE g1, g2, g3, g4, g5, g6;

     g1 = (w>>8)&0xff;
     g2 = w&0xff;

     g3 = ftable[g2 ^ key[(4*k)%10]] ^ g1;
     g4 = ftable[g3 ^ key[(4*k+1)%10]] ^ g2;
     g5 = ftable[g4 ^ key[(4*k+2)%10]] ^ g3;
     g6 = ftable[g5 ^ key[(4*k+3)%10]] ^ g4;

     return ((g5<<8) + g6);
 }

 void
 skip32(BYTE key[10], BYTE buf[4], int encrypt)
 {
     int         k; /* round number */
     int         i; /* round counter */
     int         kstep;
     WORD        wl, wr;

     /* sort out direction */
     if (encrypt)
	 kstep = 1, k = 0;
     else
	 kstep = -1, k = 23;

     /* pack into words */
     wl = (buf[0] << 8) + buf[1];
     wr = (buf[2] << 8) + buf[3];

     /* 24 feistel rounds, doubled up */
     for (i = 0; i < 24/2; ++i) {
	 wr ^= g(key, k, wl) ^ k;
	 k += kstep;
	 wl ^= g(key, k, wr) ^ k;
	 k += kstep;
     }

     /* implicitly swap halves while unpacking */
     buf[0] = wr >> 8;   buf[1] = wr & 0xFF;
     buf[2] = wl >> 8;   buf[3] = wl & 0xFF;
 }

 #include <stdio.h>
 int main(int ac, char *av[])
 {
     BYTE        in[4] = { 0x33,0x22,0x11,0x00 };
     BYTE        key[10] = { 0x00,0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22,0x11 };
     int         i, encrypt;
     int         bt;

     if (ac == 1) {
	 skip32(key, in, 1);
	 printf("%02x%02x%02x%02x\n", in[0], in[1], in[2], in[3]);
	 if (in[0] != 0x81 || in[1] != 0x9d || in[2] != 0x5f || in[3] != 0x1f) {
	     printf("819d5f1f is the answer! Didn't encrypt correctly!\n");
	     return 1;
	 }
	 skip32(key, in, 0);
	 if (in[0] != 0x33 || in[1] != 0x22 || in[2] != 0x11 || in[3] != 0x00) {
	     printf("%02x%02x%02x%02x\n", in[0], in[1], in[2], in[3]);
	     printf("33221100 is the answer! Didn't decrypt correctly!\n");
	     return 1;
	 }
     }
     else if (ac != 4) {
	 fprintf(stderr, "usage: %s e/d kkkkkkkkkkkkkkkkkkkk dddddddd\n", av[0]);
	 return 1;
     }
     else {
	 encrypt = av[1][0] == 'e';
	 for (i = 0; i < 10; ++i) {
	     sscanf(&av[2][i*2], "%02x", &bt);
	     key[i] = bt;
	 }
	 for (i = 0; i < 4; ++i) {
	     sscanf(&av[3][i*2], "%02x", &bt);
	     in[i] = bt;
	 }
	 skip32(key, in, encrypt);
	 printf("%02x%02x%02x%02x\n", in[0], in[1], in[2], in[3]);
     }
     return 0;
 }

=cut
