use strict;
$^W = 1;

use Test::More tests => 12;

use CPU::Emulator::Memory::Banked;

my $memory = CPU::Emulator::Memory::Banked->new();

# out of range errors
eval { $memory->peek(-1); };
ok($@ =~ /^Address .* out of range/i, "Can't peek below address range");
eval { $memory->peek(0x10000); };
ok($@ =~ /^Address .* out of range/i, "Can't peek above address range");
ok($memory->peek(0) == 0, "Can peek bottom of range");
ok($memory->peek(0xFFFF) == 0, "Can peek top of range");

eval { $memory->poke(-1, 1); };
ok($@ =~ /^Address .* out of range/i, "Can't poke below address range");
eval { $memory->poke(0x10000, 1); };
ok($@ =~ /^Address .* out of range/i, "Can't poke above address range");
eval { $memory->poke(0, -1); };
ok($@ =~ /^Value .* out of range/i, "Can't poke values below range");
eval { $memory->poke(0, 256); };
ok($@ =~ /^Value .* out of range/i, "Can't poke values above range");
ok($memory->poke(0, 1) && $memory->peek(0) == 1,
    "Can poke bottom of address range");
ok($memory->poke(0xFFFF, 1) && $memory->peek(0) == 1,
    "Can poke top of address range");

$memory = CPU::Emulator::Memory::Banked->new(size => 100);
eval { $memory->peek(101); };
ok($@ =~ /^Address .* out of range/i, "When we set memory size, it works");

eval { $memory->bank(
    address => 99,
    size    => 10,
    type    => 'RAM',
); };
ok($@ =~ /address and size is out of range/i, "Banks can't be mapped stupidly");
