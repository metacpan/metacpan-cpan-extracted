package Data::CompactReadonly::V0::Array::Long;
our $VERSION = '0.0.2';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Array';

use Data::CompactReadonly::V0::Scalar::Long;

# this class only exists so it can encode the length's
# type in its name, and load that type

1;
