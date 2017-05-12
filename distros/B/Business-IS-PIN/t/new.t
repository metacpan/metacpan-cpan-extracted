use strict;

use Test::More tests => 1;

use Business::IS::PIN;

my $pkg = 'Business::IS::PIN';

my $kt = $pkg->new( qw< 0902862349 > );

isa_ok $kt, $pkg;


