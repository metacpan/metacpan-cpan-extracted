use strict;
$^W = 1;

use Test::More tests => 40;

use CPU::Emulator::Z80;

my $cpu = CPU::Emulator::Z80->new(
    memory => CPU::Emulator::Memory->new(size => 4000)
);
ok($cpu->memory()->isa('CPU::Emulator::Memory') &&
   !$cpu->memory()->isa('CPU::Emulator::Memory::Banked'),
   "pass in a memory object and it gets used");

$cpu = CPU::Emulator::Z80->new();
ok($cpu->memory()->isa('CPU::Emulator::Memory::Banked'),
   "default memory type is Banked");

foreach (qw(A B C D E F R HL IX IY PC SP A_ B_ C_ D_ E_ F_ HL_ I)) {
    ok($cpu->register($_)->get() == 0, "register $_ defaults to 0");
}

ok(CPU::Emulator::Z80->new(init_B => 3)->register('B')->get() == 3,
   "initialising registers at power-on works");

my $v = 0x0A;
foreach (qw(A B C D E F R HL IX IY PC SP A_ B_ C_ D_ E_ F_ HL_ I)) {
    $cpu->register($_)->set($v++);
}
$v = 0x0A;
is_deeply(
    $cpu->registers(),
    { map { $_ => $v++ } qw(A B C D E F R HL IX IY PC SP A_ B_ C_ D_ E_ F_ HL_ I) },
    "registers() method works"
);
    
ok($cpu->register('AF')->get() == 0x0A0F, "register-pair AF get()s OK");
ok($cpu->register('BC')->get() == 0x0B0C, "register-pair BC get()s OK");
ok($cpu->register('DE')->get() == 0x0D0E, "register-pair DE get()s OK");
ok($cpu->register('H')->get() == 0x00, "half-register H get()s OK");
ok($cpu->register('L')->get() == 0x11, "half-register L get()s OK");
ok($cpu->register('HIX')->get() == 0x00, "half-register HIX get()s OK");
ok($cpu->register('LIX')->get() == 0x12, "half-register LIX get()s OK");
ok($cpu->register('HIY')->get() == 0x00, "half-register HIY get()s OK");
ok($cpu->register('LIY')->get() == 0x13, "half-register LIY get()s OK");
ok($cpu->register('AF_')->get() == 0x161B, "register-pair AF_ get()s OK");
ok($cpu->register('BC_')->get() == 0x1718, "register-pair BC_ get()s OK");
ok($cpu->register('DE_')->get() == 0x191A, "register-pair DE_ get()s OK");
ok($cpu->register('H_')->get() == 0x00, "half-register H_ get()s OK");
ok($cpu->register('L_')->get() == 0x1C, "half-register L_ get()s OK");

my $status = $cpu->status();
$cpu = CPU::Emulator::Z80->new();
$cpu->status($status);
$v = 0x0A;
is_deeply(
    $cpu->registers(),
    { map { $_ => $v++ } qw(A B C D E F R HL IX IY PC SP A_ B_ C_ D_ E_ F_ HL_ I) },
    "status() serialises and restores correctly ..."
);
ok($cpu->status() eq $status, "... and round-trips");
