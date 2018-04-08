#! perl

use Test2::V0;
use Test::Lib;

$ENV{APP_ENV_SITE} = '';

require App::Env;

App::Env::import( 'App1' );

ok( $ENV{App1} == 1, 'import func: empty APP_ENV_SITE; override App::Env::Site' );

done_testing;
