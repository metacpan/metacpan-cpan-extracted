package Data::CompactReadonly::V0::NegativeScalar;
our $VERSION = '0.0.6';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Scalar';

sub _init {
    my($class, %args) = @_;
    return -1 * $class->SUPER::_init(%args);
}

1;
