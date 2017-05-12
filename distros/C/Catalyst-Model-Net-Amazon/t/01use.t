use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 3;

use_ok('TestApp');

my $amazon = TestApp->model('Amazon');

isa_ok( $amazon, 'Net::Amazon' );
can_ok( $amazon, 'search' );

1;
