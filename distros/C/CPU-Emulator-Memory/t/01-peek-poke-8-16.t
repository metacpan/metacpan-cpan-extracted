use strict;
$^W = 1;

use Test::More;
END { done_testing }

use CPU::Emulator::Memory;

my $memory = CPU::Emulator::Memory->new();
ok($memory->poke16(0x1000, 258) && $memory->peek16(0x1000) == 258,
    "Can peek and poke 16 bit values");
ok($memory->peek(0x1000) == 2 && $memory->peek(0x1001) == 1,
    "Little-endian works");
ok($memory->peek8(0x1000) == 2 && $memory->peek8(0x1001) == 1,
    "peek8 works");

$memory = CPU::Emulator::Memory->new(
    endianness => 'BIG'
);
$memory->poke16(0x1000, 258);
ok($memory->peek(0x1000) == 1 && $memory->peek(0x1001) == 2,
    "Big-endian poke16 works");
ok($memory->peek16(0x1000) == 258,
    "Big-endian peek16 works");
