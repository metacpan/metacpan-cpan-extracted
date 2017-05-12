use strict;
use warnings;

package Data::ParseBinary::Stream::WrapperReader;
our @ISA = qw{Data::ParseBinary::Stream::Reader Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("Wrap");

sub new {
    my ($class, $sub_stream) = @_;
    my $self = bless { }, $class;
    $self->_warping($sub_stream);
    return $self;
}

sub ReadBytes { my $self = shift; $self->{ss}->ReadBytes(@_);  }
sub ReadBits { my $self = shift; $self->{ss}->ReadBits(@_); }
sub isBitStream { my $self = shift; $self->{ss}->isBitStream(@_); }
sub seek { my $self = shift; $self->{ss}->seek(@_); }
sub tell { my $self = shift; $self->{ss}->tell(@_); }

package Data::ParseBinary::Stream::WrapperWriter;
our @ISA = qw{Data::ParseBinary::Stream::Writer Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("Wrap");

sub new {
    my ($class, $sub_stream) = @_;
    my $self = bless { }, $class;
    $self->_warping($sub_stream);
    return $self;
}

sub WriteBytes { my $self = shift; $self->{ss}->WriteBytes(@_);  }
sub WriteBits { my $self = shift; $self->{ss}->WriteBits(@_); }
sub Flush { my $self = shift; return $self->{ss} }
sub isBitStream { my $self = shift; $self->{ss}->isBitStream(@_); }
sub seek { my $self = shift; $self->{ss}->seek(@_); }
sub tell { my $self = shift; $self->{ss}->tell(@_); }

1;