use strict;
use warnings;

package Data::ParseBinary::Stream::BitReader;
our @ISA = qw{Data::ParseBinary::Stream::Reader Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("Bit");

sub new {
    my ($class, $byteStream) = @_;
    my $self = bless { buffer => '' }, $class;
    $self->_warping($byteStream);
    return $self;
}

sub ReadBytes {
    my ($self, $count) = @_;
    return $self->_readBytesForBitStream($count);
}

sub ReadBits {
    my ($self, $bitcount) = @_;
    my $current = $self->{buffer};
    my $moreBitsNeeded = $bitcount - length($current);
    $moreBitsNeeded = 0 if $moreBitsNeeded < 0;
    my $moreBytesNeeded = int($moreBitsNeeded / 8) + ($moreBitsNeeded % 8 ? 1 : 0);
    #print "BitStream: $bitcount bits requested, $moreBytesNeeded bytes read\n";
    my $string = $self->{ss}->ReadBytes($moreBytesNeeded);
    $current .= unpack "B*", $string;
    my $data = substr($current, 0, $bitcount, '');
    $self->{buffer} = $current;
    return $data;
}

sub tell {
    my $self = shift;
    #die "A bit stream is not seekable";
    if ($self->{buffer}) {
        return "Bit ". (8 - length($self->{buffer}))
    } else {
        return "Bit 0";
    }
}

sub seek {
    my ($self, $newpos) = @_;
    die "A bit stream is not seekable";
}

sub isBitStream { return 1 };


package Data::ParseBinary::Stream::BitWriter;
our @ISA = qw{Data::ParseBinary::Stream::Writer Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("Bit");

sub new {
    my ($class, $byteStream) = @_;
    my $self = bless { buffer => '' }, $class;
    $self->_warping($byteStream);
    return $self;
}

sub WriteBytes {
    my ($self, $data) = @_;
    return $self->_writeBytesForBitStream($data);
}

sub WriteBits {
    my ($self, $bitdata) = @_;
    my $current = $self->{buffer};
    my $new_buffer = $current . $bitdata;
    my $numof_bytesToWrite = int(length($new_buffer) / 8);
    my $bytesToWrite = substr($new_buffer, 0, $numof_bytesToWrite * 8, '');
    my $binaryToWrite = pack "B".($numof_bytesToWrite * 8), $bytesToWrite;
    $self->{buffer} = $new_buffer;
    return $self->{ss}->WriteBytes($binaryToWrite);
}

sub Flush {
    my $self = shift;
    my $write_size = (-length($self->{buffer})) % 8;
    $self->WriteBits('0'x$write_size);
    return $self->{ss}->Flush();
}

sub tell {
    my $self = shift;
    return "Bit ". length($self->{buffer});
    #die "A bit stream is not seekable";
}

sub seek {
    my ($self, $newpos) = @_;
    die "A bit stream is not seekable";
}

sub isBitStream { return 1 };

package Data::ParseBinary::Stream::ReversedBitStreamReader;
our @ISA = qw{Data::ParseBinary::Stream::BitReader};

__PACKAGE__->_registerStreamType("ReversedBit");

sub ReadBits {
    my ($self, $bitcount) = @_;
    my $current = $self->{buffer};
    my $moreBitsNeeded = $bitcount - length($current);
    if ($moreBitsNeeded > 0) {
        my $moreBytesNeeded = int($moreBitsNeeded / 8) + ($moreBitsNeeded % 8 ? 1 : 0);
        my $string = $self->{ss}->ReadBytes($moreBytesNeeded);
        $string = join '', reverse split '', $string if $moreBytesNeeded > 1;
        $current = unpack("B*", $string) . $current;
    }
    my $data = substr($current, -$bitcount, $bitcount, '');
    $data = join '', reverse split '', $data if length($data) > 1;
    $self->{buffer} = $current;
    return $data;
}

package Data::ParseBinary::Stream::ReversedBitStreamWriter;
our @ISA = qw{Data::ParseBinary::Stream::BitWriter};

__PACKAGE__->_registerStreamType("ReversedBit");

sub WriteBits {
    my ($self, $bitdata) = @_;
    $bitdata = join '', reverse split '', $bitdata if length($bitdata) > 1;
    $self->{buffer} = $bitdata . $self->{buffer};
    my $numof_bytesToWrite = int(length($self->{buffer}) / 8);    
    my $num_of_bits_to_cut = $numof_bytesToWrite * 8;
    my $bytesToWrite = substr($self->{buffer}, -$num_of_bits_to_cut, $num_of_bits_to_cut, '');
    my $binaryToWrite = pack "B".($numof_bytesToWrite * 8), $bytesToWrite;
    $binaryToWrite = join '', reverse split '', $binaryToWrite if $numof_bytesToWrite > 1;
    return $self->{ss}->WriteBytes($binaryToWrite);
}

1;