# -*- perl -*-

use Test::More tests => 3;

use Business::TNTPost::NL;

my $tpg  = Business::TNTPost::NL->new ();
my $cost = $tpg->calculate(
               country => 'PL',
               weight  => '345',
               register=> 1
           );
is($cost, '9.48');

$tpg  = Business::TNTPost::NL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '11337',
               priority=> 1,
               large   => 1
           );
is($cost, '12.20');

$tpg  = Business::TNTPost::NL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '1337',
               priority=> 1,
               large   => 1
           );
is($cost, '6.75');
