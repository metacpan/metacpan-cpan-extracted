package Data::ParseBinary::Stream::Reader;
use strict;
use warnings;

sub _readBitsForByteStream {
    my ($self, $bitcount) = @_;
    my $count = int($bitcount / 8) + ($bitcount % 8 ? 1 : 0);
    my $data = $self->ReadBytes($count);
    my $fullbits = unpack "B*", $data;
    my $string = substr($fullbits, -$bitcount);
    return $string;
}

sub _readBytesForBitStream {
    my ($self, $count) = @_;
    my $bitData = $self->ReadBits($count * 8);
    my $data = pack "B*", $bitData;
    return $data;
}

sub isBitStream { die "unimplemented" }
sub ReadBytes { die "unimplemented" }
sub ReadBits { die "unimplemented" }
sub seek { die "unimplemented" }
sub tell { die "unimplemented" }

our %_streamTypes;

sub _registerStreamType {
    my ($class, $typeName) = @_;
    $_streamTypes{$typeName} = $class;
}

sub CreateStreamReader {
    my @params = @_;
    if (@params == 0) {
        die "CreateStreamReader: mush have a parameter";
    }
    if (@params == 1) {
        my $source = $params[0];
        if (not defined $source or not ref $source) {
            # some value (string?). let's feed it to StringStreamWriter
            return $_streamTypes{String}->new($source);
        }
        if (UNIVERSAL::isa($source, "Data::ParseBinary::Stream::Reader")) {
            return $source;
        }
        die "Got unknown input to CreateStreamReader";
    }

    # @params > 1
    my $source = pop @params;
    while (@params) {
		my $opts = undef;
        my $type = pop @params;
		if ( defined( ref $type ) and @params and ( $params[-1] eq ' Opts' ) ) {
			$opts = $type;
			$type = pop @params;
		}
        if (not exists $_streamTypes{$type}) {
            die "CreateStreamReader: Unrecognized type: $type";
        }
        $source = $_streamTypes{$type}->new($source, $opts);
    }
    return $source;
}

sub DESTROY {
    my $self = shift;
    if ($self->can("disconnect")) {
        $self->disconnect();
    }
}

package Data::ParseBinary::Stream::Writer;

sub WriteBytes { die "unimplemented" }
sub WriteBits { die "unimplemented" }
sub Flush { die "unimplemented" }
sub isBitStream { die "unimplemented" }
sub seek { die "unimplemented" }
sub tell { die "unimplemented" }

sub _writeBitsForByteStream {
    my ($self, $bitdata) = @_;
    my $data_len = length($bitdata);
    my $zeros_to_add = (-$data_len) % 8;
    my $binary = pack "B".($zeros_to_add + $data_len), ('0'x$zeros_to_add).$bitdata;
    return $self->WriteBytes($binary);
}

sub _writeBytesForBitStream {
    my ($self, $data) = @_;
    my $bitdata = unpack "B*", $data;
    return $self->WriteBits($bitdata);
}

our %_streamTypes;

sub _registerStreamType {
    my ($class, $typeName) = @_;
    $_streamTypes{$typeName} = $class;
}

sub CreateStreamWriter {
    my @params = @_;
    if (@params == 0) {
        return $_streamTypes{String}->new();
    }
    if (@params == 1) {
        my $source = $params[0];
        if (not defined $source or not ref $source) {
            # some value (string?). let's feed it to StringStreamWriter
            return $_streamTypes{String}->new($source);
        }
        if (UNIVERSAL::isa($source, "Data::ParseBinary::Stream::Writer")) {
            return $source;
        }
        die "Got unknown input to CreateStreamWriter";
    }

    # @params > 1
    my $source = pop @params;
    while (@params) {
        my $type = pop @params;
        if (not exists $_streamTypes{$type}) {
            die "CreateStreamWriter: Unrecognized type: $type";
        }
        $source = $_streamTypes{$type}->new($source);
    }
    return $source;
}

sub DESTROY {
    my $self = shift;
    $self->Flush();
    if ($self->can("disconnect")) {
        $self->disconnect();
    }
}

package Data::ParseBinary::Stream::WrapperBase;
# this is a nixin class for streams that will warp other streams

sub _warping {
    my ($self, $sub_stream) = @_;
    if ($sub_stream->{is_warped}) {
        die "Wrapping Stream " . ref($self) . ": substream is already wraped!";
    }
    $self->{ss} = $sub_stream;
    $sub_stream->{is_wraped} = 1;
}

sub ss {
    my $self = shift;
    return $self->{ss};
}

sub disconnect {
    my ($self) = @_;
    $self->{ss}->{is_wraped} = 0;
    $self->{ss} = undef;
}

1;