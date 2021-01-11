use Test2::V0;
use Config::App;

my ( $obj, $conf );

ok( $obj = Config::App->new( 'config/preinclude.yaml', 1 ), 'Config::App->new( "preinclude.yaml", 1 )' );
is( $obj->get('answer'), 42, 'preinclude data merge correct' );

done_testing;
