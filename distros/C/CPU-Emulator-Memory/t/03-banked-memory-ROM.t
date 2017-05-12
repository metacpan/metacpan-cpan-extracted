use strict;
$^W = 1;

use Test::More tests => 39;

use CPU::Emulator::Memory::Banked;
use IO::Scalar;
use IO::File;
require './t/read_write_binary.pl';

unlink 'ramfile.ram', 'romfile.rom';
my $memory = CPU::Emulator::Memory::Banked->new(file => 'ramfile.ram');

# NB using {0xHEXSTUFF} in regexes doesn't work.
# and the repeated {30000}...{30000} is cos there's a 2^15 - 2 limit

write_binary('romfile.rom', 'This is a ROM');

# no file
eval { $memory->bank(
    address => 0,
    size    => length('This is a ROM'), 
    type    => 'ROM'
) };
ok($@, "Can't map ROM without a filename");

# size mismatch
eval { $memory->bank(
    address => 0,
    size    => 1, 
    type    => 'ROM',
    file    => 'romfile.rom'
) };
like($@, qr/is wrong size/, "size mismatch");

# default size
$memory->bank(
    address => 0,
    type    => 'ROM',
    file    => 'romfile.rom'
);
ok($memory->peek(0)  == ord('T'), "peek returns data from the ROM");
ok($memory->peek(12) == ord('M'), "peek returns data from the ROM");

# defined size
$memory->bank(
    address => 0,
    size    => length('This is a ROM'), 
    type    => 'ROM',
    file    => 'romfile.rom'
);
ok($memory->peek(0) == ord('T'), "peek returns data from the ROM");
ok($memory->peek(12) == ord('M'), "peek returns data from the ROM");
ok($memory->poke(0, 1) == 0, "poke returns 0 when we try to write ...");
ok($memory->peek(0) == ord('T'), "... and really didn't change anything");
ok($memory->peek8(0) == ord('T'), "peek8 reads from ROM too");
ok($memory->poke(0xFFFF, 1) && $memory->peek(0xFFFF) == 1, "We can still write elsewhere in RAM");

$memory->unbank(address => 0);
ok($memory->peek(0) == 0, "poking to ROM is ignored when writethrough isn't enabled");

$memory->bank(
    address => 1,
    type    => 'ROM',
    file    => 'romfile.rom',
    writethrough => 1
);
ok($memory->peek(0) == 0 && $memory->peek(1) == ord('T'), "Loading a ROM at a random address puts it at the right place");
$memory->poke(1, 1);
ok($memory->poke8(2, 1) == 1, "poke8 claims to writethrough");
$memory->unbank(address => 1);
ok($memory->peek(1) == 1, "With writethrough, RAM gets updated");
ok($memory->peek(2) == 1, "poke8 worked too");

$_ = read_binary('romfile.rom');
ok($_ eq 'This is a ROM', "ROM files don't get altered");

$_ = read_binary('ramfile.ram');
ok(/^\000\001{2}\000{30000}\000{30000}\000{5532}\001$/, "With writethrough, RAM file gets updated correctly");

$memory->bank(
    address => 0,
    type    => 'ROM',
    file    => 'romfile.rom'
);
$memory->bank(
    address => 6,
    type    => 'ROM',
    file    => 'romfile.rom'
);
ok($memory->peek(0) == 0, "Loading a new overlay starting in an older one unloads the old one ...");
ok($memory->peek(6) == ord('T'), "... and loads the new one");

$memory->bank(
    address => 6,
    type    => 'ROM',
    file    => 'romfile.rom'
);
$memory->bank(
    address => 0,
    type    => 'ROM',
    file    => 'romfile.rom'
);
ok($memory->peek(5 + length('This is a ROM')) == 0, "Loading a new overlay finishing in an older one unloads the old one ...");
ok($memory->peek(0) == ord('T'), "... and loads the new one");
ok($memory->peek16(0) == ord('T') + 256 * ord('h'), "peek16 reads from ROM too");

ok(unlink('ramfile.ram'), "ramfile.ram deleted");
ok(unlink('romfile.rom'), "romfile.rom deleted");

$memory->bank(
    address => 0,
    size => 1,
    type => 'ROM',
    file => IO::Scalar->new(do {
        (my $foo = <DATA>) =~ s/\s+$//;
        \$foo;
    })
);
ok($memory->peek(0) == ord('A'), "ROM 'file' can also be a filehandle");

# test banked ROM with chr(13) and chr(10) inside 
# - needs binmode to read/write correctly in Win32
write_binary('romfile.rom', "\x01\x0D\x0A");
is(-s 'romfile.rom', 3, "binmode was used, size is OK");
$memory->bank(
    address => 0,
    size => 3, 
    type => 'ROM',
    file => 'romfile.rom'
);
is($memory->peek(0), 1, "peek 1");
is($memory->peek(1), 13, "peek 13");
is($memory->peek(2), 10, "peek 10");

# test with filehandle
open(my $fh, 'romfile.rom') || die("Couldn't read romfile.rom\n");
$memory->bank(
    address => 0,
    size => 3,
    type => 'ROM',
    file => $fh
);
is($memory->peek(0), 1, "peek 1");
is($memory->peek(1), 13, "peek 13");
is($memory->peek(2), 10, "peek 10");
close $fh;

# test with IO::File
$memory->bank(
    address => 0,
    size => 3,
    type => 'ROM',
    file => IO::File->new('romfile.rom', 'r')
);
is($memory->peek(0), 1, "peek 1");
is($memory->peek(1), 13, "peek 13");
is($memory->peek(2), 10, "peek 10");

undef $memory; # to release IO::File handle
ok(unlink('romfile.rom'), "romfile.rom deleted");

__DATA__
A
