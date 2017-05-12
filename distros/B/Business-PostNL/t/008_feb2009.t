# -*- perl -*-

use Test::More tests => 2;

use Business::PostNL;

my $tpg1  = Business::PostNL->new ();
my $cost1 = $tpg1->calculate(
               country => 'NO',
               weight  => '150',
            );
is($cost1, '5.25');

my $tpg2  = Business::PostNL->new ();
my $cost2 = $tpg2->calculate(
               country => 'NO',
               weight  => '150',
               priority=> 1,
           );
is($cost2, '5.25');
