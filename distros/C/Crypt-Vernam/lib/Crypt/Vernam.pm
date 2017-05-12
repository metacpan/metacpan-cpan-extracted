#------------------------------------------------#
# Vernam.pm - (C)opyright 2008 by Manuel Gebele
#             <forensixs[at]gmx[dot]de>, Germany.
#------------------------------------------------#

#------------------------------------------------#
package Crypt::Vernam;
#------------------------------------------------#

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
    vernam_encrypt
    vernam_decrypt
);

our $VERSION = '0.03';

#-------------------- Globals -------------------#

my %alpha_pos_of = (
    A =>  0, N => 13,
    B =>  1, O => 14,
    C =>  2, P => 15,
    D =>  3, Q => 16,
    E =>  4, R => 17,
    F =>  5, S => 18,
    G =>  6, T => 19,
    H =>  7, U => 20,
    I =>  8, V => 21,
    J =>  9, W => 22,
    K => 10, X => 23,
    L => 11, Y => 24,
    M => 12, Z => 25,
);

my @alpha = sort keys %alpha_pos_of;

#--------------- Private methods ----------------#

## Generates a pseudo random key for mod26 mode.
sub _get_key_mod26 {
    my $length = shift;
    my $key;

    $key .= $alpha[int rand 26] for 1..$length;

    return $key;
}

## Shift positions and get character at new position.
sub _shift_char {
    my ($char, $key_char, $action) = @_;

    my $pos1 = $alpha_pos_of{uc $char};
    my $pos2 = $alpha_pos_of{uc $key_char};

    # Handle non-alpha characters...
    return $char unless defined $pos1;
    
    my $new_char = $action eq 'encrypt'
                 ?
        $alpha[($pos1 + $pos2) % 26]
                 :
        $alpha[($pos1 - $pos2) % 26]
                 ;

    # Handle lower-case letters...
    if ($char =~ /[a-z]/) {
        return lc $new_char;
    }

    return $new_char;
}

## Encrypt/Decrypt @data using mod26 mode.
sub _vernam_mod26 {
    my @data   = split //, shift;
    my @key    = split //, shift;
    my $action =           shift;
    my $ind    = 0;
    my $retval;

    for my $char (@data) {
        $retval .= 
            _shift_char(
                $char,      # plain/cipher char
                $key[$ind], # key char
                $action
            );

        $ind++;
    }

    return $retval;
}

## Generates a pseudo random key for xor mode.
sub _get_key_xor {
    my $length = shift;
    my $key;

    $key .= chr rand 256 for 1..$length;

    return $key;
}

## Encrypt/Decrypt @data using xor mode.
sub _vernam_xor {
    my ($data, $key) = @_;
    my $retval;

    $retval = $data ^ $key;

    return $retval;
}

## Help function for vernam_encrypt and vernam_decrypt
sub _check_args {
    my ($mode, $data, $key) = @_;
    my $length              = length $data;

    croak "Illegal encryption/decryption mode"
        if $mode !~ /mod26|xor/i;
    croak "Missing plain/ciphertext string"
        if !defined $data;
    croak "Empty plain/ciphertext string"
        if $length <= 0;

    return ($mode, $data) 
        if (caller(1))[3] !~ /decrypt$/;
 
    # Only required for vernam_decrypt...
    croak "Missing decryption key" 
        if !defined $key;
    
    my $klength = length $key;
    
    croak "The encryption key must have the "
        . "same length as the ciphertext string"
        if $length != $klength;

    if ($mode =~ /mod26/i) {
        for (split //, $key) {
            croak "Invalid mod26 key"
                if !/[a-z]/i;
        }
    }
   
    return ($mode, $data, $key);
}

#---------------- Public methods ----------------#

sub vernam_encrypt {
    my ($mode, $plaintext) = _check_args(@_);
    my ($ciphertext, $key);

    my $length = length $plaintext;

    $key = $mode =~ /mod26/i
         ?
        _get_key_mod26($length)
         :
        _get_key_xor($length)
         ;

    $ciphertext = $mode =~ /mod26/i
                ?
        _vernam_mod26($plaintext, $key, 'encrypt')
                :
        _vernam_xor($plaintext, $key)
                ;

    return ($ciphertext, $key);
}

sub vernam_decrypt {
    my ($mode, $ciphertext, $key) = _check_args(@_);
    my $plaintext;

    $plaintext = $mode =~ /mod26/i
               ?
        _vernam_mod26($ciphertext, $key, 'decrypt')
               :
        _vernam_xor($ciphertext, $key)
               ;

    return $plaintext;
}

1;

=head1 NAME

Crypt::Vernam - Perl implementation of the Vernam cipher

=head1 SYNOPSIS

  use Crypt::Vernam;

  # mod26 mode
  my ($ciphertext, $key) = vernam_encrypt('mod26', 'Vernam');
  my $plaintext = vernam_decrypt('mod26', $ciphertext, $key);

  # xor mode
  ($ciphertext, $key) = vernam_encrypt('xor', 'Vernam');
  $plaintext = vernam_decrypt('xor', $ciphertext, $key);

=head1 DESCRIPTION

The Crypt::Vernam module allows you to do a simple but robust
encryption/decryption, with the algorithm of Gilbert Sandford, Vernam.
This kind of encryption is truly unbreakable as long the key is
maintained a secret.

See the README file that came with the Crypt::Vigenere package for
more information.

=head2 Public methods

=over

=item B<vernam_encrypt($mode, $plaintext)>

The C<vernam_encrypt> method is called to encrypt the $plaintext 
string, using $mode (mod26 or xor).

=item B<vernam_decrypt($mode, $ciphertext, $key)>

The C<vernam_decrypt> method is called to decrypt the $ciphertext
string, using $mode (mod26 or xor) and decryption key $key.

=back

=head1 EXPORT

B<vernam_encrypt>
B<vernam_decrypt>

=head1 AUTHOR

Manuel Gebele, E<lt>forensixs[at]gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Manuel Gebele.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
