package Data::CompactReadonly::V0::Array::Byte;
our $VERSION = '0.0.1';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Array';

use Data::CompactReadonly::V0::Scalar::Byte;

# this class only exists so it can encode the length's
# type in its name, and load that type

1;
