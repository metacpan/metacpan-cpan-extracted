use strict;
use warnings;

package Data::ParseBinary::Stream::FileReader;
our @ISA = qw{Data::ParseBinary::Stream::Reader};

__PACKAGE__->_registerStreamType("File");

sub new {
    my ($class, $fh) = @_;
    my $self = {
        handle => $fh,
    };
    return bless $self, $class;
}

sub ReadBytes {
    my ($self, $count) = @_;
    my $buf = '';
    while ((my $buf_len = length($buf)) < $count) {
        my $bytes_read = read($self->{handle}, $buf, $count - $buf_len, $buf_len);
        die "Error: End of file" if $bytes_read == 0;
    }
    return $buf;
}

sub ReadBits {
    my ($self, $bitcount) = @_;
    return $self->_readBitsForByteStream($bitcount);
}

sub tell {
    my $self = shift;
    return CORE::tell($self->{handle});
}

sub seek {
    my ($self, $newpos) = @_;
    CORE::seek($self->{handle}, $newpos, 0);
}

sub isBitStream { return 0 };

package Data::ParseBinary::Stream::FileWriter;
our @ISA = qw{Data::ParseBinary::Stream::Writer};

__PACKAGE__->_registerStreamType("File");

sub new {
    my ($class, $fh) = @_;
    my $self = {
        handle => $fh,
    };
    return bless $self, $class;
}

sub WriteBytes {
    my ($self, $data) = @_;
    print { $self->{handle} } $data;
}

sub WriteBits {
    my ($self, $bitdata) = @_;
    return $self->_writeBitsForByteStream($bitdata);
}

sub tell {
    my $self = shift;
    return CORE::tell($self->{handle});
}

sub seek {
    my ($self, $newpos) = @_;
    CORE::seek($self->{handle}, $newpos, 0);
}

sub Flush {
    my $self = shift;
}

sub isBitStream { return 0 };


1;