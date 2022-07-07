#! perl

use Test2::V0;
use Test::Lib;

is( $ENV{APP_ENV_SITE}, U(), "No APP_ENV_SITE" );

{
    local %ENV = %ENV;
    require App::Env;
    my $env = App::Env->new( 'App1' );
    is( $env->{Site1_App1}, 1 );
}

is( $ENV{APP_ENV_SITE}, U(), "No APP_ENV_SITE" );

{
    local %ENV = %ENV;
    my $env = App::Env->new( 'App1' );
    is( $env->{App1},       U() );
    is( $env->{Site1_App1}, 1 );
}

is( $ENV{APP_ENV_SITE}, U(), "No APP_ENV_SITE" );

done_testing;
