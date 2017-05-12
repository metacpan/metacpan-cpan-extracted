use Test::More tests => 1;

use lib 't';

use App::Env qw( App1 );

ok( $ENV{Site1_App1} == 1, 'use App1' );
