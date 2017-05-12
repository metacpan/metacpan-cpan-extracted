# -*- perl -*-

use Test::More tests => 2;

use Business::PostNL;

my $tpg  = Business::PostNL->new ();
my $cost = $tpg->calculate(
               country => 'GB',
               weight  => '250',
           );
is($cost, '5.25');

# UK is not the ISO code, so it should take the same value as, say, Japan
$tpg  = Business::PostNL->new ();
$cost = $tpg->calculate(
               country => 'UK',
               weight  => '250',
           );
is($cost, '5.25');
