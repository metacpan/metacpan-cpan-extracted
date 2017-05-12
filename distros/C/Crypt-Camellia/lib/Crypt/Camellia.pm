package Crypt::Camellia;

use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = '2.02';

require XSLoader;
XSLoader::load('Crypt::Camellia', $VERSION);

# Preloaded methods go here.

sub usage {
    my ($package, $filename, $line, $subr) = caller(1);
    $Carp::CarpLevel = 2;
    croak "Usage: $subr(@_)";
}

sub blocksize { 16 }
sub keysize   { 32 }

sub new{
    usage("new Camellia key") unless @_ == 2;
    my ($type, $key) = @_;
    my $self = { keysize => length($key) };
    bless $self, $type;
    if ($self->{keysize} != 16 && $self->{keysize} != 24 && $self->{keysize} != 32) {
        croak "wrong key length: key must be 128, 192 or 256 bits long";
    }
    $self->{keytable} = Crypt::Camellia::keygen($key, $self->{keysize}*8);
    return $self;
}

sub encrypt{
    usage("encrypt data[16 bytes]") unless @_ == 2;
    my ($self,$data) = @_;
    if (length $data != blocksize()) {
        croak "datasize not multiple of blocksize (16 bytes)";
    }
    return Crypt::Camellia::crypt($data, $self->{keytable}, $self->{keysize}*8, 1);
}

sub decrypt {
    usage("decrypt data[16 bytes]") unless @_ == 2;
    my ($self,$data) = @_;
    if (length $data != blocksize()) {
        croak "datasize not multiple of blocksize (16 bytes)";
    }
    return Crypt::Camellia::crypt($data, $self->{keytable}, $self->{keysize}*8, 0);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::Camellia - Perl Camellia encryption module

=head1 SYNOPSIS

  use Crypt::Camellia;
  my $cipher     = Crypt::Camellia->new($key); 
  my $ciphertext = $cipher->encrypt($plaintext);
  my $plaintext  = $cipher->decrypt($ciphertext);

  # more likely
  use Crypt::CBC;
  $cipher = Crypt::CBC->new( -key    => 'my secret key',
                             -cipher => 'Camellia'
                            );

=head1 DESCRIPTION

This module implements Camelia 128-bit Block Cipher for perl.
For Camellia.  Check L<https://info.isl.ntt.co.jp/crypt/eng/camellia/index_s.html>.  Here is an exerpt of that page.

=over 2

Camellia is a symmetric key block cipher developed jointly in 2000 by
world top class encryption researchers at NTT and Mitsubishi Electric
Corporation. Technologically speaking, Camellia naturally has not only
a high level of security, but also excellent efficiency and practical
characteristics. It can be implemented at high performance by software
on various platforms. In regard to hardware implementation, compact
and low-power consumption type implementation as well as high-speed
implementation is possible.

Based on these technological advantages, Camellia has been
internationally recognized, for example the selection project on the
European recommendation of strong cryptographic primitives, NESSIE,
evaluated Camellia to have "many similarities to the AES, so much of
the analysis for the AES is also applicable to Camellia." Currently,
Camellia is the only cipher internationally recognized which has the
same level of security and performance as AES, and is selected for
many international standard/recommended ciphers. In particular, as
Japanese domestic ciphers, this is the first case to be approved as
IETF standard ciphers (Proposed Standard RFC) .

=back

Crypt::Camellia has the following methods:

=over 2

 blocksize()
 keysize()
 encrypt()
 decrypt()

=back

Like many Crypt:: modules like L<Crypt::Blowfish> and L<Crypt::DES>,
this module works as a backend of L<Crypt::CBC>.

=head1 FUNCTIONS

=over 2

=item blocksize

Returns the size (in bytes) of the block cipher.  Currently this is a
fixed value of 16.

=item new

  my $cipher = Crypt::Camellia-E<gt>new($key);

This creates a new Crypt::Camellia BlockCipher object, using $key,
where $key is a key of C<keysize()> bytes (minimum of eight bytes).

=item encrypt

  my $ciphertext = $cipher-E<gt>encrypt($plaintext);

This function encrypts $plaintext and returns the $ciphertext
where $plaintext and $ciphertext must be of C<blocksize()> bytes.
(hint:  Camellia is an 16 byte block cipher)

=item decrypt

  my $plaintext = $cipher-E<gt>decrypt($ciphertext);

This function decrypts $ciphertext and returns the $plaintext
where $plaintext and $ciphertext must be of C<blocksize()> bytes.
(hint:  see previous hint)

=back

=head1 EXAMPLE

  my $key = pack("H16", "0123456789ABCDEF");  # min. 8 bytes
  my $cipher = Crypt::Camellia->new($key);
  my $ciphertext = $cipher->encrypt("plaintex");# SEE NOTES 
  print unpack("H16", $ciphertext), "\n";

=head1 NOTES

For practical uses use this module via L<Crypt::CBC> rather than directly. 

=head1 SEE ALSO

L<Crypt::CBC>,
L<Crypt::Rijndael>,
L<Crypt::DES>,
L<Crypt::IDEA>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

Current maintainer is Hiroyuki OYAMA E<lt>oyama@module.jpE<gt>.

And 

NTT  L<http://info.isl.ntt.co.jp/crypt/camellia/index.html>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

Except for anything under camellia/ directory which is licensed as follows:

 Copyright (c) 2006
  NTT (Nippon Telegraph and Telephone Corporation) . All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer as
    the first lines of this file unmodified.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY NTT ``AS IS'' AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL NTT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
