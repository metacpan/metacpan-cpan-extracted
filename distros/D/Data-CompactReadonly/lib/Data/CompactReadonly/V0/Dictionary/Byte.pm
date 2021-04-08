package Data::CompactReadonly::V0::Dictionary::Byte;
our $VERSION = '0.0.5';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Dictionary';

use Data::CompactReadonly::V0::Scalar::Byte;

# this class only exists so it can encode the length's
# type in its name, and load that type

1;
