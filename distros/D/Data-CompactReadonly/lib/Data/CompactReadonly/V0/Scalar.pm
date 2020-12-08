package Data::CompactReadonly::V0::Scalar;
our $VERSION = '0.0.2';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Node';

sub _init {
    my($class, %args) = @_;
    my $parent = $args{parent};
    
    my $word = $parent->_bytes_at_current_offset($class->_num_bytes());
    return $class->_decode_word($word);
}

# turn a sequence of bytes into an integer
sub _decode_word {
    my($class, $word) = @_;

    my $value = 0;
    foreach my $byte (split(//, $word)) {
        $value *= 256;
        $value += ord($byte);
    }
    return $value;
}

sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);

    print $fh $class->_type_byte_from_class().
              $class->_get_bytes_from_word(abs($args{data}));
}

sub _get_bytes_from_word {
    my($class, $word) = @_;
    return $class->_encode_word_as_number_of_bytes($word, $class->_num_bytes());
}

# given an integer and a number of bytes, encode that int
# as a sequence of bytes, zero-padding if necessary
sub _encode_word_as_number_of_bytes {
    my($class, $word, $num_bytes) = @_;

    my $bytes = '';
    while($word) {
        $bytes = chr($word & 0xff).$bytes;
        $word >>= 8;
    }

    # zero-pad if needed
    $bytes = (chr(0) x ($num_bytes - length($bytes))).$bytes
        if(length($bytes) < $num_bytes);

    return $bytes;
}

1;
