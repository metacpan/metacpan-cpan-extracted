
use strict;
use Test;
use Time::DeltaString qw/delta_string/;

plan tests => 3;

ok( delta_string( "127:34" ), "2h7m34s" );
ok( delta_string("2:46:40" ), "2h46m40s" );
ok( delta_string( 7654321 ),  "2mo4w14h12m1s" );
