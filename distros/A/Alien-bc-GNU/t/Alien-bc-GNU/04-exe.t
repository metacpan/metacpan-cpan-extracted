use strict;
use warnings;

use Alien::bc::GNU;
use Test::Alien;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
alien_ok('Alien::bc::GNU');
ok(my $exe = Alien::bc::GNU->exe, 'exe');
run_ok( [ $exe, '--version' ] )
    ->success
    ->out_like(qr/^bc /);
