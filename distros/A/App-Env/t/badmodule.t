use Test::More tests => 2;

use lib 't';

use App::Env;

eval {
     App::Env::import( 'App1' );
     };

ok( ! $@, "import existent module" );

eval {
     App::Env::import( 'BadModule' );
     };

ok( $@, "import non-existent module" );
