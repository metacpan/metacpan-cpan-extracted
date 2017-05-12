# -*- perl -*-

use Test::More tests => 5;

use Business::PostNL;

my $tnt  = Business::PostNL->new ();
my $cost = $tnt->calculate(
               country => 'DE',
               weight  => '1234',
               priority=> 1
           );
is($cost, '9.45');

$tnt  = Business::PostNL->new ();
$cost = $tnt->calculate(
               country => 'NL',
               weight  => '234',
               priority=> 0,
               register=> 1,
               machine => 1
           );
is($cost, '7.71');

$tnt  = Business::PostNL->new ();
$cost = $tnt->calculate(
               country => 'MX',
               weight  => '666',
               priority=> 1,
               register=> 0,
               machine => 0
           );
is($cost, '9.45');

$tnt  = Business::PostNL->new ();
$cost = $tnt->calculate(
               country => 'CH',
               weight  => '6666',
               priority=> 1,
               register=> 1,
               machine => 0
           );
is($cost, undef);
is($Business::PostNL::ERROR, '4666 grams too heavy (max: 2000 gr.)');
