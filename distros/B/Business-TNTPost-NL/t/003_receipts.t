# -*- perl -*-

use Test::More tests => 2;

use Business::TNTPost::NL;

my $tpg  = Business::TNTPost::NL->new ();
my $cost = $tpg->calculate(
               country => 'DE',
               weight  => '250',
               register=> 1,
           );
is($cost, '9.48');

$tpg  = Business::TNTPost::NL->new ();
$cost = $tpg->calculate(
               country => 'DE',
               weight  => '250',
               register=> 1,
               receipt => 1,
           );
is($cost, '9.48');
