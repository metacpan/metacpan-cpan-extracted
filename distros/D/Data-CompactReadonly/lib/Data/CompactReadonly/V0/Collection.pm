package Data::CompactReadonly::V0::Collection;
our $VERSION = '0.0.5';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Node';

use Scalar::Util qw(blessed);
use Data::CompactReadonly::V0::Scalar;

sub _numeric_type_for_length {
    my $invocant = shift();
    (my $class = blessed($invocant) ? blessed($invocant) : $invocant) =~ s/(Text|Array|Dictionary)/Scalar/;
    return $class;
}

sub count {
    my $self = shift;
    if($self->{cache} && exists($self->{cache}->{count})) {
        return $self->{cache}->{count};
    } elsif($self->{cache}) {
        return $self->{cache}->{count} = $self->_count();
    } else {
        return $self->_count();
    }
}

sub _count {
    my $self = shift;
    $self->_seek($self->_offset());
    return $self->_numeric_type_for_length()->_init(root => $self->_root());
}

sub id {
    my $self = shift;
    return $self->_offset();
}

sub _scalar_type_bytes {
    my $self = shift;
    return $self->_numeric_type_for_length()->_num_bytes();
}

sub _encode_ptr {
    my($class, %args) = @_;
    return Data::CompactReadonly::V0::Scalar->_encode_word_as_number_of_bytes(
        $args{pointer}, 
        $args{ptr_size}
    );
}

sub _decode_ptr {
    goto &Data::CompactReadonly::V0::Scalar::_decode_word;
}

1;
