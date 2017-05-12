# -*- perl -*-

use Test::More tests => 6;

use Business::PostNL;

my $tpg  = Business::PostNL->new ();
my $cost = $tpg->calculate(
               country => 'PL',
               weight  => '345',
               register=> 1
           );
is($cost, '11.00');

$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '11337',
               priority=> 1,
               large   => 1
           );
is($cost, '12.90');

$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '31337',
               priority=> 1,
               large   => 1
           );

is($cost, undef);
is($Business::PostNL::ERROR, '1337 grams too heavy (max: 30000 gr.)');

$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '1337',
               large   => 1
           );
is($cost, '6.75');

$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'NL',
               weight  => '2337',
               priority=> 1,
               large   => 1
           );
is($cost, '6.75');
