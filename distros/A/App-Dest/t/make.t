use Test2::V0;

use File::Basename 'dirname';
use File::Copy::Recursive 'dircopy';
use File::Path 'rmtree';
use Test::Output;

use App::Dest;

sub set_state {
    chdir( dirname($0) . '/make' );
    rmtree($_) for ( '.dest', 'actions/003' );
}
set_state;

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
    sub { App::Dest->make( 'actions/003', 'sh' ) },
    "actions/003/deploy.sh actions/003/verify.sh actions/003/revert.sh\n",
    'make sh',
);

ok(
    (
        -f 'actions/003/deploy.sh' and
        -f 'actions/003/verify.sh' and
        -f 'actions/003/revert.sh'
    ),
    'make created files correctly',
);

open( my $out, '>>', 'actions/003/deploy.sh' );
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
    'make',
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

ok( lives { App::Dest->clean('actions/001') }, 'partial clean' ) or note $@;
stdout_is(
    sub { App::Dest->status },
    "diff - actions\n  - actions/000\n  + actions/003\n",
    'status after partial clean',
);

ok( lives { App::Dest->clean }, 'full clean' ) or note $@;
stdout_is(
    sub { App::Dest->status },
    "ok - actions\n",
    'status after full clean',
);

ok( lives { App::Dest->preinstall }, 'preinstall' ) or note $@;
stdout_is(
    sub { App::Dest->status },
    "diff - actions\n  + actions/001\n  + actions/002\n  + actions/003\n",
    'status after full clean',
);

set_state;
done_testing;
