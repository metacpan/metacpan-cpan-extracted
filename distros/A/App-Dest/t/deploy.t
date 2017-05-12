use strict;
use warnings;

use Test::Most;
use File::Path 'mkpath';
use lib 't';
use TestLib qw( t_module t_startup t_teardown t_capture t_action_files );

exit main();

sub main {
    require_ok( t_module() );

    t_startup();
    t_action_files('adt/state');
    t_module->init;
    t_module->add('adt');

    deploy();

    t_teardown();
    done_testing();
    return 0;
}

sub deploy {
    is (
        ( t_capture( sub { t_module->verify } ) )[0],
        "not ok - verify: adt/state\n",
        'verify all existing actions returns false',
    );
    is (
        ( t_capture( sub { t_module->verify('adt/state') } ) )[0],
        "not ok - verify: adt/state\n",
        'verify undeployed action returns false',
    );


    is (
        ( t_capture( sub { t_module->deploy } ) )[2],
        "File to deploy required; usage: dest deploy file\n",
        'deploy without action fails',
    );
    is (
        ( t_capture( sub { t_module->deploy('adt/state') } ) )[0],
        join( "\n",
           'begin - deploy: adt/state',
           'ok - deploy: adt/state',
           'ok - verify: adt/state',
        ) . "\n",
       'deploy with action succeeds',
    );

    is (
        ( t_capture( sub { t_module->verify } ) )[0],
        "ok - verify: adt/state\n",
        'verify all existing actions returns true',
    );
    is (
        ( t_capture( sub { t_module->verify('adt/state') } ) )[0],
        "ok - verify: adt/state\n",
        'verify undeployed action returns true',
    );

    is (
        ( t_capture( sub { t_module->revert } ) )[2],
        "File to revert required; usage: dest revert file\n",
        'revert without action throws error',
    );
    is (
        ( t_capture( sub { t_module->revert('adt/state') } ) )[0],
        join( "\n",
            'begin - revert: adt/state',
            'ok - revert: adt/state',
        ) . "\n",
        'revert with action succeeds',
    );

    t_capture( sub { t_module->deploy('adt/state') } );
    is (
       ( t_capture( sub { t_module->redeploy('adt/state') } ) )[0],
        join( "\n",
           'begin - deploy: adt/state',
           'ok - deploy: adt/state',
           'ok - verify: adt/state',
        ) . "\n",
       'redeploy with action succeeds',
    );

    my $state_file;
    ok( open( $state_file, '<', 'state_adt_state.txt' ) || 0, 'open state_adt_state.txt file' );
    my @lines = <$state_file>;
    is( scalar( grep { /^adt\/state$/ } @lines ), 2, 'redeploy state check passes' );

    is (
        ( t_capture( sub { t_module->revdeploy('adt/state') } ) )[0],
        join( "\n",
            'begin - revert: adt/state',
            'ok - revert: adt/state',
            'begin - deploy: adt/state',
            'ok - deploy: adt/state',
            'ok - verify: adt/state',
        ) . "\n",
        'revdeploy with action succeeds',
    );
}
