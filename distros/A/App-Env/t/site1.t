#! perl

use Test2::V0;

use Test::Lib;

$ENV{APP_ENV_SITE} = 'Site2';

require App::Env;

App::Env::import( 'App1' );

ok( $ENV{Site2_App1} == 1, 'import func: pre-existing APP_ENV_SITE' );

done_testing;
