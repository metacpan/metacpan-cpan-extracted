package App::FileSync::Protocol;

use strict;
use warnings;

use IO::Handle ();
use Compress::Raw::Zlib ();

use App::FileSync qw(json_encode json_decode);

# Payloads are raw-deflated when that makes them smaller.  Small payloads and
# already-compressed data are left alone, so the flag costs more than it saves.
our $COMPRESS_MIN = 256;
our $MAX_WIRE     = 64 * 1024 * 1024;
our $MAX_INFLATED = 64 * 1024 * 1024;

# One connection, strictly one request in flight at a time.
# Control messages are JSON on one line; binary payloads are announced by "len" and
# follow the header immediately.
sub new {
    my ($class, %args) = @_;

    my $in  = $args{in};
    my $out = $args{out};
    die "Protocol: no input handle\n"  unless $in;
    die "Protocol: no output handle\n" unless $out;

    binmode $in;
    binmode $out;
    $out->autoflush(1);

    return bless {
        in             => $in,
        out            => $out,
        buffer         => '',
        closed         => 0,
        # Payload bytes as they crossed the wire, headers and control
        # messages excluded: this is the number a transfer report means.
        sent_bytes     => 0,
        received_bytes => 0,
    }, $class;
}

sub send {
    my ($self, $message) = @_;
    die "Protocol: connection is closed\n" if $self->{closed};

    my $line = json_encode($message);
    print { $self->{out} } $line, "\n"
        or die "Protocol: cannot write to the connection: $!\n";

    return 1;
}

sub recv {
    my ($self) = @_;

    my $line = $self->read_line();
    my $message = eval { json_decode($line) };
    if ($@) {
        die "Protocol: malformed message from the peer: $@";
    }
    die "Protocol: message is not an object\n" unless ref($message) eq 'HASH';

    return $message;
}

sub send_bytes {
    my ($self, $bytes) = @_;
    die "Protocol: connection is closed\n" if $self->{closed};
    return 1 unless defined $bytes && length $bytes;

    print { $self->{out} } $bytes
        or die "Protocol: cannot write payload: $!\n";

    return 1;
}

# Send a header and its binary payload, compressing the payload when that is
# worthwhile.  The header carries the wire length and a "z" flag, so a peer
# that does not know the flag would reject the frame rather than misread it.
sub send_data {
    my ($self, $message, $bytes) = @_;

    my ($wire, $compressed) = _deflate(defined $bytes ? $bytes : '');

    my %header = %{ $message || {} };
    $header{len} = length $wire;
    $header{z}   = 1 if $compressed;

    $self->send(\%header);
    $self->send_bytes($wire);
    $self->{sent_bytes} += length $wire;

    return 1;
}

# Read the payload announced by a send_data header, decompressing if needed.
sub read_data {
    my ($self, $message) = @_;

    my $length = defined $message->{len} ? $message->{len} : 0;
    die "Protocol: bad payload length\n"
        unless $length =~ /\A\d+\z/ && $length <= $MAX_WIRE;

    my $wire = $length ? $self->read_bytes($length) : '';
    $self->{received_bytes} += length $wire;

    return $message->{z} ? _inflate($wire) : $wire;
}

sub _deflate {
    my ($bytes) = @_;

    return ('', 0) unless defined $bytes && length $bytes;
    return ($bytes, 0) if length($bytes) < $COMPRESS_MIN;

    my ($deflater, $status) = Compress::Raw::Zlib::Deflate->new(
        -WindowBits => -Compress::Raw::Zlib::MAX_WBITS(),
        -Level      => 6,
    );
    return ($bytes, 0)
        unless $deflater && $status == Compress::Raw::Zlib::Z_OK();

    my $out = '';
    $status = $deflater->deflate($bytes, $out);
    return ($bytes, 0) unless $status == Compress::Raw::Zlib::Z_OK();

    my $tail = '';
    $status = $deflater->flush($tail);
    $out .= $tail if $status == Compress::Raw::Zlib::Z_OK();

    return length($out) < length($bytes) ? ($out, 1) : ($bytes, 0);
}

sub _inflate {
    my ($wire) = @_;

    my ($inflater, $status) = Compress::Raw::Zlib::Inflate->new(
        -WindowBits => -Compress::Raw::Zlib::MAX_WBITS(),
    );
    die "Protocol: cannot decompress the payload\n"
        unless $inflater && $status == Compress::Raw::Zlib::Z_OK();

    my $out = '';
    $status = $inflater->inflate($wire, $out);
    die "Protocol: corrupt compressed payload\n"
        unless $status == Compress::Raw::Zlib::Z_OK()
            || $status == Compress::Raw::Zlib::Z_STREAM_END();
    die "Protocol: compressed payload expands beyond the limit\n"
        if length($out) > $MAX_INFLATED;

    return $out;
}

sub read_line {
    my ($self) = @_;

    my $position;
    while (($position = index($self->{buffer}, "\n")) < 0) {
        $self->_fill();
    }

    my $line = substr($self->{buffer}, 0, $position);
    substr($self->{buffer}, 0, $position + 1, '');

    return $line;
}

sub read_bytes {
    my ($self, $length) = @_;

    die "Protocol: negative payload length\n" if $length < 0;
    while (length($self->{buffer}) < $length) {
        $self->_fill();
    }

    return substr($self->{buffer}, 0, $length, '');
}

sub _fill {
    my ($self) = @_;

    my $read = sysread($self->{in}, my $chunk, 65536);
    if (!defined $read) {
        die "Protocol: read error: $!\n";
    }
    if ($read == 0) {
        $self->{closed} = 1;
        die "Protocol: connection closed by the peer\n";
    }

    $self->{buffer} .= $chunk;
    return 1;
}

sub bytes_sent { $_[0]{sent_bytes} || 0 }
sub bytes_received { $_[0]{received_bytes} || 0 }

sub close {
    my ($self) = @_;
    return if $self->{closed};
    $self->{closed} = 1;
    close $self->{in};
    close $self->{out};
    return 1;
}

1;
