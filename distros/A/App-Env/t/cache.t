#! perl

use Test2::V0;
use Test::Lib;

use App::Env;
use App::Env::Site1::App1;
use App::Env::Site1::App2;


# cache initial directory
my $env = App::Env->new( 'null' );

sub reset_env {

    %ENV = %{$env};
    App::Env::Site1::App1::reset();
    App::Env::Site1::App2::reset();

    for my $site ( undef, qw[ Site1 Sitee2 ] ) {

        my @site = defined $site ? ( Site => $site ) : ();

        App::Env::uncache( App => 'App1', @site );
        App::Env::uncache( App => 'App2', @site );

    }

}

#############################################################

# check simple caching and uncaching

subtest "Simple" => sub {

    reset_env;

    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 1, "import func 1, cache on" );

    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 1, "import func 2, cache on" );

    App::Env::uncache( App => 'App1' );
    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 2, "import func 2, deleted cache" );

    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 2, "import func 2, cache on" );

    # check that correct site is uncached
    {
        local %ENV = %ENV;
        $ENV{APP_ENV_SITE} = 'Site2';

        App::Env::import( 'App1' );
        is( $ENV{Site2_App1}, 1, "import site2" );

        App::Env::uncache( App => 'App1' );
    }
    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 2, "cache site1 after uncache of site 2" );

};

#############################################################

subtest 'CacheID' => sub {


    reset_env;

    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 1, "import App1, id => default" );

    App::Env::import( 'App1', { CacheID => 'foo' } );
    is( $ENV{Site1_App1}, 2, "import App1, id => 'foo'" );


    # verify that the old one is still cached.
    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 1, "re-import App1, id => default" );

    # and now try for foo again
    App::Env::import( 'App1', { CacheID => 'foo' } );
    is( $ENV{Site1_App1}, 2, "re-import App1, id => 'foo'"  );


    # merge.  should pull in fresh App1
    App::Env::import( 'App1', 'App2' );
    is( $ENV{Site1_App1}, 3, "merge App1 & App2, id => default; check App1" );
    is( $ENV{Site1_App2}, 1, "merge App1 & App2, id => default; check App2" );

    # App1 cache should be untouched
    App::Env::import( 'App1' );
    is( $ENV{Site1_App1}, 1, "re-import App1, id => default" );

    # App2 hasn't been cached, so should increment
    App::Env::import( 'App2' );
    is( $ENV{Site1_App2}, 2, "import App2, id => default" );


    # uncache App2 and import it to increment the counter,
    # then reimport merge to see if it's being cached
    App::Env::uncache( App => 'App2' );
    App::Env::import( 'App2' );
    is( $ENV{Site1_App2}, 3, "uncache App2; import App2, id => default" );

    # now check merge.  should be same as above as it was cached
    App::Env::import( 'App1', 'App2' );
    ok( $ENV{Site1_App1} == 3, "re-import App1 & App2, id => default; check App1" );
    ok( $ENV{Site1_App2} == 1, "re-import App1 & App2, id => default; check App2" );


    # now explicitly delete CacheID foo, and import it to increment counter
    App::Env::uncache( {CacheID => 'foo'} );
    App::Env::import( 'App1', { CacheID => 'foo' } );
    is( $ENV{Site1_App1}, 4, "uncache App1/'foo', import App1/'foo'" );

    App::Env::uncache( All => 1 );
    is( keys %App::Env::EnvCache, 0, "uncache all" );

};


#############################################################
# check Object caching

subtest 'Object caching' => sub {

    reset_env;

    my ( $obj1, $obj2 );

    # get new App1
    $obj1 = App::Env->new( 'App1' );
    is( $obj1->env( 'Site1_App1' ), 1, "method 1, cache on" );

    # make sure that next attempt is cached
    $obj2 = App::Env->new( 'App1' );
    is( $obj2->env( 'Site1_App1' ), 1, "method 2, cache on" );

    # uncache it and get it again
    $obj1->cache( 0 );
    $obj1 = App::Env->new( 'App1' );
    is( $obj1->env( 'Site1_App1' ), 2, "method 1, cache on" );

    # make sure that last one was cached
    $obj1 = App::Env->new( 'App1' );
    is( $obj1->env( 'Site1_App1' ), 2, "method 1, cache on" );

    # merge.  should pull in new App1
    $obj1 = App::Env->new( 'App1', 'App2' );
    ok( $obj1->env( 'Site1_App1' ) == 3 && $obj1->env( 'Site1_App2' ) == 1,
        "obj merge: 1" );

    # merge.  force reload of all apps
    $obj2 = App::Env->new( 'App1', 'App2', { Force => 1 } );
    ok( $obj2->env( 'Site1_App1' ) == 4 && $obj2->env( 'Site1_App2' ) == 2,
        "obj merge: 2" );

    # but obj1 should be the same
    ok( $obj1->env( 'Site1_App1' ) == 3 && $obj1->env( 'Site1_App2' ) == 1,
        "obj merge: 1 check" );
};

done_testing;
