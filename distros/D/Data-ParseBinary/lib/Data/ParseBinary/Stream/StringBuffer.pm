use strict;
use warnings;

package Data::ParseBinary::Stream::StringBufferReader;
our @ISA = qw{Data::ParseBinary::Stream::StringRefReader Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("StringBuffer");

sub new {
    my ($class, $sub_stream) = @_;
    my $string = '';
    my $self = $class->SUPER::new(\$string);
    $self->_warping($sub_stream);
    return $self;
}

sub ReadBytes {
    my ($self, $count) = @_;
    if ($self->{location} + $count > $self->{length}) {
        my $more_needed = $count - ($self->{length} - $self->{location});
        my $new_bytes = $self->{ss}->ReadBytes($more_needed);
        ${ $self->{data} } .= $new_bytes;
        $self->{length} += $more_needed;
    }
    return $self->SUPER::ReadBytes($count);
}

sub seek {
    my ($self, $newpos) = @_;
    if ($newpos > $self->{length}) {
        my $more_needed = $newpos - $self->{length};
        my $new_bytes = $self->{ss}->ReadBytes($more_needed);
        ${ $self->{data} } .= $new_bytes;
        $self->{length} += $more_needed;
    }
    $self->SUPER::seek($newpos);
}

package Data::ParseBinary::Stream::StringBufferWriter;
our @ISA = qw{Data::ParseBinary::Stream::StringRefWriter Data::ParseBinary::Stream::WrapperBase};

__PACKAGE__->_registerStreamType("StringBuffer");

sub new {
    my ($class, $sub_stream) = @_;
    my $source = '';
    my $self = $class->SUPER::new(\$source);
    $self->_warping($sub_stream);
    return $self;
}

sub Flush {
    my $self = shift;
    my $data = $self->SUPER::Flush();
    $self->{ss}->WriteBytes($$data);
    my $empty_string = '';
    $self->{data} = \$empty_string;
    $self->{offset} = 0;
    return $self->{ss}->Flush();
}


1;