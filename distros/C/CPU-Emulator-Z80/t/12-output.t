use strict;
$^W = 1;

use Test::More tests => 18;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new();
my $m = $cpu->memory();

my @buffer = ();

$cpu->add_output_device(
    address => 0xC000,
    function => sub { push @buffer, shift(); }
);

$cpu->register('PC')->set(0);
$m->poke(0, 0x01);     # LD BC, ...
$m->poke16(1, 0xC000); #        0xC000
$m->poke16(3, 0xCD3E); # LD A, 0xCD
$m->poke(5, 0xD3);     # OUT (n), A
$m->poke(6, 0);        # n

$cpu->run(3);
ok(@buffer == 1, "One byte was written by OUT (n), A ...");
ok($buffer[0] == 0xCD, "... with the correct value");

$cpu = CPU::Emulator::Z80->new();
$m = $cpu->memory();
$cpu->add_output_device(
    address => 0xC000,
    function => sub { push @buffer, shift(); }
);
my %h = (
    A => 0x79,
    B => 0x41,
    C => 0x49,
    D => 0x51,
    E => 0x59,
    H => 0x61,
    L => 0x69
);
foreach my $r (keys %h) {
    @buffer = ();
    $cpu->register($r)->set($h{$r});
    $cpu->register('BC')->set(0xC000);
    $cpu->register('PC')->set(0);
    $m->poke(0, 0xED);     # OUT (C), ...
    $m->poke(1, $h{$r});   #          r
    $cpu->run(1);
    ok(@buffer == 1, "One byte was written by OUT (C), $r ...");
    ok($buffer[$#buffer] == $cpu->register($r)->get(), "... with the correct value");
    # use Data::Dumper;print Dumper(\@buffer, $cpu->register($r)->get());
}

@buffer = ();
$cpu->register('BC')->set(0xC000);
$cpu->register('PC')->set(0);
$m->poke(0, 0xED);   # OUT (C), ...
$m->poke(1, 0x71);   #          0
$cpu->run(1);
ok(@buffer == 1, "One byte was written by OUT (C), 0 ...");
ok($buffer[$#buffer] == 0, "... with the correct value");
