use strict;
use warnings;

use Test::Most;
use lib 't';
use TestLib qw( t_module t_startup t_teardown t_capture t_action_files );

exit main();

sub main {
    require_ok( t_module() );

    t_startup();
    t_action_files(
        [ 'adt/state_sixth',      'adt_alt/state_fifth',  undef                  ],
        [ 'adt/state_first',      undef,                  'adt_alt/state_second' ],
        [ 'adt/state_fourth',     'adt_alt/state_third',  'adt_alt/state_fifth'  ],
        [ 'adt_alt/state_third',  'adt_alt/state_second', 'adt/state_fourth'     ],
        [ 'adt_alt/state_fifth',  'adt/state_fourth',     'adt/state_sixth'      ],
        [ 'adt_alt/state_second', 'adt/state_first',      'adt_alt/state_third'  ],
    );
    t_module->init;
    t_module->add('adt');
    t_module->add('adt_alt');

    single_prereqs();
    multi_prereqs();
    update();

    t_teardown();
    done_testing();
    return 0;
}

sub single_prereqs {
    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state_first',
            '  + adt/state_fourth',
            '  + adt/state_sixth',
            'diff - adt_alt',
            '  + adt_alt/state_fifth',
            '  + adt_alt/state_second',
            '  + adt_alt/state_third',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions',
    );

    {
        my ( $out, $err, $exp ) = t_capture( sub { t_module->deploy('adt_alt/state_second') } );

        is(
            $out,
            join( "\n",
                'begin - deploy: adt/state_first',
                'ok - deploy: adt/state_first',
                'ok - verify: adt/state_first',
                'begin - deploy: adt_alt/state_second',
                'ok - deploy: adt_alt/state_second',
                'ok - verify: adt_alt/state_second',
            ) . "\n",
            'single deploy with single prereq',
        );

        ok( ! $err, 'no warnings in last command' );
        ok( ! $exp, 'no exceptions in last command' );
    }

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state_fourth',
            '  + adt/state_sixth',
            'diff - adt_alt',
            '  + adt_alt/state_fifth',
            '  + adt_alt/state_third',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions after limited deployment',
    );

    _revert_to_clean();
}

sub _revert_to_clean {
    {
        my ( $out, $err, $exp ) = t_capture( sub { t_module->revert('adt/state_first') } );

        is(
            $out,
            join( "\n",
                'begin - revert: adt_alt/state_second',
                'ok - revert: adt_alt/state_second',
                'begin - revert: adt/state_first',
                'ok - revert: adt/state_first',
            ) . "\n",
            'single revert with single prereq',
        );

        ok( ! $err, 'no warnings in last command' );
        ok( ! $exp, 'no exceptions in last command' );
    }

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state_first',
            '  + adt/state_fourth',
            '  + adt/state_sixth',
            'diff - adt_alt',
            '  + adt_alt/state_fifth',
            '  + adt_alt/state_second',
            '  + adt_alt/state_third',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions after revert',
    );
}

sub multi_prereqs {
    {
        my ( $out, $err, $exp ) = t_capture( sub { t_module->deploy('adt_alt/state_fifth') } );

        is(
            $out,
            join( "\n",
                'begin - deploy: adt/state_first',
                'ok - deploy: adt/state_first',
                'ok - verify: adt/state_first',
                'begin - deploy: adt_alt/state_second',
                'ok - deploy: adt_alt/state_second',
                'ok - verify: adt_alt/state_second',
                'begin - deploy: adt_alt/state_third',
                'ok - deploy: adt_alt/state_third',
                'ok - verify: adt_alt/state_third',
                'begin - deploy: adt/state_fourth',
                'ok - deploy: adt/state_fourth',
                'ok - verify: adt/state_fourth',
                'begin - deploy: adt_alt/state_fifth',
                'ok - deploy: adt_alt/state_fifth',
                'ok - verify: adt_alt/state_fifth',
            ) . "\n",
            'single deploy with multiple prereqs',
        );

        ok( ! $err, 'no warnings in last command' );
        ok( ! $exp, 'no exceptions in last command' );
    }

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state_sixth',
            'ok - adt_alt',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions after revert',
    );

    {
        my ( $out, $err, $exp ) = t_capture( sub { t_module->revert('adt_alt/state_third') } );

        is(
            $out,
            join( "\n",
                'begin - revert: adt_alt/state_fifth',
                'ok - revert: adt_alt/state_fifth',
                'begin - revert: adt/state_fourth',
                'ok - revert: adt/state_fourth',
                'begin - revert: adt_alt/state_third',
                'ok - revert: adt_alt/state_third',
            ) . "\n",
            'single deploy with multiple prereqs',
        );

        ok( ! $err, 'no warnings in last command' );
        ok( ! $exp, 'no exceptions in last command' );
    }

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state_fourth',
            '  + adt/state_sixth',
            'diff - adt_alt',
            '  + adt_alt/state_fifth',
            '  + adt_alt/state_third',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions after revert',
    );

    _revert_to_clean();
}

sub update {
    is(
        ( t_capture( sub { t_module->update } ) )[0],
        join( "\n",
            'begin - deploy: adt/state_first',
            'ok - deploy: adt/state_first',
            'ok - verify: adt/state_first',
            'begin - deploy: adt_alt/state_second',
            'ok - deploy: adt_alt/state_second',
            'ok - verify: adt_alt/state_second',
            'begin - deploy: adt_alt/state_third',
            'ok - deploy: adt_alt/state_third',
            'ok - verify: adt_alt/state_third',
            'begin - deploy: adt/state_fourth',
            'ok - deploy: adt/state_fourth',
            'ok - verify: adt/state_fourth',
            'begin - deploy: adt_alt/state_fifth',
            'ok - deploy: adt_alt/state_fifth',
            'ok - verify: adt_alt/state_fifth',
            'begin - deploy: adt/state_sixth',
            'ok - deploy: adt/state_sixth',
            'ok - verify: adt/state_sixth',
        ) . "\n",
        'update() of clean state',
    );

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'ok - adt',
            'ok - adt_alt',
        ) . "\n",
        'status() of adt/* and adt_alt/* actions after revert',
    );

    t_action_files('adt_new/state');
    my $watch_file;
    ok( open( $watch_file, '>', 'dest.watch' ) or 0, 'write out new dest.watch file' );
    print $watch_file "adt\nadt_alt\nadt_new";
    close $watch_file;

    {
        my ( $out, $err, $exp ) = t_capture( sub { t_module->update } );

        is(
            $err,
            "Added adt_new to the watch list\n",
            'update() based on changed dest.watch file adds new watch',
        );

        is(
            $out,
            join( "\n",
                'begin - deploy: adt_new/state',
                'ok - deploy: adt_new/state',
                'ok - verify: adt_new/state',
            ) . "\n",
            'update() based on changed dest.watch file runs OK',
        );
    }
}
