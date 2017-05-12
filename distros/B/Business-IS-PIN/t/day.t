use strict;

use Test::More tests => 31;

use Business::IS::PIN qw< :all >;

for my $d ( 1 .. 31 ) {
    my $kt = Business::IS::PIN->new( sprintf q<%02d02862349>, $d );
    cmp_ok $kt->day, '==', $d;
}






