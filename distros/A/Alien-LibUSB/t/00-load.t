use strict;
use warnings;

use Config;
use Test::More tests => 4;

BEGIN { require_ok('Alien::LibUSB'); }

diag("Testing Alien::LibUSB $Alien::LibUSB::VERSION, Perl $], $^X, OS $^O ($Config{'archname'})");

my $alien = new_ok('Alien::LibUSB');

isa_ok($alien, 'Alien::Base');

can_ok($alien, qw/cflags libs install_type/);
