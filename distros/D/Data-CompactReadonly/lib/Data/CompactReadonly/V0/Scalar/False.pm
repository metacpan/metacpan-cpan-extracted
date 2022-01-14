package Data::CompactReadonly::V0::Scalar::False;
our $VERSION = '0.1.0';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Scalar::HeaderOnly';

sub _init { return 1 == 0; }

1;
