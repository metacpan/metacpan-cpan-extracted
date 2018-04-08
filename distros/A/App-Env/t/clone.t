#!perl

use Test2::V0;
use Test::Lib;

use App::Env;

#############################################################

my $app1 = App::Env->new( 'App1' );

ok( defined $app1, 'create env' );

# make sure that worked
is( $app1->env('Site1_App1'), 1, "check env" );

# and brand it
$app1->setenv( 'AppEnvTestID' => $$ );

{

    # now clone it
    my $clone = $app1->clone;

    ok( defined $clone, 'cloned env' );

    is( $clone->env('AppEnvTestID'), $$, "check cloned env" );

    # change cloned environment
    $clone->setenv( 'CloneTest' => 1 );

    is( $clone->env('CloneTest'), 1, "check updated cloned env" );

    # and ensure that the parent environment has not been changed

    is( $app1->env('CloneTest'), undef, "check parent env" );

    # and ensure that the clone has a new object id
    isnt( $app1->lobject_id, $clone->lobject_id, "clone object id" );

}

# try a cached clone

{
    my $clone = $app1->clone( { Cache => 1 } );
    ok( defined $clone, 'cached cloned env' );

    # and brand it
    $clone->setenv( 'CloneTest' => 2 );

    # and ensure that the parent environment has not been changed
    is( $app1->env('CloneTest'), undef, "check parent env" );

    # and make sure that the cache id is different
    ok( $clone->cacheid ne $app1->cacheid, "clone cache id" );

    # and retrieve the cached env
    my $retrieve = App::Env::retrieve( $clone->cacheid );

    ok( defined $retrieve, "retrieve cached clone" );

    # and make sure its the correct one.
    is( $retrieve->env('CloneTest'), 2, "check cached cloned env" );
}

done_testing;
