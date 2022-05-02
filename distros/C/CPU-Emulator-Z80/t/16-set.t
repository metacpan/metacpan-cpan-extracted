use strict;
use warnings;

package memory;

use CPU::Emulator::Memory::Banked;
use base qw/CPU::Emulator::Memory::Banked/;

sub peek {
    my $self = shift;
    my $adr = shift;

    return 0xcb if $adr == 0x0000;
    return 0xfc if $adr == 0x0001;
    die "Accessing a location that shouldn't be accessed.";
}

package main;

use Test::More tests => 2;

use CPU::Emulator::Z80;
my $c = CPU::Emulator::Z80->new(memory => memory->new());
$c->register('H')->set(0b00001111);
eval { $c->run(1); };
ok($@ eq "", "the set 7, h instruction didn't dereference HL");
ok($c->register('H')->get() == 0b10001111, "the bit is set correctly");
