use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use YAML::XS ();

use App::karr::Foundation;
use App::karr::Git;
use App::karr::Task;

# ---------------------------------------------------------------------------
# Ticket #168: Foundation::_sync_pull aborts the whole run when one repo's
# pull refuses.
#
# The wholesale-wipe guard, the board-identity guard, and (since #154) the
# unapplied-refs guard all die from the pull rather than returning false.
# Until this fix _sync_pull was called bare from _process_repo, so any of
# those three refusals escaped up to the outer try in run() and the rest of
# the run proceeded from there -- which is fine for "warn and keep going"
# but means _process_repo is no longer throwing at the level it is supposed
# to handle internally. Lock release, an explicit skip signal, a clean
# separation between the per-repo pull step and the per-repo drain step --
# all of that lives one level down, in the same pattern _drain_repo already
# uses, and the pull sat just outside it.
#
# The fix wraps the pull in its own try block inside _process_repo, the
# same shape as _drain_repo's. A pull that refuses warns, skips the rest
# of _process_repo for that board, and lets the surrounding run() loop
# continue to the next repo. The drain is never reached for a board whose
# pull failed, so the agent never runs against a board that is not at the
# version the pull was supposed to bring in.
# ---------------------------------------------------------------------------

# Tiny shell helper that croaks on failure. Foundation regression tests use
# system() at the top level and ignore the exit code; here we want any
# `git init` / `git clone` / `git config` failure to abort the test, the
# same way the canonical t/30-foundation.t helpers do.
sub _sys { system(@_) == 0 or die "system @_: $?" }

# The failure mode this is all about: a .lock file in refs/karr/tasks/N/
# left behind by a killed karr. libgit2's reference_create refuses to take
# the ref while it is there, exactly as if another karr were holding the
# lock right now -- the same shape the unapplied-refs guard rejects with.
sub _stale_lock {
    my ( $dir, $ref ) = @_;
    my $path = "$dir/.git/$ref.lock";
    my ( $parent ) = $path =~ m{^(.*)/[^/]+$};
    make_path($parent);
    open my $fh, '>', $path or die "cannot create $path: $!";
    close $fh;
    return $path;
}

sub _task {
    my ( $id, $title ) = @_;
    return App::karr::Task->new(
        id       => $id,
        title    => $title,
        status   => 'todo',
        priority => 'high',
        class    => 'standard',
    );
}

# Foundation run with a captured $SIG{__WARN__} so the test can assert on
# what the run complained about. Returns ( $exit, \@warnings ).
sub _run_capturing {
    my ( $cfg_path, %opts ) = @_;
    my $f = App::karr::Foundation->new( config => $cfg_path, %opts );
    my @warnings;
    my $exit = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $f->run;
    };
    return ( $exit, \@warnings );
}

# -- Test 1: pull that refuses on one board is skipped, the other runs ---------
subtest 'a pull that refuses on one board does not abort the run' => sub {
    # Two clones, both starting from the same board; B publishes an edit,
    # so A holds the stale OID by the time the lock is planted. Without the
    # wrap the pull dies out of _sync_pull, the outer try in run() catches
    # it, and the loop moves on to B -- the board-isolation had to live
    # somewhere, and the fix moves it down to where _drain_repo's lives.
    my $work   = tempdir( CLEANUP => 1 );
    my $remote = "$work/origin";
    _sys( 'git', '-C', $work, 'init', '-q', '--bare', "$remote.git" );

    my $a = "$work/a";
    my $b = "$work/b";
    _sys( 'git', 'clone', '-q', "$remote.git", $a );
    _sys( 'git', 'clone', '-q', "$remote.git", $b );
    _sys( 'git', '-C', $a, 'config', 'user.email', 'a@karr.test' );
    _sys( 'git', '-C', $a, 'config', 'user.name',  'agent-a' );
    _sys( 'git', '-C', $b, 'config', 'user.email', 'b@karr.test' );
    _sys( 'git', '-C', $b, 'config', 'user.name',  'agent-b' );

    # A puts the board up.
    my $git_a = App::karr::Git->new( dir => $a );
    $git_a->write_config_ref( { board => { name => 'Test Board' } } );
    $git_a->save_task_ref( _task( 1, 'Original title' ) );
    ok $git_a->push, 'A publishes the board';

    # B syncs it in, then edits and pushes -- after which A's local is the
    # board with the OLD OID, B's local is the board with the NEW OID, and
    # the remote holds the NEW.
    my $git_b = App::karr::Git->new( dir => $b );
    ok $git_b->pull, 'B syncs the board in';
    my $edited = $git_b->load_task_ref(1);
    $edited->title('IMPORTANT EDIT FROM B');
    $git_b->save_task_ref($edited);
    ok $git_b->push, 'B publishes an edit';

    # The lock a killed karr would have left behind. Planted on A because A
    # holds the stale OID -- exactly the shape the unapplied-refs guard
    # refuses, which is the third trigger added by #154.
    my $lock = _stale_lock( $a, 'refs/karr/tasks/1/data' );

    # Sanity-check the setup itself: the lock really does refuse A's pull,
    # independently of any foundation behaviour. This is what the foundation
    # code is about to encounter, and the test would be hollow if it did not.
    my $rv = eval { App::karr::Git->new( dir => $a )->pull };
    ok !$rv,        'A pull refuses on the stale lock';
    like $@, qr/could not apply the remote's version/,
        'and the refusal names the unapplied-refs shape the fix is about';

    # Wire both boards into the foundation. Sentinel files prove whether
    # the agent command ever reached the shell -- A's must not, B's must.
    path("$a/.karr")->spew_utf8(
        "command: touch $a/__sentinel_a__\n"
        . "on_idle: always-run\n"
        . "max_runtime: 5\n" );
    path("$b/.karr")->spew_utf8(
        "command: touch $b/__sentinel_b__\n"
        . "on_idle: always-run\n"
        . "max_runtime: 5\n" );

    my $cfg_dir = tempdir( CLEANUP => 1 );
    my $cfg     = path("$cfg_dir/config.yml");
    $cfg->spew_utf8( "dirs:\n  - $a\n  - $b\n" );

    my ( $exit, $warnings ) = _run_capturing( "$cfg", force => 1 );

    is $exit, 0, 'foundation run exits 0 even when one pull refuses';
    ok !path("$a/__sentinel_a__")->exists,
        'board A was skipped -- its pull refused, so the agent never ran';
    ok path("$b/__sentinel_b__")->exists,
        'board B was processed normally -- the run continued past A';

    # The warning is the per-repo catch's report. Its content is karr's own
    # error text, surfaced at the foundation level, so the operator can see
    # which board refused and why. It is not the generic "something died"
    # message a bare die would have produced.
    my $a_warned = grep { index( $_, $a ) >= 0 } @$warnings;
    ok $a_warned, 'a warning was emitted naming the failing repo';
    like $warnings->[0], qr/could not apply the remote's version/,
        'and the warning carries the underlying pull refusal, not just a stack trace';

    # Clean up the lock so the test exit is tidy even if the assertions fail
    # partway through -- otherwise the next test sees a half-set-up board.
    unlink $lock;
};

# -- Test 2: pull is wrapped at the same level as _drain_repo -----------------
#
# Pinning the structure: _process_repo isolates its own pull, the same way
# it isolates _drain_repo. Without the fix, the pull from inside _process_repo
# is unprotected -- a refusal from any of the three guards dies out of the
# function. With the fix, _process_repo handles the pull locally and returns
# cleanly, so the calling run() loop never sees a die from that path at all.
subtest '_process_repo: a failing pull is isolated, the rest of the function is not entered' => sub {
    # Same setup as the first subtest, but driven through _process_repo
    # directly so the test can prove the wrap is inside the function, not
    # only at the run() boundary.
    my $work   = tempdir( CLEANUP => 1 );
    my $remote = "$work/origin";
    _sys( 'git', '-C', $work, 'init', '-q', '--bare', "$remote.git" );

    my $a = "$work/a";
    my $b = "$work/b";
    _sys( 'git', 'clone', '-q', "$remote.git", $a );
    _sys( 'git', 'clone', '-q', "$remote.git", $b );
    _sys( 'git', '-C', $a, 'config', 'user.email', 'a@karr.test' );
    _sys( 'git', '-C', $a, 'config', 'user.name',  'agent-a' );
    _sys( 'git', '-C', $b, 'config', 'user.email', 'b@karr.test' );
    _sys( 'git', '-C', $b, 'config', 'user.name',  'agent-b' );

    my $git_a = App::karr::Git->new( dir => $a );
    $git_a->write_config_ref( { board => { name => 'Test Board' } } );
    $git_a->save_task_ref( _task( 1, 'Original title' ) );
    $git_a->push;

    my $git_b = App::karr::Git->new( dir => $b );
    $git_b->pull;
    my $edited = $git_b->load_task_ref(1);
    $edited->title('IMPORTANT EDIT FROM B');
    $git_b->save_task_ref($edited);
    $git_b->push;

    my $lock = _stale_lock( $a, 'refs/karr/tasks/1/data' );

    # A sentinel the agent command would touch if _process_repo reached the
    # drain. After the fix, _process_repo returns early on the pull failure
    # and the agent never runs -- the sentinel is the test's witness for
    # "the rest of the function was not entered".
    path("$a/.karr")->spew_utf8(
        "command: touch $a/__sentinel_a__\n"
        . "on_idle: always-run\n"
        . "max_runtime: 5\n" );

    my $f = App::karr::Foundation->new();
    my @warnings;
    my $died = !do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        eval { $f->_process_repo( path($a) ); 1 };
    };

    ok !$died, '_process_repo returns cleanly instead of dying on a refused pull';
    ok !path("$a/__sentinel_a__")->exists,
        'and the agent command was not invoked -- the board was skipped';
    ok scalar @warnings, 'and the refusal was reported as a warning, not a die';

    unlink $lock;
};

done_testing;
