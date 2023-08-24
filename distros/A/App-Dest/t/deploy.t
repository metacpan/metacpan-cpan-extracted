use Test2::V0;

use exact;
use File::Basename 'dirname';
use File::Copy 'move';
use File::Copy::Recursive 'dircopy';
use File::Path 'rmtree';
use Test::Output;

use App::Dest;

sub set_state {
    chdir( dirname($0) . '/deploy' );
    rmtree($_) for ( '.dest', 'actions' );

    open( my $log, '>', 'log' );
    print $log "# log\n";
    close $log;
}
set_state;

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

move(    'actions/005', '.dest/actions/005' );
dircopy( 'actions/001', '.dest/actions/001' );
dircopy( 'actions/002', '.dest/actions/002' );

open( my $out, '>>', 'actions/002/deploy' );
print $out "changed\n";
close $out;

stdout_is(
    sub { App::Dest->list },
    "actions actions:\n" .
        "  actions/001\n" .
        "  actions/002\n" .
        "  actions/003\n" .
        "  actions/004\n",
    'list',
);

stdout_is(
    sub { App::Dest->status },
    "diff - actions\n" .
        "  actions/002\n" .
        "    M actions/002/deploy\n" .
        "  + actions/003\n" .
        "  + actions/004\n" .
        "  - actions/005\n",
    'status',
);

stdout_is(
    sub { App::Dest->verify('actions/002') },
    "ok - verify: actions/002\n",
    'verify',
);
$log .= "# log\n" .
    "actions/002/verify\n" .
    "002 verify\n";
is( &read_log, $log, 'log correct after verify' );

stdout_is(
    sub { App::Dest->deploy( 'actions/004', '-d' ) },
    "actions/dest.wrap actions/004/deploy\n" .
        "actions/dest.wrap actions/004/verify\n",
    'deploy dry run',
);

stdout_is(
    sub { App::Dest->deploy('actions/004') },
    "begin - deploy: actions/004\n" .
        "ok - deploy: actions/004\n" .
        "ok - verify: actions/004\n",
    'deploy',
);
$log .= "actions/004/deploy\n" .
    "004 deploy\n" .
    "actions/004/verify\n" .
    "004 verify\n";
is( &read_log, $log, 'log correct after deploy' );

stderr_is( sub {
    try {
        App::Dest->deploy('actions/004');
    }
    catch ($e) {
        warn $e;
    }
}, "Action already deployed\n", 'deploy again fails' );

stdout_is(
    sub { App::Dest->redeploy('actions/004') },
    "begin - deploy: actions/004\n" .
        "ok - deploy: actions/004\n" .
        "ok - verify: actions/004\n",
    'redeploy',
);
$log .= "actions/004/deploy\n" .
    "004 deploy\n" .
    "actions/004/verify\n" .
    "004 verify\n";
is( &read_log, $log, 'log correct after deploy' );

stdout_is(
    sub { App::Dest->revdeploy('actions/004') },
    "begin - revert: actions/004\n" .
        "ok - revert: actions/004\n" .
        "begin - deploy: actions/004\n" .
        "ok - deploy: actions/004\n" .
        "ok - verify: actions/004\n",
    'redeploy',
);
$log .= ".dest/actions/004/revert\n" .
    "004 revert\n" .
    "actions/004/deploy\n" .
    "004 deploy\n" .
    "actions/004/verify\n" .
    "004 verify\n";
is( &read_log, $log, 'log correct after revdeploy' );

stdout_is(
    sub { App::Dest->revert('actions/004') },
    "begin - revert: actions/004\n" .
        "ok - revert: actions/004\n",
    'revert',
);
$log .= ".dest/actions/004/revert\n" .
    "004 revert\n";
is( &read_log, $log, 'log correct after deploy' );

stdout_is(
    sub { App::Dest->update('actions') },
    "begin - revert: actions/002\nok - revert: actions/002\n" .
        "begin - deploy: actions/002\n" .
        "ok - deploy: actions/002\n" .
        "ok - verify: actions/002\n" .
        "begin - deploy: actions/003\n" .
        "ok - deploy: actions/003\n" .
        "ok - verify: actions/003\n" .
        "begin - deploy: actions/004\n" .
        "ok - deploy: actions/004\n" .
        "ok - verify: actions/004\n" .
        "begin - revert: actions/005\n" .
        "ok - revert: actions/005\n",
    'update',
);
$log .= ".dest/actions/002/revert\n" .
    "002 revert\n" .
    "actions/002/deploy\n" .
    "002 deploy\n" .
    "changed\n" .
    "actions/002/verify\n" .
    "002 verify\n" .
    "actions/003/deploy\n" .
    "003 deploy\n" .
    "actions/003/verify\n" .
    "003 verify\n" .
    "actions/004/deploy\n" .
    "004 deploy\n" .
    "actions/004/verify\n" .
    "004 verify\n" .
    ".dest/actions/005/revert\n" .
    "005 revert\n";
is( &read_log, $log, 'log correct after update' );

set_state;
done_testing;
