#!/usr/bin/perl

=head1 NAME

Crypt::OTP26 - a classic form of encryption

=head1 DESCRIPTION

This implements a mod-26 One Time Pad encryption, similar to the sort
classically used with pen and paper, as described in
L<http://en.wikipedia.org/wiki/One_time_pad>

Its primary use is to explore the intriguing situation detailed
at L<http://itre.cis.upenn.edu/~myl/languagelog/archives/003314.html>

NB: We don't handle the cases of generating or securely transmitting the pads
themselves.  

Also, only lower case alpha (ascii 'a-z') characters are handled.  
If you are actually encrypting and transmitting useful and valuable data, you
should use a proper strong crypto module.

And though it's based on the OneTimePad concept, it actually supports the pad
being shorter or longer than the encrypted text, in which case it is truncated
or repeated as appropriate.  So... don't do that!

=cut

package Crypt::OTP26;

use strict; use warnings;
use Data::Dumper;

our $VERSION = 0.03;
use constant ORD_A => ord('a');

=head1 METHODS

=head2 C<new>

    my $otp = Crypt::OTP26->new();

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 C<crypt>

Encrypts an alpha text (a-z) with an alpha pad (a-z), by
performing mod26 addition on it.

    my $encrypted = $otp->crypt( $pad, $text ); 
        # though it's commutative, so can be in either order 

    my $encrypted = $otp->crypt( 'aced', 'scam' ); 
        # returns 'seep'

=cut

sub crypt {
    my ($self, $string1, $string2) = @_;

    my $stream = $self->mk_stream( $string1, $string2 );

    my $new_string = '';
    
    while (my ($char1, $char2) = $stream->()) {
        $new_string .= $self->crypt_char( $char1, $char2 );
    }
    return $new_string;
}

=head2 C<decrypt>

Decrpyts a previously encrypted text using mod26 sutraction.

    my $encrypted = $otp->decrypt( $crypt, $pad );
    my $encrypted = $otp->decrypt( 'aced', 'seep' ); 
        # returns 'scam'

=cut

sub decrypt {
    my ($self, $string1, $string2) = @_;

    my $stream = $self->mk_stream( $string1, $string2 );

    my $new_string = '';
    
    while (my ($char1, $char2) = $stream->()) {
        $new_string .= $self->decrypt_char( $char2, $char1 );
    }
    return $new_string;
}

=head2 C<char2int>

Return the mod26 integer value of an ascii character.

    my $int = $otp->char2int('a'); 
        # returns 0

=cut

sub char2int {
    my $self = shift;
    my $char = shift;
    return ord(lc $char) - ORD_A;
}

=head2 C<int2char>

    my $char = $otp->int2char( 1 ); 
        # returns 'b'

Will always return 'a'-'z'

=cut

sub int2char {
    my $self = shift;
    my $int = shift;
    return chr( ORD_A + ($int % 26));
}

=head2 C<crypt_char>

    my $char = $otp->crypt_char( 'a', 's' ); 
        # returns 's'

Crypts 2 characters by performing mod26 addition on them.  Called internally by
L<crypt> above.

=cut
    
sub crypt_char {
    my ($self, $char1, $char2) = @_;
    my $int1 = $self->char2int( $char1 );
    my $int2 = $self->char2int( $char2 );
    my $int3 = $int1 + $int2;
    return $self->int2char( $int3 );
}

=head2 C<decrypt_char>

Decrypts the character with the appropriate letter from the pad, by performing
mod26 subtraction.  Called internally L<decrypt> above.

    my $char = $otp->decrypt_char( $crypt_char, $pad_char );
    my $char = $otp->decrypt_char( 't', 's' ); 
        # returns 'b'

=cut

sub decrypt_char {
    my ($self, $crypt_char, $pad_char) = @_;
    my $int1 = $self->char2int( $crypt_char );
    my $int2 = $self->char2int( $pad_char );
    my $int3 = $int1 - $int2;
    return $self->int2char( $int3 );
}

=head2 C<mk_stream>

Private method for iterating the pad and the string.

=cut

sub mk_stream {
    my $self = shift;
    my ($string1, $string2) = @_;

    # $string1 is the pad, and will repeat if necessary

    my @stream1 = split '', $string1;
    my @stream2 = split '', $string2;

    return sub {
        return unless @stream2;
        @stream1 = split '', $string1 unless @stream1;
        my $char1 = splice(@stream1, 0, 1);
        my $char2 = splice(@stream2, 0, 1);
        return ($char1, $char2);
    }    
}

=head1 AUTHOR

    (C) 2009
    osfameron@cpan.org

    May be distributed under the same conditions as Perl itself

Repo is at L<http://github.com/osfameron/crypt-otp26/> 

(Clone url: git://github.com/osfameron/crypt-otp26.git )

=cut

1;

