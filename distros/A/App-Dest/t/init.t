use Test2::V0;

use exact;
use File::Basename 'dirname';
use File::Path 'rmtree';
use Test::Output;

use App::Dest;

sub set_state {
    chdir( dirname($0) . '/init' );
    rmtree('.dest');
    open( my $out, '>', 'dest.watch' );
    print $out "actions\n";
    close $out;
}
set_state;


stderr_is(
    sub { App::Dest->init },
    "Created new watch list based on dest.watch file:\n  actions\n",
    'init succeeds',
);

ok( -d '.dest', '.dest created' );
ok( -f '.dest/watch', '.dest/watch created' );

stderr_is( sub {
    try {
        App::Dest->init;
    }
    catch {
        my $e = $_ || $@;
        warn $e;
    };
}, "Project already initialized\n", 'init again fails' );

stderr_is( sub {
    try {
        App::Dest->add('actions');
    }
    catch {
        my $e = $_ || $@;
        warn $e;
    };
}, "Directory actions already added\n", 'no re-add actions' );

ok( lives { App::Dest->rm('actions') }, 'rm actions' ) or note $@;
stdout_is( sub { App::Dest->watches }, '', 'watches (no results)' );
ok( lives { App::Dest->add('actions') }, 'add actions' ) or note $@;

stderr_is( sub {
    try {
        App::Dest->add('not_exists');
    }
    catch {
        my $e = $_ || $@;
        warn $e;
    };
}, "Directory specified does not exist\n", 'no add not exists' );

stdout_is( sub { App::Dest->watches }, "actions\n", 'watches (results)' );
ok( lives { App::Dest->putwatch('dest.watch2') }, 'putwatch' ) or note $@;
stdout_is( sub { App::Dest->watches }, "actions\nactions2\n", 'watches (results) 2' );
ok( lives { App::Dest->writewatch }, 'writewatch' ) or note $@;

open( my $in, '<', 'dest.watch' );
is( join( '', <$in> ), "actions\nactions2\n", 'new dest.watch is correct' );

stdout_like( sub { App::Dest->version }, qr/^dest version [\d\.]+$/, 'version' );

set_state;
done_testing;
