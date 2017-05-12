use strict;
$^W = 1;

use Test::More tests => 4;

use CPU::Emulator::Memory::Banked;

my $memory = CPU::Emulator::Memory::Banked->new();

my $read_counter = 0;
my %writes = ();
$memory->bank(
    address => 5,
    size    => 5,
    type    => 'dynamic',
    function_read => sub { return $read_counter++; },
    function_write => sub { $writes{$_[1]} = $_[2]; }
);

ok($memory->peek(5) == 0, "Can read  from a 'dynamic' address ...");
ok($memory->peek(5) == 1, "... whose contents are dynamically generated");
$memory->poke(5, 2);
$memory->poke(7,4);
$memory->poke(30, 8);
is_deeply(\%writes, { 7 => 4, 5 => 2 }, "Writes work too");
ok($memory->peek(30) == 8, "Writes outside the dynamic area go to RAM");
