# -*- perl -*-
# More random testing

use Test::More tests => 2;

use Business::PostNL;

my $tnt  = Business::PostNL->new ();

my $regcost = $tnt->calculate(
           country       => 'GR',
           weight        => '470',
           priority      => 1,
           register      => 1,
           large         => 0,
           machine       => 1,
         );

is($regcost, '10.67');

$regcost = $tnt->calculate(
           country       => 'ID',
           weight        => '470',
           priority      => 1,
           register      => 1,
           large         => 0,
           machine       => 0,
         );
is($regcost, '16.00');
