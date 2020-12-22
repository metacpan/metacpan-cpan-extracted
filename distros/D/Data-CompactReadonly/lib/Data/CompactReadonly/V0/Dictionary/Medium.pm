package Data::CompactReadonly::V0::Dictionary::Medium;
our $VERSION = '0.0.4';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Dictionary';

use Data::CompactReadonly::V0::Scalar::Medium;

# this class only exists so it can encode the length's
# type in its name, and load that type

1;
