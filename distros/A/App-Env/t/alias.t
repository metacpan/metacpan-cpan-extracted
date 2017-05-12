#!perl
use Test::More tests => 9;

use lib 't';

BEGIN { use_ok('App::Env') };

#############################################################

{
    local %ENV = %ENV;

    # import alias.  Site1 App3 is an alias for Site1 App1
    App::Env::import( 'App3' );
    is( $ENV{Site1_App1}, 1, "import alias" );
}

{
    local %ENV = %ENV;

    # now import it directly. have to use Force to increment
    # the internal counter or it'll be impossible to distinguish
    # between a first time import or a cache
    App::Env::import( 'App1', { Force => 1 } );
    is( $ENV{Site1_App1}, 2, "import original" );
}

{
    local %ENV = %ENV;

    # import nested alias, which also sets AppOpts
    App::Env::import( 'App4', { Force => 1 } );
    is( $ENV{Site1_App1}, 3, "import nested alias" );
    is( $ENV{Alias}, 'App4', "alias w/ AppOpts" );
}

{
    local %ENV = %ENV;

    # import nested alias, which also sets AppOpts,
    # but override AppOpts
    App::Env::import( 'App4', { Force => 1, AppOpts => { Alias => 'None' } } );
    is( $ENV{Site1_App1}, 4, "import nested alias" );
    is( $ENV{Alias}, 'None', "alias w/ overridden AppOpts" );
}


{
    local %ENV = %ENV;

    # import lowercased alias
    App::Env::import( 'app3', { Force => 1 } );
    is( $ENV{Site1_App1}, 5, "import lower case alias" );
}

{
    local %ENV = %ENV;

    # try this with Site ignored
    # import lowercased alias
    delete $ENV{APP_ENV_SITE};
    App::Env::import( 'app1', { Force => 1 } );
    is( $ENV{App1}, 1, "import lower case alias" );
}
