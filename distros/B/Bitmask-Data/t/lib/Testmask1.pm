package Testmask1;

use strict;
use warnings;

use parent qw(Bitmask::Data);
use Math::BigInt;

__PACKAGE__->bitmask_lazyinit(1);
__PACKAGE__->init(
    'value1', #1
    'value2' => 0b0000000000000010, #2
    'value3' => 0x8000, #16
    'value4' => 0x4, #3
    'value5', # 5
    'value6' => '0b0100000', # 6 
    'value7' => 8, #4
    'value8' => Math::BigInt->new('128'),
    'value9' => "\1\0\0\0\0\0\0\0\0",
);

1;