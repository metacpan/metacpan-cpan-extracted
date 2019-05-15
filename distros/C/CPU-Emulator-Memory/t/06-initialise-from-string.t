use strict;
$^W = 1;

use Test::More tests => 6;

use CPU::Emulator::Memory;

my $memory = CPU::Emulator::Memory->new(
    bytes => 'This is all the memory',
);
ok($memory->peek(length('This is all the memory') - 1) == ord('y'), "Memory is initialised correctly from a string");

$memory = CPU::Emulator::Memory->new(
    bytes => 'This is all the memory',
    size  => length('This is all the memory')
);
ok($memory->peek(length('This is all the memory') - 1) == ord('y'), "Memory is initialised correctly from a string and size");

$memory = CPU::Emulator::Memory->new(
    bytes => 'This is all the memory',
    size  => length('This is all the memory') + 4,
    org   => 4
);
ok($memory->peek(length('....This is all the memory') - 1) == ord('y'), "Memory is loaded correctly from a string with an org");
ok($memory->peek(3) == 0, "Preceding bytes are zero");
eval { $memory->peek(length('....This is all the memory')); };
like($@, qr/Address.*out of range/, "size is adjusted correctly");

eval { CPU::Emulator::Memory->new(bytes => 'This is all the memory', size => 2) };
like($@, qr/bytes and size don't match/, "size mismatch");
