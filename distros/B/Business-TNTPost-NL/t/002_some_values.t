# -*- perl -*-

use Test::More tests => 5;

use Business::TNTPost::NL;

my $tnt  = Business::TNTPost::NL->new ();
my $cost = $tnt->calculate(
               country => 'DE',
               weight  => '1234',
               priority=> 1
           );
is($cost, '8.69');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'NL',
               weight  => '234',
               priority=> 0,
               register=> 1,
               machine => 1 
           );
is($cost, '6.79');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'MX',
               weight  => '666',
               priority=> 1,
               register=> 0,
               machine => 0 
           );
is($cost, '16.15');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'CH',
               weight  => '6666',
               priority=> 1,
               register=> 1,
               machine => 0 
           );
is($cost, undef);
is($Business::TNTPost::NL::ERROR, '4666 grams too heavy (max: 2000 gr.)');
