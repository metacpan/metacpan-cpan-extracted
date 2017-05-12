use strict;
$^W = 1;

use Test::More tests => 7;

use CPU::Emulator::Z80;

eval {
    my $cpu = CPU::Emulator::Z80->new(
        ports => 2
    );
};
ok($@, "stupid number of ports is an error");

my $cpu = CPU::Emulator::Z80->new();
my @buffer; my @buffer2;
$cpu->add_output_device(
    address => 0xC000,
    function => sub { push @buffer, shift(); }
);
$cpu->add_output_device(
    address => 0xB000,
    function => sub { push @buffer2, shift(); }
);
$cpu->_put_to_output(0xB000, 1);
$cpu->_put_to_output(0xC000, 2);
ok($buffer[0] == 2 && $buffer2[0] == 1, "default is 65536 outputs");

$cpu = CPU::Emulator::Z80->new(ports => 256);
@buffer = @buffer2 = ();
$cpu->add_output_device(
    address => 0xC000,
    function => sub { push @buffer, shift(); }
);
eval { $cpu->add_output_device(
    address => 0xB000,
    function => sub { push @buffer2, shift(); }
); };
ok($@, "with 256 ports, can't add the same output twice");
$cpu->_put_to_output(0xB000, 1);
$cpu->_put_to_output(0xC000, 2);
is_deeply([\@buffer, \@buffer2], [[1, 2], []],
    "with 256 ports, outputs are duplicated");

@buffer = @buffer2 = ();
$cpu = CPU::Emulator::Z80->new();
$cpu->add_input_device(
    address => 0xC000,
    function => sub { push @buffer, 42; }
);
$cpu->add_input_device(
    address => 0xB000,
    function => sub { push @buffer2, 42; }
);
$cpu->_get_from_input(0xB000);
$cpu->_get_from_input(0xC000);
ok($buffer[0] == 42 && $buffer2[0] == 42, "default is 65536 inputs");

$cpu = CPU::Emulator::Z80->new(ports => 256);
@buffer = @buffer2 = ();
$cpu->add_input_device(
    address => 0xC000,
    function => sub { push @buffer, 42; }
);
eval { $cpu->add_input_device(
    address => 0xB000,
    function => sub { push @buffer2, 42; }
); };
ok($@, "with 256 ports, can't add the same input twice");
$cpu->_get_from_input(0xB000);
$cpu->_get_from_input(0xC000);
is_deeply([\@buffer, \@buffer2], [[42, 42], []],
    "with 256 ports, inputs are duplicated");
