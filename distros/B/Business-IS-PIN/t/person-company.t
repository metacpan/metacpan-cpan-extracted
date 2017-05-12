use strict;

use Test::More tests => 9;

use Business::IS::PIN qw< :all >;

ok( person( '0902862349' ) );
ok( person( '19' ) );
ok( person( '29' ) );
ok( person( '30' ) );
ok( person( '31' ) );
ok( company( '39' ) );
ok( company( '49' ) );
ok( company( '59' ) );
ok( ! company( '69' ) );
