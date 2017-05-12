use strict;
$^W = 1;

use Test::More tests => 24;
# FIXME - add tests for flags
print "# when register W appears in these tests, it's just a dummy\n";
print "# register to indicate that IN (C) (0xED70) throws the\n";
print "# result away\n";

use CPU::Emulator::Z80;

my %instrs = (
    0xED40 => 'B',
    0xED48 => 'C',
    0xED50 => 'D',
    0xED58 => 'E',
    0xED60 => 'H',
    0xED68 => 'L',
    0xED70 => 'W', #  IN (C) - throws away result, but sets flags
    0xED78 => 'A'
);

foreach my $instr (keys %instrs) {
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

    $m->poke(0,   0x01);
    $m->poke16(1, 0xC000);
    $m->poke(3, $instr >> 8);
    $m->poke(4, $instr & 0x00FF);
    $cpu->run(2);
    ok($cpu->register($instrs{$instr})->get() == 0, "Read status port says 0 when nothing available for IN $instrs{$instr}, (C)");
    # die($cpu->format_registers());
    
    push @buffer, ord('A'); # put 'A' on port 0xC000
    $m->poke(5,   0x01);   # LD BC, ...
    $m->poke16(6, 0xC000); #        0xC000
    $m->poke(8, $instr >> 8);
    $m->poke(9, $instr & 0x00FF);
    $cpu->run(2);
    ok($cpu->register($instrs{$instr})->get() == 1, "Read status port says number of bytes available");
    $m->poke(10,     0x01); # LD BC, ...
    $m->poke16(11, 0xC001); #        0xC001
    $m->poke(13, $instr >> 8);
    $m->poke(14, $instr & 0x00FF);
    $cpu->run(2);
    ok($cpu->register($instrs{$instr})->get() == ord('A'), "Got right value");
}
