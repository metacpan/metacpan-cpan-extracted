#!/usr/bin/perl
package Authen::OATH::OCRA;
use warnings;
use strict;
use Math::BigInt;
use Moose;
use Carp;
use Digest::SHA qw(hmac_sha1 hmac_sha256 hmac_sha512);

has 'ocrasuite' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'key' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'counter' => (
    'is'  => 'rw',
    'isa' => 'Int'
);

has 'question' => (
    'is'  => 'rw',
    'isa' => 'Str'
);

has 'password' => (
    'is'  => 'rw',
    'isa' => 'Str'
);

has 'session_information' => (
    'is'  => 'rw',
    'isa' => 'Str'
);

has 'timestamp' => (
    'is'  => 'rw',
    'isa' => 'Int'
);

=head1 NAME

OCRA - OATH Challenge-Response Algorithm

=head1 VERSION

Version 1.01

=cut

our $VERSION = "1.01";

=head1 SYNOPSIS

    use Authen::OATH::OCRA;
    my $key = '7110eda4d09e062aa5e4a390b0a572ac0d2c0220';
    my $question = 'This is the challenge';
    my $ocrasuite = 'OCRA-1:HOTP-SHA1-6:QA32';
    my $ocra = Authen::OATH::OCRA->new(     
                                 ocrasuite => $ocrasuite,
                                 key       => $key,   # key must be hex encoded
                                 question  => $question   
                                );
    my $otp = $ocra->ocra();

Parameters may be set after object instantiation using accesor methods before the ocra() method is called

    use Authen::OATH::OCRA;
    my $ocra = Authen::OATH::OCRA->new();
    $ocra->ocrasuite('OCRA-1:HOTP-SHA512-6:C-QA32-PSHA1-S20-T1M');
    $ocra->key('7110eda4d09e062aa5e4a390b0a572ac0d2c0220');
    $ocra->counter(77777777);
    $ocra->question("I bet you can't");
    $ocra->password('f7c3bc1d808e04732adf679965ccc34ca7ae3441');
    $ocra->session_information('Some session info');
    $ocra->timestamp(1234567890);
    my $otp = $ocra->ocra();

=head1 Description

Implementation of the OATH Challenge-Response authentication algorithm 
as defined by The Initiative for Open Authentication OATH (http://www.openauthentication.org)
in RFC 6287 (http://tools.ietf.org/html/rfc6287)



=head1 PARAMETERS

Minimum required parameters are: ocrasuite, key and question.
Aditional parameters (counter, password or session_information) may be required depending on the specified ocrasuite.

Accesor methods are provided for each parameter

=head2 ocrasuite

Text string that specifies the operation mode for OCRA. For further information see http://tools.ietf.org/html/rfc6287#section-6 

=head2 key

Text string with the shared secret key known to both parties, must be in hexadecimal format

=head2 counter

An unsigned integer value, must be sinchronized between both parties

=head2 question

Text string with the challenge question

=head2 password

Text string with the hash (SHA-1 , SHA-256 and SHA-512 are supported) value of PIN/password that is known to both parties, must be in hexadecimal format

=head2 session_information

Text string that contains information about the current session, must be UTF-8 encoded

=head2 timestamp

Defaults to system time if required by the OCRA Suite and not provided, use only if you need to set the time manually. An unsigned integer value representing the manual Unix Time in the granularity specified in the OCRA Suite

=head1 SUBROUTINES/METHODS

=head2 ocra

Returns a text string with the One Time Password for the provided parameters

    my $otp = $ocra->ocra();

ocra()  passed all the test vectors contained in the RFC document.
=cut

sub ocra {
    my ($self) = @_;

    #Validate that min required parameters are present
    croak "Parameter \"ocrasuite\" is required"
        unless defined( $self->{ocrasuite} );
    croak "Parameter \"question\" is required"
        unless defined( $self->{question} );
    croak "Parameter \"key\" is required" unless defined( $self->{key} );

    #Validate the OCRA Suite format and parse sub parameters into variables
    croak "Invalid ocrasuite"
        unless $self->{ocrasuite} =~ /^
                                      OCRA-1:HOTP-SHA
                                      (1|256|512)-
                                      (\d+):
                                      (C-)?Q
                                      (A|N|H)\d+
                                      (-PSHA(1|256|512))?
                                      (-S(\d+))?
                                      (-T(\d+)(S|H|M))?
                                      $
                                      /x;
    my $sha             = $1;
    my $digits          = $2;
    my $has_counter     = $3;
    my $question_format = $4;
    my $has_password    = $5;
    my $password_format = $6;
    my $has_session     = $7;
    my $session_size    = $8;
    my $has_timestamp   = $9;
    my $period          = $10;
    my $time_unit       = $11;

    #Validate parameters included in the OCRA Suite
    croak "Must request at least 4 digits" if $digits < 4;
    croak "Must request at most 10 digits" if $digits > 10;

    #Validate if additional parameters required
    #in the provided OCRA Suite are present
    croak "Parameter \"counter\" is required for the provided ocrasuite"
        if $has_counter && !defined( $self->{counter} );
    croak "Parameter \"password\" is required for the provided ocrasuite"
        if $has_password && !defined( $self->{password} );
    croak
        "Parameter \"session_information\" is required for the provided ocrasuite"
        if $has_session && !defined( $self->{session_information} );

    #Initiate the data input with the Ocra Suite and the separator byte
    my $datainput = $self->ocrasuite . "\0";

    #Concatenate encoded Counter padded with 8 zeros at left
    $datainput .= _hex_to_bytes( _dec_to_hex( $self->counter ), 8 )
        if $has_counter;

    #Encode the Question on the specified format
    my $question;
    $question = _str_to_hex( $self->question ) if $question_format eq 'A';
    $question = _dec_to_hex( $self->question ) if $question_format eq 'N';
    $question = _check_hex( $self->question )  if $question_format eq 'H';

    #Concatenate encoded Question padded with 128 zeros at right
    $datainput .= pack( "H*",
        _check_hex($question)
            . "\0" x ( 256 - length( _check_hex($question) ) ) );

    #Concatenate encoded password and  pad with zeros 
    #to the left depending on the specified SHA
    my %password_size = ( 1 => 20, 256 => 32, 512 => 64 );
    $datainput
        .= _hex_to_bytes( $self->password, $password_size{$password_format} )
        if $has_password;

    #Concatenate encoded Session Information padded with zeros at left
    $datainput .= _hex_to_bytes( _str_to_hex( $self->session_information ),
        $session_size )
        if $has_session;

    #Assign timestamp value
    if ($has_timestamp) {
        my $timestamp;
        if ( $self->{timestamp} ) {

            #use provided timestamp
            $timestamp = $self->timestamp;
        }
        else {

            #if timestamp is not provided, query the system
            #time and calculate according to provided parameters
            my %timestep = ( S => 1, M => 60, H => 3600 );
            $timestamp = int( time() / ( $period * $timestep{$time_unit} ) );
        }

        #Concatenate encoded timestamp padded with 8 zeros at left
        $datainput .= _hex_to_bytes( _dec_to_hex($timestamp), 8 );
    }

    #Encode the Key
    my $key = pack( 'H*', _check_hex( $self->key ) );

    #Compute the HMAC
    my $hash;
    {
        no strict 'refs';
        $hash = &{"hmac_sha$sha"}( $datainput, $key );
    }

    #Dynamic Truncation
    my $offset = hex substr unpack( "H*", $hash ), -1;
    my $dt = unpack "N" => substr $hash, $offset, 4;
    $dt &= 0x7fffffff;
    $dt = Math::BigInt->new($dt);
    my $modulus = 10**$digits;

    #Compute the HOTP value
    return sprintf( "%0${digits}d", $dt->bmod($modulus) );

}

#Private method, encodes a string in hexadecimal format
sub _str_to_hex {
    my ($str) = @_;
    return unpack( 'H*', $str );

}

#Private method, encodes a decimal in hexadecimal format
sub _dec_to_hex {
    my ($dec) = @_;
    my $big_int = Math::BigInt->new($dec);
    return _check_hex( $big_int->as_hex() );
}

#Private method, validates hexadecimal format, removes sign and preceding  0x or x
sub _check_hex {
    my ($num) = @_;

    if ($num =~ s/
                     ^
                     ( [+-]? )
                     (0?x)?
                     (
                         [0-9a-fA-F]*
                         ( _ [0-9a-fA-F]+ )*
                     )
                     $
                 //x
        )
    {

        return $3;
    }
    else { croak "$num: not in hex format"; }

}

#private method, encodes hexadecimal to binary, pads with zeros at left
sub _hex_to_bytes {
    my ( $hex, $pad ) = @_;
    $hex = _check_hex($hex);
    my $length = length($hex);

    return pack( 'H*', "\0" x ( ( $pad * 2 ) - $length ) . $hex );

}

=head1 AUTHOR

Pascual De Ruvo, C<< <pderuvo at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authen-oath-ocra at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-OATH-OCRA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::OATH::OCRA


You can also look for information at:

=over 4

=item * OATH: Initiative for Open Authentication

L<http://www.openauthentication.org>

=item * OCRA: OATH Challenge-Response Algorithm RFC

L<http://tools.ietf.org/html/rfc6287>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-OATH-OCRA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-OATH-OCRA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-OATH-OCRA>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-OATH-OCRA/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Pascual De Ruvo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Authen::OATH::OCRA

################################################################################
# EOF
