# -*- perl -*-

use Test::More skip_all => 'The receipt option is no longer valid';

use Business::PostNL;

my $tpg  = Business::PostNL->new ();
my $cost = $tpg->calculate(
               country => 'DE',
               weight  => '250',
               register=> 1,
           );
is($cost, '7.70');

$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'DE',
               weight  => '250',
               register=> 1,
               receipt => 1,
           );
is($cost, '9.10');
