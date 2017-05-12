use strict;
$^W = 1;

use Test::More tests => 12;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();
my $m = $cpu->memory();

my @buffer = ();
$cpu->add_output_device(
    address => 0xC000,
    function => sub { push @buffer, shift(); }
);

$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0xC100);
$cpu->register('HL')->set(0xD000);
$m->poke(0xD000, 42);
$m->poke16(0, 0xABED); # OUTD
$cpu->run(1);
ok($buffer[0] == 42, "OUTD outputs");
ok($cpu->register('HL')->get() == 0xCFFF, "OUTD decrements HL");
ok($cpu->register('B')->get()  == 0xC0, "OUTD decrements B");

@buffer = ();
$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0xC100);
$cpu->register('HL')->set(0xD000);
$m->poke(0xD000, 42);
$m->poke16(0, 0xA3ED); # OUTI
$cpu->run(1);
ok($buffer[0] == 42, "OUTI outputs");
ok($cpu->register('HL')->get() == 0xD001, "OUTI increments HL");
ok($cpu->register('B')->get()  == 0xC0, "OUTI decrements B");

$cpu->add_output_device(
    address => 0x0200,
    function => sub { push @buffer, shift(); }
);
$cpu->add_output_device(
    address => 0x0100,
    function => sub { push @buffer, shift(); }
);
$cpu->add_output_device(
    address => 0x0000,
    function => sub { push @buffer, shift(); }
);

@buffer = ();
$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0x0300);
$cpu->register('HL')->set(0xD001);
$m->poke(0xCFFF, 41);
$m->poke(0xD000, 42);
$m->poke(0xD001, 43);
$m->poke16(0, 0xBBED); # OTDR
$cpu->run(3);
is_deeply(\@buffer, [43, 42, 41], "OTDR outputs");
ok($cpu->register('HL')->get() == 0xCFFE, "OTDR decrements HL");
ok($cpu->register('B')->get()  == 0x0, "OTDR decrements B");

@buffer = ();
$cpu->register('PC')->set(0);
$cpu->register('BC')->set(0x0300);
$cpu->register('HL')->set(0xCFFF);
$m->poke(0xCFFF, 41);
$m->poke(0xD000, 42);
$m->poke(0xD001, 43);
$m->poke16(0, 0xB3ED); # OTIR
$cpu->run(3);
is_deeply(\@buffer, [41, 42, 43], "OTIR outputs");
ok($cpu->register('HL')->get() == 0xD002, "OTIR increments HL");
ok($cpu->register('B')->get()  == 0x0, "OTIR decrements B");
