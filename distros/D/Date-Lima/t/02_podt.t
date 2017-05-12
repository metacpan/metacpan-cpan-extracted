
use strict;
use Test;
use Date::Lima qw/beek_date/;

plan tests => 3;

ok( beek_date( "127:34" ), "2h7m34s" );
ok( beek_date("2:46:40" ), "2h46m40s" );
ok( beek_date( 7654321 ),  "2mo4w14h12m1s" );
