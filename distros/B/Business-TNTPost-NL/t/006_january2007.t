# -*- perl -*-
# More random testing

use Test::More tests => 4;

use Business::TNTPost::NL;

my $tnt  = Business::TNTPost::NL->new ();
my $cost = $tnt->calculate(
               country => 'NL',
               weight  => '345',
               register=> 1,
               machine => 1
           );
is($cost, '6.79');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'MK',
               weight  => '1234',
               priority=> 1,
           );
is($cost, '8.69');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'US',
               weight  => '3513',
               large   => 1,
           );
is($cost, '34.30');

$tnt  = Business::TNTPost::NL->new ();
$cost = $tnt->calculate(
               country => 'VA',
               weight  => '666',
               register=> 1
           );
is($cost, '9.48');
