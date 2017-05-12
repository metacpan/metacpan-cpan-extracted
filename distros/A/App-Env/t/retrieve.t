#!perl

use Test::More tests => 6;

use lib 't';

BEGIN { use_ok('App::Env') };

#############################################################


my $app1 = App::Env->new( 'App1' );

ok( defined $app1, 'create env' );

# make sure that worked
is( $app1->env('Site1_App1'), 1, "check env" );

# and brand it
$app1->setenv( 'AppEnvTestID' => $$ );

{
    # now retrieve it
    my $app2 = App::Env::retrieve( $app1->cacheid );

    ok( defined $app2, 'retrieve env' );

    is( $app2->env('AppEnvTestID'), $$, "retrieve env" );
}

{
    # try retrieving something that doesn't exist
    my $app2 = App::Env::retrieve( 'Say What?' );

    ok( ! defined $app2, 'retrieve non-existent env' );
}
