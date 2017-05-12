use strict;
use warnings;

package Crypt::MCrypt;

# PODNAME: Crypt::MCrypt
# ABSTRACT: Perl interface for libmcrypt C library.
#
# This file is part of Crypt-MCrypt
#
# This software is copyright (c) 2013 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.07'; # VERSION

use 5.010;

# Dependencies
use Mo;
use Carp;

require XSLoader;
XSLoader::load( 'Crypt::MCrypt', $VERSION );


has algorithm => ();


has mode => ();


has key => ();


has iv => ();


sub decrypt {
    my ( $self, $ciphertext ) = @_;

    my $length = length($ciphertext);
    my $plain_hex =
      Crypt::MCrypt::_decrypt( $self->algorithm, $self->mode, $ciphertext,
        $self->key, $length, $self->iv );
    return pack( "H*", $plain_hex );
}


sub encrypt {
    my ( $self, $plaintext ) = @_;

    my $length = length($plaintext);
    my $cipher_hex =
      Crypt::MCrypt::_encrypt( $self->algorithm, $self->mode, $plaintext,
        $self->key, $length, $self->iv );
    return pack( "H*", $cipher_hex );
}

1;

__END__

=pod

=head1 NAME

Crypt::MCrypt - Perl interface for libmcrypt C library.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

     use Crypt::MCrypt;
 
     my $iv = pack("H*","0000000000000000");
     my $key = pack("H*","1234567890123456" . "7890123456789012" . "1234567890123456");
     my $cipher_text = pack("H*","E9FF3161EE05ABC9" 
         . "7ea3cacb991318aa" 
         . "585379599b0eaabb" 
         . "c4e474ead1956f47" 
         . "6755f13f1af5235d");
     my $algorithm = "tripledes";
     my $mode = "cbc";
     my $obj = Crypt::MCrypt->new(
         algorithm => $algorithm, 
         mode      => $mode,
         key       => $key, 
         iv        => $iv,
     );
     my $plain_text = $obj->decrypt($cipher_text);
     print "\nPLAIN: $plain_text\n";
     print "\nPLAIN in hex: " . unpack("H*",$plain_text) . "\n";
     $cipher_text = $obj->encrypt($plain_text);
     print "\nCIPHER: $cipher_text\n";
     print "\nCIPHER in hex: " . unpack("H*",$cipher_text) . "\n";

=head1 DESCRIPTION

This is a perl interface to libmcrypt c library. It exposes the crypto functions provided by the libmcrypt library in a perl interface 
with a binding code that accounts for null C strings in ciphertext or plain text.

=head1 ATTRIBUTES

=head2 algorithm

contains the name of the algorithm used to decrypt encrypt blocks of data

=head2 mode 

contains the name of the L<block cipher mode of operation|http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation> used to encrypt/decrypt blocks of data.

=head2 key

contains the key for the encryption decryption algorithm

=head2 Initialization Vector 

contains the Initialization for the first block of data in block cipher mode of operation. 

=head1 METHODS

=head2 $self->decrypt($ciphertext)

decrypt blocks of ciphertext 

=head2 $self->encrypt($ciphertext)

encrypt blocks of data

=encoding utf-8

=head1 USAGE

=over

=item *

This module provides a object oriented interface to the libmcrypt library. It uses Mo, a scaled down version of Moose without any data checks to improve speed.

=back

=head1 see ALSO

=over

=item *

L<Mo>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/crypt-mcrypt/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/crypt-mcrypt>

  git clone git://github.com/shantanubhadoria/crypt-mcrypt.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 CONTRIBUTORS

=over 4

=item *

Shantanu <shantanu@cpan.org>

=item *

Shantanu Bhadoria <shantanu@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
