use Test::Most;
use File::Basename 'dirname';
use File::Path 'rmtree';
use Test::Output;
use Try::Tiny;

sub set_state {
    chdir( dirname($0) . '/init' );
    rmtree('.dest');
    open( my $out, '>', 'dest.watch' );
    print $out "actions\n";
    close $out;
}
set_state();

use_ok('App::Dest');

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
        warn $_;
    };
}, "Project already initialized\n", 'init again fails' );

stderr_is( sub {
    try {
        App::Dest->add('actions');
    }
    catch {
        warn $_;
    };
}, "Directory actions already added\n", 'no re-add actions' );

lives_ok( sub { App::Dest->rm('actions') }, 'rm actions' );
stdout_is( sub { App::Dest->watches }, '', 'watches (no results)' );
lives_ok( sub { App::Dest->add('actions') }, 'add actions' );

stderr_is( sub {
    try {
        App::Dest->add('not_exists');
    }
    catch {
        warn $_;
    };
}, "Directory specified does not exist\n", 'no add not exists' );

stdout_is( sub { App::Dest->watches }, "actions\n", 'watches (results)' );
lives_ok( sub { App::Dest->putwatch('dest.watch2') }, 'putwatch' );
stdout_is( sub { App::Dest->watches }, "actions\nactions2\n", 'watches (results) 2' );
lives_ok( sub { App::Dest->writewatch }, 'writewatch' );

open( my $in, '<', 'dest.watch' );
is( join( '', <$in> ), "actions\nactions2\n", 'new dest.watch is correct' );

stdout_like( sub { App::Dest->version }, qr/^dest version [\d\.]+$/, 'version' );

set_state();
done_testing();
