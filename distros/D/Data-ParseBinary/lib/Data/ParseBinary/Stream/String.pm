use strict;
use warnings;

package Data::ParseBinary::Stream::StringRefReader;
our @ISA = qw{Data::ParseBinary::Stream::Reader};

__PACKAGE__->_registerStreamType("StringRef");

sub new {
    my ($class, $stringref) = @_;
    my $self = {
        data => $stringref,
        location => 0,
        length => length($$stringref),
    };
    return bless $self, $class;
}

sub ReadBytes {
    my ($self, $count) = @_;
    die "not enought bytes in stream" if $self->{location} + $count > $self->{length};
    my $data = substr(${ $self->{data} }, $self->{location}, $count);
    $self->{location} += $count;
    return $data;
}

sub ReadBits {
    my ($self, $bitcount) = @_;
    return $self->_readBitsForByteStream($bitcount);
}

sub tell {
    my $self = shift;
    return $self->{location};
}

sub seek {
    my ($self, $newpos) = @_;
    die "can not seek past string's end" if $newpos > $self->{length};
    $self->{location} = $newpos;
}

sub isBitStream { return 0 };

package Data::ParseBinary::Stream::StringReader;
our @ISA = qw{Data::ParseBinary::Stream::StringRefReader};

__PACKAGE__->_registerStreamType("String");

sub new {
    my ($class, $string) = @_;
    return $class->SUPER::new(\$string);
}

package Data::ParseBinary::Stream::StringRefWriter;
our @ISA = qw{Data::ParseBinary::Stream::Writer};

__PACKAGE__->_registerStreamType("StringRef");

sub new {
    my ($class, $source) = @_;
    if (not defined $source) {
        my $data = '';
        $source = \$data;
    }
    my $self = {
        data => $source,
        offset => 0, # minus bytes from the end
    };
    return bless $self, $class;
}

sub tell {
    my $self = shift;
    return length(${ $self->{data} }) - $self->{offset};
}

sub seek {
    my ($self, $newpos) = @_;
    if ($newpos > length(${ $self->{data} })) {
        $self->{offset} = 0;
        ${ $self->{data} } .= "\0" x ($newpos - length(${ $self->{data} }))
    } else {
        $self->{offset} = length(${ $self->{data} }) - $newpos;
    }
}

sub WriteBytes {
    my ($self, $data) = @_;
    if ($self->{offset} == 0) {
        ${ $self->{data} } .= $data;
        return length ${ $self->{data} };
    }
    substr(${ $self->{data} }, -$self->{offset}, length($data), $data);
    if ($self->{offset} <= length($data)) {
        $self->{offset} = 0;
    } else {
        $self->{offset} = $self->{offset} - length($data);
    }
    return length(${ $self->{data} }) - $self->{offset};
}

sub WriteBits {
    my ($self, $bitdata) = @_;
    return $self->_writeBitsForByteStream($bitdata);
}

sub Flush {
    my $self = shift;
    return $self->{data};
}

sub isBitStream { return 0 };

package Data::ParseBinary::Stream::StringWriter;
our @ISA = qw{Data::ParseBinary::Stream::StringRefWriter};

__PACKAGE__->_registerStreamType("String");

sub new {
    my ($class, $source) = @_;
    $source = '' unless defined $source;
    return $class->SUPER::new(\$source);
}

sub Flush {
    my $self = shift;
    my $data = $self->SUPER::Flush();
    return $$data;
}


1;