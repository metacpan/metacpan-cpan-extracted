use strict;
use warnings;

use Test::Most;
use File::Path 'mkpath';
use lib 't';
use TestLib qw( t_module t_startup t_teardown t_capture );

exit main();

sub main {
    require_ok( t_module() );
    t_startup();

    t_module->init;

    add();
    rm();
    make();
    list();
    watches();

    _setup_watch_lists();
    putwatch();
    writewatch();

    t_teardown();
    done_testing();
    return 0;
}

sub add {
    mkpath('atd');

    eval{ t_module->add('atd') };

    ok( !$@, 'add' );
    ok( -d '.dest/atd', 'add() += directory' );
    is_deeply( [ t_module->watch_list ], ['atd'], 'add() -> (watch file)++' );

    throws_ok(
        sub { t_module->add() },
        qr/No directory specified; usage: dest add \[directory\]/,
        'no dir specified',
    );

    throws_ok(
        sub { t_module->add('notexists') },
        qr/Directory specified does not exist/,
        'dir not exists',
    );

    throws_ok(
        sub { t_module->add('atd') },
        qr/Directory atd already added/,
        'dir already exists',
    );
}

sub rm {
    mkpath('atd2');
    t_module->add('atd2');

    eval{ t_module->rm('atd2') };
    ok( !$@, 'rm' );
    ok( ! -d '.dest/atd2', 'rm() -= directory' );
    is_deeply( [ t_module->watch_list ], ['atd'], 'rm() -> (watch file)--' );

    throws_ok(
        sub { t_module->rm() },
        qr/No directory specified; usage: dest rm \[directory\]/,
        'no dir specified for rm',
    );

    throws_ok(
        sub { t_module->rm('untracked') },
        qr/Directory untracked not currently tracked/,
        'dir not tracked',
    );
}

sub make {
    my ( $out, $err, $exp ) = t_capture( sub { t_module->make('atd/state') } );
    ok( ! $exp, 'make' );
    ok( $out eq "atd/state/deploy atd/state/verify atd/state/revert\n", 'make() output correct' );

    throws_ok(
        sub { t_module->make() },
        qr/No name specified; usage: dest make \[path\]/,
        'no name specified for make',
    );
}

sub list {
    mkpath('new');
    t_module->add('new');

    ok( ( t_capture( sub { t_module->list } ) )[0] eq "atd\n  atd/state\nnew\n", 'list (blank)' );
    ok(
        ( t_capture(
            sub { t_module->list('atd/state') }
        ) )[0] eq "atd/state/deploy atd/state/verify atd/state/revert\n",
        'list (action)',
    );

    t_module->rm('new');

    ok( ( t_capture( sub { t_module->list } ) )[0] eq "atd\n  atd/state\n", 'list (again)' );
}

sub watches {
    is( ( t_capture( sub { t_module->watches } ) )[0], "atd\n", 'watches()' );
}

sub _setup_watch_lists {
    my ( $dest_a, $dest_b );
    ok( open( $dest_a, '>', 'dest_a' ) || 0, 'open dest_a file for write' );
    ok( open( $dest_b, '>', 'dest_b' ) || 0, 'open dest_b file for write' );

    mkpath($_) for ( qw( a b c d e ) );
    print $dest_a $_, "\n" for ( qw( a b c ) );
    print $dest_b $_, "\n" for ( qw( b c d e ) );
    close $_ for ( $dest_a, $dest_b );
}

sub putwatch {
    is_deeply( [ t_module->watch_list ], [ qw(atd) ], 'watch_list 1' );

    lives_ok( sub { t_module->add('a') }, 't_module->add("a")' );
    is_deeply( [ t_module->watch_list ], [ qw( a atd ) ], 'watch_list 2' );

    lives_ok( sub { t_module->putwatch('dest_a') }, 'putwatch("dest_a")' );
    is_deeply( [ t_module->watch_list ], [ qw( a b c ) ], 'watch_list 3' );

    lives_ok( sub { t_module->putwatch('dest_b') }, 'putwatch("dest_b")' );
    is_deeply( [ t_module->watch_list ], [ qw( b c d e ) ], 'watch_list 4' );
}

sub _read_watch_file {
    my $watch_file;
    open( my $watch_file, '<', 'dest.watch' ) or die $!;
    my @watch_file = map { chomp; $_ } <$watch_file>;
    return \@watch_file;
}

sub writewatch {
    lives_ok( sub { t_module->putwatch('dest_a') }, 'putwatch("dest_a")' );
    lives_ok( sub { t_module->writewatch }, 'writewatch 1' );
    is_deeply( _read_watch_file(), [ qw( a b c ) ], 'watch file check 1' );

    lives_ok( sub { t_module->putwatch('dest_b') }, 'putwatch("dest_b")' );
    lives_ok( sub { t_module->writewatch }, 'writewatch 2' );
    is_deeply( _read_watch_file(), [ qw( b c d e ) ], 'watch file check 2' );
}
