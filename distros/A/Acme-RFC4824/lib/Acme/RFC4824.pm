package Acme::RFC4824;

use warnings;
use strict;

use Moose;
use Carp;
use bytes;

our $VERSION = '0.02';

# a hash ref of mappings from ASCII to ASCII art representations
has 'ascii2art_map'     => (
    is => 'ro',
);

# the default SFS frame size in bytes
has 'default_framesize' => (
    is      => 'ro',
    isa     => 'Int',
    default => 255,
);

sub BUILD {
    my $self    = shift;
    my $arg_ref = shift;

    if (exists $arg_ref->{'DEFAULT_FRAMESIZE'}) {
        if ($arg_ref->{'DEFAULT_FRAMESIZE'} > 255) {
            croak "Frame size too large, can at most be 255";
        }
        $self->{'default_framesize'} = $arg_ref->{'DEFAULT_FRAMESIZE'};
    }
    # initialize mapping from characters to ASCII art
    # ASCII-Art comes directly from RFC4824
    $self->{'ascii2art_map'}->{'A'} = << 'XEOF';
 0 
/||
/ \
XEOF
    $self->{'ascii2art_map'}->{'B'} = << 'XEOF';
__0 
  ||
 / \
XEOF
    $self->{'ascii2art_map'}->{'C'} = << 'XEOF';
\0 
 ||
/ \
XEOF
    $self->{'ascii2art_map'}->{'D'} = << 'XEOF';
|0 
 ||
/ \
XEOF
    $self->{'ascii2art_map'}->{'E'} = << 'XEOF';
 0/
||
/ \
XEOF
    $self->{'ascii2art_map'}->{'F'} = << 'XEOF';
 0__
||
/ \
XEOF
    $self->{'ascii2art_map'}->{'G'} = << 'XEOF';
 0 
||\
/ \
XEOF
    $self->{'ascii2art_map'}->{'H'} = << 'XEOF';
__0 
 /| 
 / \
XEOF
    $self->{'ascii2art_map'}->{'I'} = << 'XEOF';
\0 
/| 
/ \
XEOF
    $self->{'ascii2art_map'}->{'J'} = << 'XEOF';
|0__
 | 
/ \
XEOF
    $self->{'ascii2art_map'}->{'K'} = << 'XEOF';
 0|
/| 
/ \
XEOF
    $self->{'ascii2art_map'}->{'L'} = << 'XEOF';
 0/
/| 
/ \
XEOF
    $self->{'ascii2art_map'}->{'M'} = << 'XEOF';
 0__
/| 
/ \
XEOF
    $self->{'ascii2art_map'}->{'N'} = << 'XEOF';
 0 
/|\
/ \
XEOF
    $self->{'ascii2art_map'}->{'O'} = << 'XEOF';
_\0 
  | 
 / \
XEOF
    $self->{'ascii2art_map'}->{'P'} = << 'XEOF';
__0|
  | 
 / \
XEOF
    $self->{'ascii2art_map'}->{'Q'} = << 'XEOF';
__0/
  | 
 / \
XEOF
    $self->{'ascii2art_map'}->{'R'} = << 'XEOF';
__0__
  | 
 / \
XEOF
    $self->{'ascii2art_map'}->{'S'} = << 'XEOF';
__0 
  |\
 / \
XEOF
    $self->{'ascii2art_map'}->{'T'} = << 'XEOF';
\0|
 | 
/ \
XEOF
    $self->{'ascii2art_map'}->{'U'} = << 'XEOF';
\0/
 | 
/ \
XEOF
    $self->{'ascii2art_map'}->{'V'} = << 'XEOF';
|0 
 |\
/ \
XEOF
    $self->{'ascii2art_map'}->{'W'} = << 'XEOF';
 0/_
 | 
/ \
XEOF
    $self->{'ascii2art_map'}->{'X'} = << 'XEOF';
 0/
 |\
/ \
XEOF
    $self->{'ascii2art_map'}->{'Y'} = << 'XEOF';
\0__
 | 
/ \
XEOF
    $self->{'ascii2art_map'}->{'Z'} = << 'XEOF';
 0__
 |\
/ \
XEOF
    return 1;
}

sub decode {
    my $self    = shift;
    my $arg_ref = shift;

    my $frame   = $arg_ref->{FRAME};
    if (! defined $frame) {
        croak "You need to pass a frame to be decoded.";
    }
    my $last_frame_undo = rindex $frame, 'T';
    if ($last_frame_undo > 0) {
        # if a FUN was found, take everything to the right to be the
        # new frame.
        $frame = 'Q' . substr($frame, $last_frame_undo + 2);
    }
    while ($frame =~ m{ (.*) [^S]S (.*) }xms) {
        # delete the signal before a 'S' (SUN, signal undo)
        $frame = $1 . $2;
    }
    $frame =~ s/[U-Y]//g; # ignore ACK, KAL, NAK, RTR and RTT signals
    my ($header, $payload, $checksum) =
        ($frame =~ m{\A Q([A-E][A-B][A-P]{2}) ([A-P]+) ([A-P]{4})R \z}xms);
    if (! defined $header || ! defined $payload || ! defined $checksum) {
        croak "Invalid frame format.";
    }
    return $self->__pack($payload);
}

sub __pack {
    my $self  = shift;
    my $frame = shift;

    # convert from ASCII to hex
    $frame =~ tr/A-J/0-9/;
    $frame =~ tr/K-P/a-f/;
    return pack('H*', $frame);
}

sub __unpack {
    my $self = shift;
    my $data = shift;

    # unpack
    my $result = unpack('H*', $data);
    $result =~ tr/0-9/A-J/;
    $result =~ tr/a-f/K-P/;
    return $result;
}

sub encode {
    my $self    = shift;
    my $arg_ref = shift;

    my $sfs_frame = 'Q'; # Frame Start FST

    # type is ASCII or ASCII-ART
    my $type = 'ASCII';
    if (defined $arg_ref->{TYPE}) {
        $type = $arg_ref->{TYPE};
    }
    if ($type ne 'ASCII' && $type ne 'ASCII art') {
        croak "Invalid output type";
    }

    my $packet = $arg_ref->{PACKET};
    if (! defined $packet || ! length($packet)) {
        croak "You need to pass an IP packet";
    }

    my $checksum = 0;
    if (defined $arg_ref->{CHECKSUM}) {
        $checksum = $arg_ref->{CHECKSUM};
    };
    # TODO - implement CRC 16 support
    if ($checksum == 1) {
        croak "CRC 16 support not implemented (yet).";
    }
    elsif ($checksum > 1) {
        croak "Invalid checksum type";
    }

    my $framesize = $self->{default_framesize};
    if (exists $arg_ref->{FRAMESIZE}) {
        $framesize = $arg_ref->{FRAMESIZE};
    }
    # TODO - implement fragmenting
    # note: honor DF bit in IP packets
    if (length($packet) > $framesize) {
        croak "Fragmenting not implemented (yet).";
    }

    # TODO - implement support for gzipped frames
    my $gzip = $arg_ref->{GZIP};
    if ($gzip) {
        croak "GZIP support not implemented (yet).";
    }

    my $packet_ascii = $self->__unpack($packet);
    if (substr($packet_ascii, 0, 1) eq 'E') { # E=4: IPv4
        $sfs_frame .= 'B';
    }
    elsif (substr($packet_ascii, 0, 1) eq 'G') { # G=6: IPv6
        $sfs_frame .= 'C';
    }
    else {
        croak "Invalid IP version";
    }

    $sfs_frame .= 'A';    # Checksum Type: none
    $sfs_frame .= 'AA';   # Frame number 0x00

    $sfs_frame .= $packet_ascii;

    $sfs_frame .= 'AAAA'; # No checksum, so we just set it zeros 
    $sfs_frame .= 'R';    # Frame End, FEN

    if ($type eq 'ASCII') {
        return $sfs_frame;
    }
    else { # ASCII-ART
        my @sfss_ascii_art_frames = ();
        for (my $i = 0; $i < length($sfs_frame); $i++) {
            my $char = substr($sfs_frame, $i, 1);
            my $aa_repr = $self->ascii2art_map->{$char};
            if (! defined $aa_repr) {
                die "No ASCII-Art representation for '$char'";
            }
            push @sfss_ascii_art_frames, $aa_repr;
        }
        if (wantarray) {
            return @sfss_ascii_art_frames;
        }
        else {
            return join "\n", @sfss_ascii_art_frames;
        }
    }
}
1;
__END__

=head1 NAME

Acme::RFC4824 - Internet Protocol over Semaphore Flag Signaling System (SFSS)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module is used to help you implement RFC 4824 - The Transmission
of IP Datagrams over the Semaphore Flag Signaling System (SFSS).

It can be used to convert IP datagrams to SFS frames and the other
way round. Furthemore, it can be used to display an ASCII art representation
of the SFS frame.

    use Acme::RFC4824;

    my $sfss = Acme::RFC4824->new();
    
    # get IP datagram from somewhere (for example Net::Pcap)
    # print a representation of the SFS frame
    print $sfss->encode({
        TYPE   => 'ASCII art',
        PACKET => $datagram, 
    });

    # get an ASCII representation of the SFS frame
    my $sfs_frame = $sfss->encode({
        TYPE   => 'ASCII',
        PACKET => $datagram,
    });

    # get an SFS frame from somewhere
    # (for example from someone signaling you)
    # get an IP datagram from the frame
    my $datagram = $sfss->decode({
        FRAME => $frame,
    });

=head1 EXPORT

As this module is supposed to be used in an object oriented fashion, it
does not export anything.

=head1 FUNCTIONS

=head2 BUILD

see new()

=head2 new

Constructs a new object for you. Takes the following named parameters:

=over 1

=item * DEFAULT_FRAMESIZE (optional)

The framesize in bytes that is used whenever the FRAMESIZE paramter is
not given for encode. Defaults to 255 bytes (the maximum SFS frame size).

=back

=head2 encode

Encodes an IP datagram into one or more SFS frames. Currently, fragmenting
is not (yet) supported, so it will always encode into one frame (or
complain that the IP packet is too large to encode into one frame).

Takes the following named parameters:

=over 4

=item * TYPE

Determines the output format. Can either be 'ASCII' or 'ASCII art'.
In the first case, a string representation of the SFS frame is returned.
In the second case, an ASCII art representation is returned - as an
array of ASCII art strings in list context or as the concatenation in
scalar context.

=item * PACKET

The IP packet that you want to convert

=item * CHECKSUM (optional)

The checksum algorithm. Only 0 (no checksum) is implemented at the moment.

=item * FRAMESIZE (optional)

The optional maximal frame size of the SFS frame. Will later be used
to fragment, currently only limits the size of the packet you can encode.

=item * GZIP (optional)

Not implemented yet, meant to support the gzipped frame variant of RFC 4824.

=back

=head2 decode

Decodes one or more SFS frame into an IP datagram.

Takes the following named parameters:

=over 4

=item * FRAME

An ASCII representation of the SFS frame which you would like to decode
into an IP datagram.

=back

=head2 ascii2art_map

Read-only accessor for the attribute with the same name.
Returns a hash reference that maps SFS ASCII characters to an ASCII art
representation of the given character. There is probably no need to use
this from the outside.

=head2 default_framesize

Read-only accessor for the attribute with the same name.
Returns the default SFS framesize. There is probably no need to use this
from the outside.

=head2 meta

From Moose.pm: This is a method which provides access to the current class's
meta-class. Only used internally.

=head1 AUTHOR

Alexander Klink, C<< <alech at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-rfc4824 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-RFC4824>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::RFC4824

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-RFC4824>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-RFC4824>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-RFC4824>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-RFC4824>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the RFC 4824 authors for letting me use their ASCII art in this
module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Alexander Klink, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


