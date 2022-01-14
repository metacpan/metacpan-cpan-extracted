package Data::CompactReadonly::V0::Scalar::Float64;
our $VERSION = '0.1.0';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Scalar::Huge';

# FIXME this uses pack()'s d format underneath, which exposes the
# native machine floating point format. This is not guaranteed to
# actually be IEEE754. Yuck. Need to find a comprehensible spec and
# a comprehensive text suite and implement my own.
use Data::IEEE754 qw(unpack_double_be pack_double_be);

sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    print $fh $class->_type_byte_from_class().
              pack_double_be($args{data});
    $class->_set_next_free_ptr(%args);
}

sub _decode_word {
    my($class, $word) = @_;
    return unpack_double_be($word);
}

1;
