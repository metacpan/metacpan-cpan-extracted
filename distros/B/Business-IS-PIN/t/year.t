use strict;

use Test::More tests => 3;

use Business::IS::PIN qw< :all >;

my %h = qw< 8 1886 9 1986 0 2086 >;

for my $c ( keys %h ) {
    my $kt = Business::IS::PIN->new( "090286234" . $c );
    cmp_ok $kt->year, '==', $h{ $c }, "$c => $h{ $c } ";
}






