use strict;
$^W = 1;

use Test::More tests => 8;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();
my $m = $cpu->memory();

my @buffer = ();

$cpu->add_input_device(
    address => 0xC000,
    function => sub { scalar(@buffer); }
);
$cpu->add_input_device(
    address => 0xC001,
    function => sub { shift(@buffer) || 0 }
);

$cpu->register('PC')->set(0);
$m->poke16(0, 0xC03E); # LD A, 0xC0
$m->poke16(2, 0x00DB); # IN A, (00) ; read from 0x[A]00

$cpu->run(2);
ok($cpu->register('A')->get() == 0, "Read status port says 0 when nothing available");

push @buffer, ord('A'), ord('B'), ord('C');

$cpu->register('PC')->set(0);
$m->poke16(0, 0xC03E); # LD A, 0xC0
$m->poke16(2, 0x00DB); # IN A, (00) ; read from 0xC000
$cpu->run(2);
ok($cpu->register('A')->get() == 0x03, "Read status port says number of bytes available");

$m->poke16(4, 0xC03E);
$m->poke16(6, 0x01DB); # IN A, (00) ; read from 0xC001
$cpu->run(2);
ok($cpu->register('A')->get() == ord('A'), "Got right value when we read");

$m->poke16(8,  0xC03E);
$m->poke16(10, 0x00DB); # IN A, (00) ; read from 0xC000
$cpu->run(2);
ok($cpu->register('A')->get() == 2, "Available bytes decreases");
$m->poke16(12, 0xC03E);
$m->poke16(14, 0x01DB); # IN A, (01) ; read from 0xC001
$cpu->run(2);
ok($cpu->register('A')->get() == ord('B'), "Got right value when we read again");

$m->poke16(16, 0xC03E);
$m->poke16(18, 0x00DB); # IN A, (00) ; read from 0xC000
$cpu->run(2);
ok($cpu->register('A')->get() == 1, "Available bytes decreases");
$m->poke16(20, 0xC03E);
$m->poke16(22, 0x01DB); # IN A, (01) ; read from 0xC001
$cpu->run(2);
ok($cpu->register('A')->get() == ord('C'), "Putting multiple values at once worked too");

$m->poke16(24, 0xC03E);
$m->poke16(26, 0x00DB); # IN A, (00) ; read from 0xC000
$cpu->run(2);
ok($cpu->register('A')->get() == 0, "Port emptied");
