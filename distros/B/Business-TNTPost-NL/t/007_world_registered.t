# -*- perl -*-
# More random testing

use Test::More tests => 2;

use Business::TNTPost::NL;

my $tnt  = Business::TNTPost::NL->new ();

my $regcost = $tnt->calculate(
           country       => 'GR',
           weight        => '470',
           priority      => 1,
           register      => 1,
           large         => 0,
           machine       => 1,
         );

is($regcost, '9.20');

$regcost = $tnt->calculate(
           country       => 'ID',
           weight        => '470',
           priority      => 1,
           register      => 1,
           large         => 0,
           machine       => 0,
         );
is($regcost, '16.15');
