package Testmask7;
use strict;
use warnings;
use parent qw(Bitmask::Data);

__PACKAGE__->bitmask_length(64);
__PACKAGE__->bitmask_lazyinit(1);
__PACKAGE__->init(
    map { 'value'.$_ } (1..64)
);

1;