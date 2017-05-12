use strict;
use warnings;

use Test::Most;
use File::Path 'mkpath';
use File::Copy 'copy';
use lib 't';
use TestLib qw( t_module t_startup t_teardown t_capture );

exit main();

sub main {
    require_ok( t_module() );
    t_startup();

    t_module->init;
    mkpath('adt');
    t_module->add('adt');
    t_capture( sub { t_module->make('adt/state') } );

    status();
    diff();

    t_teardown();
    done_testing();
    return 0;
}

sub status {
    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state',
        ) . "\n",
        'status() reports diff',
    );

    copy( '.dest/watch', 'dest.watch' );
    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state',
        ) . "\n",
        'status() reports diff (with watch file)',
    );

    lives_ok( sub { t_module->clean }, 't_module->clean' );
    is( ( t_capture( sub { t_module->status } ) )[0], "ok - adt\n", 'status() reports ok after clean' );

    lives_ok( sub { t_module->preinstall }, 't_module->preinstall' );
    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  + adt/state',
        ) . "\n",
        'status() reports ok after preinstall',
    );

    t_module->clean;

    my $state_deploy;
    ok( open( $state_deploy, '>', 'adt/state/deploy' ) || 0, 'open deploy file for write' );
    print $state_deploy 'new content', "\n";

    is(
        ( t_capture( sub { t_module->status } ) )[0],
        join( "\n",
            'diff - adt',
            '  adt/state',
            '    M adt/state/deploy',
        ) . "\n",
        'status() output correct',
    );

    my $dest_watch;
    ok( open( $dest_watch, '>', 'dest.watch' ) || 0, 'open dest.watch file for write' );
    print $dest_watch 'not_exists_watch', "\n";
    like(
        ( t_capture( sub { t_module->status } ) )[1],
        qr/Diff between current watch list and dest.watch file/,
        'watch list diff warn',
    );
}

sub diff {
    like(
        ( t_capture( sub { t_module->diff } ) )[0],
        qr|--- .dest/adt/state/deploy[^\n]*\n\+\+\+ adt/state/deploy[^\n]*\n\@\@ \-1 \+1 \@\@[^\n]*\n\-[^\n]*\n\+new content|,
        'messy diff appears correct',
    );

    like(
        ( t_capture( sub { t_module->diff('adt') } ) )[0],
        qr|--- .dest/adt/state/deploy[^\n]*\n\+\+\+ adt/state/deploy[^\n]*\n\@\@ \-1 \+1 \@\@[^\n]*\n\-[^\n]*\n\+new content|,
        'messy diff appears correct with path',
    );

    t_module->clean;

    is(
        ( t_capture( sub { t_module->diff } ) )[0],
        undef,
        'clean diff appears correct',
    );
}
