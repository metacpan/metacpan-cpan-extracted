use strict;

use Test::More tests => 12;

use Business::IS::PIN qw< :all >;

for my $m ( 1 .. 12 ) {
    my $kt = Business::IS::PIN->new( sprintf q<09%02d862349>, $m );
    cmp_ok $kt->month, '==', $m;
}






