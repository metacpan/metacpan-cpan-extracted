use Test::More tests => 1;

use lib 't';

require App::Env;

App::Env::import( 'App1' );

ok( $ENV{Site1_App1} == 1, 'import func: use App::Env::Site' );
