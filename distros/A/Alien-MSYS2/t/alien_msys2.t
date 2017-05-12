use strict;
use warnings;
use Test2::Bundle::Extended;
use Alien::MSYS2;
use Test::Alien;

my $alien = Alien::MSYS2->new;
isa_ok $alien, 'Alien::MSYS2';

alien_ok 'Alien::MSYS2';

is -d Alien::MSYS2->msys2_root, T(), "msys2_root = @{[ Alien::MSYS2->msys2_root ]}";
is -d $_, T(), "bin_dir = $_" for Alien::MSYS2->bin_dir;

done_testing;
