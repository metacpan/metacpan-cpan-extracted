use Test::Most;
use File::Basename 'dirname';
use File::Path 'rmtree';
use Test::Output;
use File::Copy::Recursive 'dircopy';

sub set_state {
    chdir( dirname($0) . '/make' );
    rmtree($_) for ( '.dest', 'actions/003' );
}
set_state();

use_ok('App::Dest');

stderr_is(
    sub { App::Dest->init },
    "Created new watch list based on dest.watch file:\n  actions\n",
    'init succeeds',
);

stdout_is(
    sub { App::Dest->list },
    "actions actions:\n  actions/001\n  actions/002\n",
    'list',
);

stdout_is(
    sub { App::Dest->make( 'actions/003', 'bash' ) },
    "actions/003/deploy.bash actions/003/verify.bash actions/003/revert.bash\n",
    'make bash',
);

ok(
    (
        -f 'actions/003/deploy.bash' and
        -f 'actions/003/verify.bash' and
        -f 'actions/003/revert.bash'
    ),
    'make created files correctly',
);

open( my $out, '>>', 'actions/003/deploy.bash' );
print $out "# dest.prereq: actions/002\n";
close $out;

stdout_is(
    sub { App::Dest->prereqs('actions') },
    "actions/001 has no prereqs\nactions/002 has no prereqs\nactions/003 prereqs:\n  actions/002\n",
    'prereqs',
);

stdout_is(
    sub { App::Dest->make('actions/000') },
    "actions/000/deploy actions/000/verify actions/000/revert\n",
    'make bash',
);

dircopy( 'actions/001', '.dest/actions/001' );
dircopy( 'actions/002', '.dest/actions/002' );
dircopy( 'actions/000', '.dest/actions/000' );
rmtree('actions/000');

open( $out, '>>', '.dest/actions/001/deploy' );
print $out "# change\n";
close $out;

stdout_is(
    sub { App::Dest->status },
    "diff - actions\n  - actions/000\n  actions/001\n    M actions/001/deploy\n  + actions/003\n",
    'status',
);

stdout_like( sub { App::Dest->diff }, qr/\-\# change/, 'diff' );

lives_ok( sub { App::Dest->clean('actions/001') }, 'partial clean' );
stdout_is(
    sub { App::Dest->status },
    "diff - actions\n  - actions/000\n  + actions/003\n",
    'status after partial clean',
);

lives_ok( sub { App::Dest->clean }, 'full clean' );
stdout_is(
    sub { App::Dest->status },
    "ok - actions\n",
    'status after full clean',
);

lives_ok( sub { App::Dest->preinstall }, 'preinstall' );
stdout_is(
    sub { App::Dest->status },
    "diff - actions\n  + actions/001\n  + actions/002\n  + actions/003\n",
    'status after full clean',
);

set_state();
done_testing();
