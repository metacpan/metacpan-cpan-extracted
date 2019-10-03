use Test::Most;
use File::Basename 'dirname';
use File::Path 'rmtree';
use Test::Output;
use Capture::Tiny 'capture';
use File::Copy::Recursive 'dircopy';

use_ok('App::Dest');

sub set_state {
    chdir( dirname($0) . '/revert' );
    rmtree($_) for ( '.dest', 'actions' );

    open( my $log, '>', 'log' );
    print $log "# log\n";
    close $log;
}
set_state();

my $log;
sub read_log {
    open( my $log, '<', 'log' );
    return join( '', <$log> );
}

dircopy( 'source', 'actions' );

stderr_is(
    sub { App::Dest->init },
    "Created new watch list based on dest.watch file:\n" .
        "  actions\n",
    'init succeeds',
);

stdout_is(
    sub { App::Dest->update('-d') },
    "actions/dest.wrap actions/005/deploy\n" .
        "actions/dest.wrap actions/005/verify\n" .
        "actions/dest.wrap actions/004/deploy\n" .
        "actions/dest.wrap actions/004/verify\n" .
        "actions/dest.wrap actions/001/deploy\n" .
        "actions/dest.wrap actions/001/verify\n" .
        "actions/dest.wrap actions/002/deploy\n" .
        "actions/dest.wrap actions/002/verify\n" .
        "actions/dest.wrap actions/003/deploy\n" .
        "actions/dest.wrap actions/003/verify\n",
    'update dry run',
);

stdout_is(
    sub { App::Dest->update },
    "begin - deploy: actions/005\n" .
        "ok - deploy: actions/005\n" .
        "ok - verify: actions/005\n" .
        "begin - deploy: actions/004\n" .
        "ok - deploy: actions/004\n" .
        "ok - verify: actions/004\n" .
        "begin - deploy: actions/001\n" .
        "ok - deploy: actions/001\n" .
        "ok - verify: actions/001\n" .
        "begin - deploy: actions/002\n" .
        "ok - deploy: actions/002\n" .
        "ok - verify: actions/002\n" .
        "begin - deploy: actions/003\n" .
        "ok - deploy: actions/003\n" .
        "ok - verify: actions/003\n",
    'update',
);

my ( $stdout, $stderr, $exit );
lives_ok(
    sub { ( $stdout, $stderr, $exit ) = capture { App::Dest->revert( 'actions/005', '-d' ) } },
    'dry run revert specific action',
);

like(
    $stdout,
    qr|(?:actions/dest.wrap .dest/actions/00[1-5]/revert\n){5}|,
    'good revert output construction',
);

my $position;
my %order = map { $_ => ++$position } ( $stdout =~ m|/(00[1-5])/|g );

is( $order{'005'}, 5, 'revert action "005" is ordered last' );
ok( ( $order{'004'} >= $order{'003'} ), 'revert action "004" happens after "003"' );
ok( ( $order{'004'} >= $order{'001'} ), 'revert action "004" happens after "001"' );

set_state();
done_testing();
