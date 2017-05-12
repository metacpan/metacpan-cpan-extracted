use strict;
$^W = 1;

use Test::More tests => 3;

use CPU::Emulator::Memory;

my $memory = CPU::Emulator::Memory->new(
    bytes => 'This is all the memory',
);

ok($memory->peek(length('This is all the memory') - 1) == ord('y'), "Memory is initialised correctly from a string");


$memory = CPU::Emulator::Memory->new(
    bytes => 'This is all the memory',
    size  => length('This is all the memory')
);

ok($memory->peek(length('This is all the memory') - 1) == ord('y'), "Memory is initialised correctly from a string");


eval { CPU::Emulator::Memory->new(bytes => 'This is all the memory', size => 2) };
like($@, qr/bytes and size don't match/, "size mismatch");
