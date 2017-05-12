use strict;
$^W = 1;

use Test::More tests => 14;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();
my $m = $cpu->memory();

my @buffer = (42);

$cpu->add_input_device(
    address => 0xC000,
    function => sub { shift(@buffer); }
);

$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0xC000);
$cpu->register('HL')->set(0xD000);
$m->poke16(0, 0xAAED); # IND
$cpu->run(1);
ok($cpu->memory()->peek(0xD000) == 42, "IND pokes (HL)");
ok($cpu->register('HL')->get() == 0xCFFF, "IND decrements HL");
ok($cpu->register('B')->get()  == 0xBF, "IND decrements B");

push @buffer, 42;

$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0xC000);
$cpu->register('HL')->set(0xE000);
$m->poke16(0, 0xA2ED); # INI
$cpu->run(1);
ok($cpu->memory()->peek(0xE000) == 42, "INI pokes (HL)");
ok($cpu->register('HL')->get() == 0xE001, "INI increments HL");
ok($cpu->register('B')->get()  == 0xBF, "INI decrements B");

@buffer = (1, 2);
$cpu = CPU::Emulator::Z80->new();
$m = $cpu->memory();
$cpu->add_input_device(
    address => 0x0200,
    function => sub { my $f = shift(@buffer); die unless($f); $f }
);
$cpu->add_input_device(
    address => 0x0100,
    function => sub { my $f = shift(@buffer); die unless($f); $f }
);
$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0x0200);
$cpu->register('HL')->set(0xC000);
$m->poke16(0, 0xBAED); # INDR
$cpu->run(2);
ok($cpu->memory()->peek(0xC000) == 1, "INDR pokes (HL) ...");
ok($cpu->memory()->peek(0xBFFF) == 2, "... more than once");
ok($cpu->register('HL')->get() == 0xBFFE, "INDR decrements HL");
ok($cpu->register('BC')->get() == 0x0000, "INDR decrements B");

@buffer = (1, 2);
$cpu = CPU::Emulator::Z80->new();
$m = $cpu->memory();
$cpu->add_input_device(
    address => 0x0200,
    function => sub { my $f = shift(@buffer); die unless($f); $f }
);
$cpu->add_input_device(
    address => 0x0100,
    function => sub { my $f = shift(@buffer); die unless($f); $f }
);
$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0x0200);
$cpu->register('HL')->set(0xC000);
$m->poke16(0, 0xB2ED); # INIR
$cpu->run(2);
ok($cpu->memory()->peek(0xC000) == 1, "INIR pokes (HL) ...");
ok($cpu->memory()->peek(0xC001) == 2, "... more than once");
ok($cpu->register('HL')->get() == 0xC002, "INIR increments HL");
ok($cpu->register('BC')->get() == 0x0000, "INIR decrements B");
