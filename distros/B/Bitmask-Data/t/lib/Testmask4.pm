package Testmask4;
use strict;
use warnings;
use parent qw(Bitmask::Data);

__PACKAGE__->bitmask_lazyinit(2);
__PACKAGE__->init(
    'value1',
    'value2',
    'value3',
    'value4',
    'value5'
);

1;