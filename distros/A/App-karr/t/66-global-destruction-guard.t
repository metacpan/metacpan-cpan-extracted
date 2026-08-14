use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Git;

# Ticket #34: `karr move 1 in-progress` (no --claim) hung forever and grew to
# 53 GB RSS on a 62 GB machine, killable only from outside.
#
# The runaway was NOT in move's validation -- that ran and printed
# "Status 'in-progress' requires --claim" correctly. It was in GLOBAL
# DESTRUCTION afterwards: sync_before stashes an App::karr::SyncGuard on the
# command object, the croak unwinds without releasing it, and the guard is
# therefore only reaped once Perl has begun tearing the process down. Its
# DESTROY then ran a full $git->push, i.e. fresh libgit2 work through
# FFI::Platypus -- whose type parser and FFI::CheckLib's search tables are
# package globals Perl had already freed. FFI::CheckLib re-ran its library
# search against undefined globals and FFI::Platypus::TypeParser::Version1
# recursed without bound at roughly 700 MB/s.
#
# The variable was never repo size or the Git::Libgit2 version (it reproduces
# on 0.005 and on a brand-new empty repo). It was simply: does the repo have a
# remote? Without one, push short-circuits at `return 1 unless has_remote` and
# never touches FFI, which is why the original throwaway board looked clean.
#
# Two guards now stop it: App::karr::Git refuses every native operation once
# ${^GLOBAL_PHASE} is 'DESTRUCT', and SyncGuard::DESTROY reports instead of
# pushing in that phase.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Virtual-memory cap for the child processes below. A healthy karr run needs
# under 200 MB of address space, so 2 GB is ~10x headroom and cannot cause a
# false failure; the regression, if it returns, blows through it in ~3s
# instead of taking the machine down with it.
my $CAP_KB = 2_000_000;

# Run the real CLI under `ulimit -v`, so a returning runaway kills the child
# rather than the test host. Returns undef when the shell cannot set the cap.
sub _run_capped {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $cmd = join ' ', map { my $a = $_; $a =~ s/'/'\\''/g; "'$a'" }
        ( $^X, "-I$ROOT/lib", @argv );
    my $stderr = gensym;
    my $pid = open3(
        undef,
        my $stdout_fh,
        $stderr,
        '/bin/sh',
        '-c',
        "ulimit -v $CAP_KB 2>/dev/null || exit 111; exec $cmd",
    );

    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return undef if $exit == 111;    # platform cannot cap address space
    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _board_repo {
    my (%opt) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    system( 'git', '-C', $repo, 'commit', '-q', '--allow-empty', '-m', 'init' ) == 0
        or die 'git commit failed';

    if ( $opt{remote} ) {
        my $bare = tempdir( CLEANUP => 1 );
        system( 'git', 'init', '-q', '--bare', $bare ) == 0
            or die 'git init --bare failed';
        system( 'git', '-C', $repo, 'remote', 'add', 'origin', $bare ) == 0
            or die 'git remote add failed';
        $opt{bare_out} and ${ $opt{bare_out} } = $bare;
    }

    my $old = getcwd();
    chdir $repo or die "chdir $repo: $!";
    # init first: a write command in a repository without a board is refused
    # (#62), so `create` alone no longer conjures one.
    system( $^X, "-I$ROOT/lib", $BIN, 'init', '--name', 'Guard Board' ) == 0
        or die 'karr init failed';
    system( $^X, "-I$ROOT/lib", $BIN, 'create', 'probe ticket' ) == 0
        or die 'karr create failed';
    chdir $old or die "chdir $old: $!";

    return $repo;
}

# The marker strings the runaway printed. Any of them coming back means the
# global-destruction FFI path is live again.
my $RUNAWAY = qr/Deep recursion|Out of memory|FFI::CheckLib|FFI::Platypus
                |during global destruction|\(in cleanup\)/x;

subtest 'a command that dies after sync_before terminates cleanly (with a remote)' => sub {
    my $repo = _board_repo( remote => 1 );
    my $res  = _run_capped( $repo, $BIN, 'move', '1', 'in-progress' );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform'
        unless $res;

    is $res->{exit}, 1, 'exits 1 (runtime failure) instead of hanging or dying on the cap';
    like $res->{stderr}, qr/requires --claim/,
        'the real validation error is what reaches STDERR';
    unlike $res->{stderr}, $RUNAWAY,
        'no FFI/global-destruction fallout on STDERR';

    # This invocation writes no ref, so it must never advise a sync. The first
    # version of the fix decided that by calling a method on the guard's git
    # object, which global destruction may already have reaped -- measured at
    # 8 spurious warnings in 60 identical runs. Repeat the invocation so a
    # regression to any teardown-order-dependent check shows up here rather
    # than as a suite that fails one run in six.
    my $noisy = 0;
    for ( 1 .. 10 ) {
        my $r = _run_capped( $repo, $BIN, 'move', '1', 'in-progress' );
        $noisy++ if $r->{stderr} =~ /Push skipped/;
    }
    is $noisy, 0,
        'no sync advice in any of 10 runs that died before writing anything';
};

subtest 'same command without a remote is unchanged' => sub {
    my $repo = _board_repo( remote => 0 );
    my $res  = _run_capped( $repo, $BIN, 'move', '1', 'in-progress' );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform'
        unless $res;

    is $res->{exit}, 1, 'exits 1';
    like $res->{stderr}, qr/requires --claim/, 'validation error on STDERR';
    unlike $res->{stderr}, $RUNAWAY, 'no FFI/global-destruction fallout';
};

subtest 'the guard still pushes on the success path' => sub {
    my $bare;
    my $repo = _board_repo( remote => 1, bare_out => \$bare );
    my $res  = _run_capped( $repo, $BIN, 'move', '1', 'in-progress', '--claim', 'test-agent' );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform'
        unless $res;

    is $res->{exit}, 0, 'move succeeds';
    like $res->{stdout}, qr/backlog -> in-progress/, 'move is reported';

    my $refs = `git --git-dir='$bare' for-each-ref --format='%(refname)'`;
    like $refs, qr{refs/karr/tasks/1/data},
        'refusing FFI during global destruction did not break the real push';
};

subtest 'a SyncGuard reaped in global destruction does no git work' => sub {
    my $repo = _board_repo( remote => 1 );

    # Holding the guard in a package variable is exactly what the command
    # object did: it survives to global destruction. Before the fix this
    # either recursed until OOM or emitted "(in cleanup) Can't call method
    # push on an undefined value" -- the insurance silently evaporating.
    # The write makes the expectation order-independent: with a ref pending,
    # the guard must report whether or not Perl has already reaped $GIT.
    my $script = <<'PERL';
use App::karr::Git;
use App::karr::SyncGuard;
our $GIT = App::karr::Git->new( dir => shift );
$GIT->write_ref( 'refs/karr/probe/gd', 'unpushed' );
our $GUARD = App::karr::SyncGuard->new( git => $GIT, quiet => 1 );
print "BODY-DONE\n";
PERL

    my $res = _run_capped( $repo, '-e', $script, $repo );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform'
        unless $res;

    is $res->{exit}, 0, 'child exits 0 rather than being killed by the cap';
    like $res->{stdout}, qr/BODY-DONE/, 'the body ran';
    unlike $res->{stderr}, $RUNAWAY, 'teardown touched no FFI and did not crash';
    like $res->{stderr}, qr/Run 'karr sync'/,
        'the skipped push is reported loudly instead of failing silently';
};

subtest 'the quiet/loud decision never consults the git object' => sub {
    my $repo = _board_repo( remote => 0 );

    # Both children hand the guard a double that cannot answer pending_writes
    # at all, standing in for the reaped $git that global destruction may
    # legitimately leave behind. The outcome must be decided purely by
    # $App::karr::Git::WRITES, so it is identical every run.
    my $preamble = <<'PERL';
use App::karr::Git;
use App::karr::SyncGuard;
{ package DeadGit; sub new { bless {}, shift } }
PERL

    my $quiet = _run_capped( $repo, '-e',
        $preamble . qq{our \$G = App::karr::SyncGuard->new( git => DeadGit->new, quiet => 1 );\n} );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform'
        unless $quiet;

    is $quiet->{exit}, 0, 'unwritten board: child exits cleanly';
    unlike $quiet->{stderr}, qr/Push skipped/,
        'unwritten board stays silent even though the git object is unusable';

    my $loud = _run_capped( $repo, '-e',
        $preamble
      . qq{\$App::karr::Git::WRITES = 1;\n}
      . qq{our \$G = App::karr::SyncGuard->new( git => DeadGit->new, quiet => 1 );\n} );

    is $loud->{exit}, 0, 'written board: child exits cleanly';
    like $loud->{stderr}, qr/Push skipped/,
        'written board reports, without consulting the git object either';
};

subtest 'App::karr::Git refuses native work in the DESTRUCT phase' => sub {
    # Ticket #63: mutating _in_global_destruction to `return 0` left this file
    # green, because SyncGuard's own DESTRUCT check alone satisfies every
    # subtest above. That makes karr's first line of defence -- the one that
    # covers every native call reachable from teardown, not just the guard's --
    # deletable in a refactor with nothing to notice. Pin it on its own.
    is( App::karr::Git::_in_global_destruction(), 0,
        'false during ordinary execution' );

    my $repo = _board_repo( remote => 0 );

    # Assert from inside the real phase. The child prints its findings to
    # STDOUT from a DESTROY that only runs once Perl is tearing down.
    my $script = <<'PERL';
use App::karr::Git;
{ package Probe;
  sub new { bless {}, shift }
  sub DESTROY {
    print "PHASE:${^GLOBAL_PHASE}\n";
    print "GUARD:",   App::karr::Git::_in_global_destruction(), "\n";
    my $git = App::karr::Git->new( dir => $ARGV[0] );
    print "IS_REPO:", $git->is_repo, "\n";
    print "READ:[",   $git->read_ref('refs/karr/tasks/1/data'), "]\n";
    print "WRITE:[",  ( defined $git->write_ref( 'refs/karr/probe/gd2', 'x' ) ? 'defined' : 'undef' ), "]\n";
    print "ERR:",     ( $git->last_error // '' ), "\n";
  }
}
our $P = Probe->new;
print "BODY-DONE\n";
PERL

    my $res = _run_capped( $repo, '-e', $script, $repo );

    plan skip_all => 'shell cannot set `ulimit -v` on this platform' unless $res;

    is $res->{exit}, 0, 'child exits cleanly';
    like $res->{stdout}, qr/^BODY-DONE$/m,     'the body ran';
    like $res->{stdout}, qr/^PHASE:DESTRUCT$/m, 'DESTROY really ran in global destruction';
    like $res->{stdout}, qr/^GUARD:1$/m,        '_in_global_destruction reports the phase';
    like $res->{stdout}, qr/^IS_REPO:0$/m,      'is_repo refuses rather than opening libgit2';
    like $res->{stdout}, qr/^READ:\[\]$/m,      'read_ref returns empty instead of touching FFI';
    like $res->{stdout}, qr/^WRITE:\[undef\]$/m, 'write_ref refuses';
    like $res->{stdout}, qr/^ERR:refused: libgit2/m, 'and says why';
    unlike $res->{stderr}, $RUNAWAY,            'no FFI fallout';

    my $refs = `git -C '$repo' for-each-ref --format='\%(refname)' refs/karr/probe`;
    unlike $refs, qr{refs/karr/probe/gd2}, 'and the refused write really wrote nothing';
};

subtest 'pending_writes counts ref mutations' => sub {
    my $repo = _board_repo( remote => 0 );
    my $git  = App::karr::Git->new( dir => $repo );

    my $before = $git->pending_writes;

    $git->write_ref( 'refs/karr/probe/x', 'hello' );
    is $git->pending_writes, $before + 1, 'write_ref counts';

    $git->delete_ref('refs/karr/probe/x');
    is $git->pending_writes, $before + 2, 'delete_ref counts';
};

done_testing;
