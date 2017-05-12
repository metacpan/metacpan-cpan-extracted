package Class::Load::Error::DieAfterBeginIsa;

use strict;
use warnings;

BEGIN {
    our @ISA = qw( UNIVERSAL );
}

die "Not a syntax error";

