#! perl

use Test2::V0;
use Test::Lib;

require App::Env;

App::Env::import( 'App1' );

ok( $ENV{Site1_App1} == 1, 'import func: use App::Env::Site' );

done_testing;
