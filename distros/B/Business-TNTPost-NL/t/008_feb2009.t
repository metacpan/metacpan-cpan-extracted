# -*- perl -*-

use Test::More tests => 2;

use Business::TNTPost::NL;

my $tpg1  = Business::TNTPost::NL->new ();
my $cost1 = $tpg1->calculate(
               country => 'NO',
               weight  => '150',
            );
is($cost1, '3.16');

my $tpg2  = Business::TNTPost::NL->new ();
my $cost2 = $tpg2->calculate(
               country => 'NO',
               weight  => '150',
               priority=> 1,
           );
is($cost2, '3.16');
