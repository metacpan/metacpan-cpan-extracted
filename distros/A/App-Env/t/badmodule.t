#! perl

use Test2::V0;
use Test::Lib;

use App::Env;

eval {
     App::Env::import( 'App1' );
     };

ok( ! $@, "import existent module" );

eval {
     App::Env::import( 'BadModule' );
     };

ok( $@, "import non-existent module" );

done_testing;
