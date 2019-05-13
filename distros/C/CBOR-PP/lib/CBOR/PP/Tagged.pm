package CBOR::PP::Tagged;

use strict;
use warnings;

sub new {
    return bless \@_, shift;
}

1;
