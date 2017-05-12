use strict;
$^W = 1;

use Test::More tests => 12;

use CPU::Emulator::Memory;

require './t/read_write_binary.pl';

unlink 'newfile.ram';
my $memory = CPU::Emulator::Memory->new(file => 'newfile.ram');

# NB using {0xHEXSTUFF} in regexes doesn't work.
# and the repeated {30000}...{30000} is cos there's a 2^15 - 2 limit

$_ = read_binary('newfile.ram');
ok(/^\000{30000}\000{30000}\000{5536}$/, "New file created as all zeroes");
ok($memory->peek(0) == 0, "Peek confirms a zero");
ok($memory->poke(0, 1) && $memory->peek(0) == 1, "Poke works ...");
ok($memory->poke(1, 13) && $memory->peek(1) == 13, "Poke works ...");
ok($memory->poke(2, 10) && $memory->peek(2) == 10, "Poke works ...");
is(-s 'newfile.ram', 0x10000, "file is correct size");
$_ = read_binary('newfile.ram');
ok(/^\001\015\012\000{30000}\000{30000}\000{5533}$/s, "... and is reflected in the file");

undef $memory;

my $newmemory = CPU::Emulator::Memory->new(file => 'newfile.ram');
ok($newmemory->peek(0) == 1, "RAM can be initialised correctly from a file");

# because Win32 is retarded, see RT 62375
ok(unlink('newfile.ram'), "newfile.ram deleted");
