use strict;
use warnings;

use Alien::cmake4;
use Test::Alien;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
alien_ok('Alien::cmake4');
ok(my $exe = Alien::cmake4->exe, 'exe');
run_ok([$exe, '--version'])
    ->success
    ->out_like(qr/^cmake\s+version\s+4\.[\d\.]+/);
