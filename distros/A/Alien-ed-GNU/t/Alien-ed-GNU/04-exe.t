use strict;
use warnings;

use Alien::ed::GNU;
use Test::Alien;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
alien_ok('Alien::ed::GNU');
ok(my $exe = Alien::ed::GNU->exe, 'exe');
run_ok( [ $exe, '--version' ] )
    ->success
    ->out_like(qr/^GNU ed /);
