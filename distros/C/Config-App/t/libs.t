use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Config::App';

BEGIN { use_ok(MODULE); }

my ( $obj, $conf );

ok( $obj = MODULE->new( 'config/libs.yaml', 1 ), MODULE . '->new( "libs.yaml", 1 )' );

is_deeply(
    $obj->get('libs'),
    [ qw( lib2 lib3 lib4 lib5 lib6 ) ],
    'libs setting is correct',
);

done_testing;
