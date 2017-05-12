use Test::More tests => 1;

use lib 't';

use App::Env qw( App1 App2 );

ok( $ENV{Site1_App1} == 1 &&
    $ENV{Site1_App2} == 1
    , 'use App1 App2' );
