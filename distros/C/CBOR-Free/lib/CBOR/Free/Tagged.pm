package CBOR::Free::Tagged;

use strict;
use warnings;

sub new {
    return bless \@_, shift;
}

1;
