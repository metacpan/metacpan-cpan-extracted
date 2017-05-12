package Testmask2;
use strict;
use warnings;
use parent qw(Bitmask::Data);

__PACKAGE__->bitmask_length(3);
__PACKAGE__->bitmask_default(5);
__PACKAGE__->init(
    r       => 0b100,
    w       => 0b010,
    x       => 0b001,
);

1;