package Acme::Playpen::_common;

use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

1;
