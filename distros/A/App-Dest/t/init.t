use strict;
use warnings;

use Test::Most;
use File::Path qw( mkpath rmtree );
use lib 't';
use TestLib qw( t_module t_startup t_teardown t_capture );

exit main();

sub main {
    require_ok( t_module() );

    basic();
    watch_file();

    done_testing();
    return 0;
}

sub basic {
    t_startup();

    eval{ t_module->init };
    ok( !$@, 'init' );

    ok( -d '.dest', 'init() += directory' );
    ok( -f '.dest/watch', 'init() += watch file' );

    throws_ok( sub { t_module->init }, qr/Project already initialized/, 'project already initialized' );

    t_teardown();
}

sub watch_file {
    t_startup();

    my $dest_watch;
    ok( open( $dest_watch, '>', 'dest.watch' ) || 0, 'open dest.watch file for write' );

    for ( qw( a b c ) ) {
        mkpath($_);
        print $dest_watch $_, "\n";
    }
    close $dest_watch;

    is(
        ( t_capture( sub { t_module->init } ) )[1],
        "Created new watch list based on dest.watch file:\n  a\n  b\n  c\n",
        'init with dest.watch',
    );

    ok( -f '.dest/watch', 'init() += watch file with dest.watch' );
    ok( -d '.dest', 'init() += directory with dest.watch' );

    t_teardown();
}
