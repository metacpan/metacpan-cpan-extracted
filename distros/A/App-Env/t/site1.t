#! perl

use Test2::V0;

use Test::Lib;

$ENV{APP_ENV_SITE} = 'Site2';

require App::Env;
is( App::Env->new( 'App1' )->env->{Site2_App1},
    1, 'import func: pre-existing APP_ENV_SITE' );

is( App::Env->new( 'App1', { Site => '' } )->env->{App1},
    1, 'override default' );

is( App::Env->new( 'App1', { Site => undef } )->env->{App1},
    1, 'override default' );

$ENV{APP_ENV_SITE} = 'Site1';

is( App::Env->new( 'App1' )->env->{Site2_App1},
    1, 'changing $ENV{APP_ENV_SITE} does nothing' );

done_testing;
