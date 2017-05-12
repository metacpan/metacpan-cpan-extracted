# $Id: GOST.pm,v 1.00 2001/05/13 14:11:35 ams Exp $
# Copyright 2001 Abhijit Menon-Sen <ams@wiw.org>

package Crypt::GOST;

use strict;
use Carp;
use DynaLoader;
use vars qw( @ISA $VERSION );

@ISA = qw( DynaLoader );
($VERSION) = q$Revision: 1.00 $ =~ /([\d.]+)/;

bootstrap Crypt::GOST $VERSION;

sub keysize   () { 32 }
sub blocksize () {  8 }

sub new
{
    my ($class, $key) = @_;

    # Sacrifice error reporting for backwards compatibility.
    # croak "Usage: ".__PACKAGE__."->new(\$key)" unless $key;
    return Crypt::GOST::old(@_) unless $key;
    return Crypt::GOST::setup($key);
}

sub encrypt
{
    my ($self, $data) = @_;

    croak "Usage: \$cipher->encrypt(\$data)" unless ref($self) && $data;
    $self->crypt($data, $data, 0);
}

sub decrypt
{
    my ($self, $data) = @_;

    croak "Usage: \$cipher->decrypt(\$data)" unless ref($self) && $data;
    $self->crypt($data, $data, 1);
}

# The functions below are retained only for backwards compatibility with
# Crypt::GOST 0.41. Please use the documented interface instead.
#
#       my $gost = new Crypt::Gost;
#       $gost->generate_sbox ($passphrase);
#       $gost->generate_keys ($passphrase);
#       $ciphertext = $gost->SScrypt($plaintext);
#       $plaintext  = $gost->SSdecrypt($ciphertext);

sub _rand { return int (((shift) / 100) * ((rand) * 100)); }

sub _longint
{
    my ($string, $pos) = @_;
    return unpack "L", pack "a4", substr $string, $pos, $pos+4;
}

sub _sub
{
    my $x = 0;
    my ($self, $d) = @_;

    $x |= ($self->{SBOX}[$_][$d>>($_*4)&15]<<($_*4)) for reverse (0..7);
    return $x << 11 | $x >> (32 - 11);
}

sub old
{
    my $class = shift;
    my $self  = { KEY => [], SBOX => [] };
    return bless $self, ref($class) || $class;
}

sub generate_sbox
{
    my ($self, $passphrase) = @_;
    croak "Usage: \$gost->generate_sbox(\$passphrase)"
        unless ref $self && defined $passphrase;

    if (ref $passphrase) {
        @{$self->{SBOX}} = @$passphrase;
    } else {
        my @temp = (0..15);
        my ($i, $x, $y, $random, @tmp) = 0;

        for ($i = 0; $i <= length $passphrase; $i += 4) {
            $random = $random ^ _longint($passphrase, $i);
        }
        srand $random;

        for ($i = 0; $i < 8; $i++) {
            @tmp = @temp;
            for (0..15) {
                $x = _rand(15);
                $y = $tmp[$x]; $tmp[$x] = $tmp[$_]; $tmp[$_] = $y;
            }
            @{$self->{SBOX}}->[$i][$_] = $tmp[$_] for (0..15);
        }
    }
} 

sub generate_keys
{
    my ($self, $passphrase) = @_;
    croak "Usage: \$gost->generate_keys(\$passphrase)"
        unless ref $self && defined $passphrase;

    if (ref $passphrase) {
        @{$self->{KEY}} = @$passphrase;
    } else {
        my ($i, $random) = 0;

        for ($i = 0; $i <= length $passphrase; $i += 4) {
            $random = $random ^ _longint($passphrase, $i);
        }
        srand $random;

        @{$self->{KEY}}[$_] = _rand (2**32) for (0..7);
    }
} 

sub SScrypt {
    my ($self, $data, $decrypt) = @_;
    my ($i, $j, $d1, $d2, $text) = 0;

    croak "Usage: \$gost->SScrypt(\$data)" unless ref $self && defined $data;

    for ($i = 0; $i < length $data; $i += 8) {
        $j = 0;
        $d1 = _longint($data, $i);
        $d2 = _longint($data, $i+4);

        for (1..32) {
            $j = ($_%8) - 1; $j = 7 if $j == -1;
            if ($decrypt) { $j = (32-$_)%8 if $_ >=  9; }
            else          { $j =  32-$_    if $_ >= 25; }

            if ($_%2 == 1) { $d2 ^= $self->_sub($d1 + $self->{KEY}[$j]) }
            else           { $d1 ^= $self->_sub($d2 + $self->{KEY}[$j]) }
        }

        $text .= pack "L2", $d2, $d1;
    }
    return $text;
}

sub SSdecrypt {
    my ($self, $data) = @_;
    croak "Usage: \$gost->SSdecrypt(\$data)" unless ref $self && defined $data;

    $self->SScrypt($data, 1);
}

1;

__END__

=head1 NAME

Crypt::GOST - The GOST Encryption Algorithm

=head1 SYNOPSIS

use Crypt::GOST;

$cipher = Crypt::GOST->new($key);

$ciphertext = $cipher->encrypt($plaintext);

$plaintext  = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

GOST 28147-89 is a 64-bit symmetric block cipher with a 256-bit key
developed in the former Soviet Union. Some information on it is
available at <URL:http://vipul.net/gost/>.

This module implements GOST encryption. It supports the Crypt::CBC
interface, with the functions described below. It also provides an
interface that is backwards-compatible with Crypt::GOST 0.41, but its
use in new code is discouraged.

=head2 Functions

=over

=item blocksize

Returns the size (in bytes) of the block (8, in this case).

=item keysize

Returns the size (in bytes) of the key (32, in this case).

=item new($key)

This creates a new Crypt::GOST object with the specified key.

=item encrypt($data)

Encrypts blocksize() bytes of $data and returns the corresponding
ciphertext.

=item decrypt($data)

Decrypts blocksize() bytes of $data and returns the corresponding
plaintext.

=back

=head1 SEE ALSO

Crypt::CBC, Crypt::Twofish, Crypt::TEA

=head1 ACKNOWLEDGEMENTS

=over 4

=item Vipul Ved Prakash

For writing Crypt::GOST 0.41, and reviewing the current version.

=back

=head1 AUTHOR

Abhijit Menon-Sen <ams@wiw.org>

Copyright 2001 Abhijit Menon-Sen. All rights reserved.

This software is distributed under the terms of the Artistic License
<URL:http://ams.wiw.org/code/artistic.txt>.
