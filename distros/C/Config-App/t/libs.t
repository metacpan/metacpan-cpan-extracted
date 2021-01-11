use Test2::V0;
use Config::App;

my ( $obj, $conf );

ok( $obj = Config::App->new( 'config/libs.yaml', 1 ), 'Config::App->new( "libs.yaml", 1 )' );

is(
    $obj->get('libs'),
    [ qw( lib2 lib3 lib4 lib5 lib6 ) ],
    'libs setting is correct',
);

done_testing;
