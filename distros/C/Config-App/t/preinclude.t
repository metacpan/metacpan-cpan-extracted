use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Config::App';

BEGIN { use_ok(MODULE); }

my ( $obj, $conf );

ok( $obj = MODULE->new( 'config/preinclude.yaml', 1 ), MODULE . '->new( "preinclude.yaml", 1 )' );
is( $obj->get('answer'), 42, 'preinclude data merge correct' );

done_testing;
