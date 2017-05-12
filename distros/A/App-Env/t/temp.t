#!perl

use Test::More tests => 10;

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
    # now clone a temp of it
    my $app2 = App::Env->new( 'App1', { Temp => 1 } );

    ok( defined $app2, 'temp clone' );

    is( $app2->env('AppEnvTestID'), $$, "verify parent" );

    # and brand it
    $app2->setenv( 'AppEnvTestID' => -$$ );

    is( $app2->env('AppEnvTestID'), -$$, "verify clone" );
    is( $app1->env('AppEnvTestID'), $$, "verify untouched parent" );

    # make sure it hasn't been cached
    ok( ! defined App::Env::retrieve( $app2->cacheid ), 'uncached clone' );

}

# check Temp options
{
    # ensure that SysFatal isn't set
    is( $app1->_opt->{SysFatal}, 0, "parent SysFatal" );

    my $app2 = App::Env->new( 'App1', { Temp => 1, SysFatal => 1 } );
    is( $app2->_opt->{SysFatal}, 1, "clone SysFatal" );

}
