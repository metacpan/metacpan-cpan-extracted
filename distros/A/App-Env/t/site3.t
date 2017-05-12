use Test::More tests => 1;

use lib 't';

$ENV{APP_ENV_SITE} = '';

require App::Env;

App::Env::import( 'App1' );

ok( $ENV{App1} == 1, 'import func: empty APP_ENV_SITE; override App::Env::Site' );
