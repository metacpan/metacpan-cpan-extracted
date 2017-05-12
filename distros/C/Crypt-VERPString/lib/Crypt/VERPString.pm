package Crypt::VERPString;

use warnings FATAL => 'all';
use strict;

use Carp         qw(croak);
#use MIME::Base32 qw(rfc);
use MIME::Base32 qw(crockford);
use Crypt::CBC   ();

=head1 NAME

Crypt::VERPString - Encrypt and encode fixed-length records for VERP

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Crypt::VERPString;
    use MIME::Base64;

    my $cv = Crypt::VERPString->new(
        cipher      => 'IDEA',                       # defaults to blowfish
        key         => 'HAHGLUBHAL!@#$!%',           # anything, really
        format      => 'Na*',                        # defaults to a*
        separator   => '!',                          # defaults to -
        encoder     => \&MIME::Base64::encode_base64,# defaults to base32
        decoder     => \&MIME::Base64::decode_base64,# ditto
    );

    my $iv      = 31337;
    my $verp    = $cv->encrypt($iv, 12345, 'hi i am a payload');

    # $verp eq '00007a69!+BT8d1wzW12YSFP5v7AnKVipYZ8rkQIT';

    # do stuff with this value, send to a friend...

    # oops, your friend doesn't exist, the message bounces and you 
    # retrieve the envelope.

    my ($bouncedverp) = ($header =~ /(?:[0-9a-fA-F]{8}!.*)/);

    my ($number, $string) = $cv->decrypt($bouncedverp);

    # now you can do something with this info.

=head1 DESCRIPTION

VERP stands for Variable Envelope Return Path. It is the act of inserting
some sort of identifying string into the local part of the envelope
address of an email, in order to match it to a distinct sending, should
the message bounce. This module prepares a string suitable for travel
in the deep jungle of SMTP, making it possible to store and retrieve
unique envelope data from a bounced message.

This module is also useful for other small payloads that require the
same kind of escaping.

=head1 METHODS

=head2 new PARAMS

=over 1

=item cipher

The block cipher to use. Defaults to Blowfish.

=item key

The secret key.

=item format

The pack() format. Defaults to "a*". 

=item separator

The separation character between the initialization vector and the payload.
Defaults to "-".

=item encoder

A Subroutine reference to encode the payload. Defaults to MIME::Base32::encode

=item decoder

A Subroutine reference to decode the payload. Defaults to MIME::Base32::decode

=back

=cut

sub new {
    # mwa ha ha.
    my $class = shift;
    my $self  = bless {map {lc($_[$_])=>$_[$_+1]} map {$_*2} (0..@_/2)}, $class;
    $self->{cipher} ||= 'Blowfish';
    # how i weep for no // operator
    #defined $self->{iv} && $self->{iv} =~ /^\d+$/ or croak 'IV not a number';
    defined $self->{key}       or croak 'Key must be defined';
    defined $self->{format}    or $self->{format}    = 'a*';
    defined $self->{separator} or $self->{separator} = '-';
    defined $self->{encoder}   or $self->{encoder}   = \&MIME::Base32::encode;
    defined $self->{decoder}   or $self->{decoder}   = \&MIME::Base32::decode;
    $self;
}

sub _get_cipher {
    my ($self, $iv) = @_;
    Crypt::CBC->new({
        key             => $self->{key},
        cipher          => $self->{cipher},
        iv              => pack('NN', $iv, 0), # we could use more entropy...
        regenerate_key  => 0,
        prepend_iv      => 0,
    });
}

#=head2 set_iv NUMBER

#Set a new initialization vector. Returns old initialization vector.

#=cut

#sub set_iv {
#    my ($self, $iv) = @_;
#    croak 'IV not a number' unless $iv =~ /^\d+$/;
#    my $oldiv = $self->{iv};
#    $self->{iv} = $iv;
#    $self->{crypto}->set_initialization_vector(pack 'NN', ($self->{iv}));
#    $oldiv;
#}

=head2 encrypt IV, LIST

Pass in the list and retrieve the unique, encrypted VERP string.

=cut

sub encrypt {
    my ($self, $iv, @args) = @_;
    my $cv = $self->_get_cipher($iv);
    return join $self->{separator}, unpack('H*', pack 'N', $iv), 
    $self->{encoder}->($cv->encrypt(pack $self->{format}, @args));
}

=head2 decrypt STRING

Pass in the VERP string and retrieve the original unencrypted list.

=cut

sub decrypt {
    my ($self, $str)   = @_;
    my ($iv, $payload) = ($str =~ /^([0-9a-fA-F]{8})$self->{separator}(.*)/o);
    croak 'Malformed input string' unless $iv and $payload;
    $iv = unpack("N", pack "H*", $iv);
    my $cv = $self->_get_cipher($iv);
    my $ciphertext = eval { $self->{decoder}->($payload) };
    croak 'Could not decode payload using supplied decode sub' 
        if $@ or !$ciphertext;
    my @payload = unpack $self->{format}, $cv->decrypt($ciphertext);
    return wantarray ? @payload : $payload[0];
}

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 SEE ALSO

L<Crypt::CBC>

L<MIME::Base32>

L<http://cr.yp.to/proto/verp.txt>

=head1 BUGS

The true IV is just the given number and zero, packed into two network longs. 
I wouldn't recommend really using this for extremely sensitive data, I mean,
it's initially designed to fit in the local-part of an email. Ideas and
patches are welcome.

Please report any bugs or feature requests to
C<bug-crypt-verpstring@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 iCrystal Software, Inc., All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Crypt::VERPString
