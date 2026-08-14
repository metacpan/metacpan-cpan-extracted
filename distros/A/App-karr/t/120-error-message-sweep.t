use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Role::SyncLifecycle;
use App::karr::Task;

# Ticket #77, the rest of the sweep that t/81-error-messages.t deliberately left
# alone. Every case below was reproduced against the pre-fix tree, and every
# "no source location" assertion here fails against it:
#
#   $ cd /tmp/not-a-repo && karr list
#   Not a git repository. karr requires Git.
#    at /.../lib/App/karr/Role/BoardDiscovery.pm line 124.
#
#   $ karr restore --input /nonexistent/nope.yml --yes
#   Error open (<:unix) on '/nonexistent/nope.yml': No such file or directory
#    at /.../lib/App/karr/Cmd/Restore.pm line 101.
#
#   $ karr backup --output <unwritable>/x.yml
#   Error spew on '...': ... Permission denied at /.../lib/App/karr/Cmd/Backup.pm line 75.
#
#   $ karr context --write-to <unwritable>/ctx.md
#   Error spew on '...': ... Permission denied at /.../lib/App/karr/Cmd/Context.pm line 213.
#
#   $ karr init --claude-skill        # into an unwritable .claude
#   mkpath failed for .../.claude/skills: Permission denied
#    at /.../lib/App/karr/Cmd/Init.pm line 171.
#
#   $ karr-foundation --config <sequence.yml>
#   Config must be a YAML mapping at /.../lib/App/karr/Foundation.pm line 299.
#
# The rule the whole ticket is about: where karr keeps its source is never the
# reader's problem. What IS their problem -- the path they typed, the reason the
# OS gave, the line and column YAML::XS objected at -- has to survive the fix,
# so each case asserts the useful half is still there.

my $ROOT = abs_path('.');

sub run_bin {
    my ( $bin, $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";
    my $errfh = gensym;
    my $pid = open3( my $in, my $outfh, $errfh, $^X, "-I$ROOT/lib", "$ROOT/bin/$bin", @argv );
    close $in;
    my $out = do { local $/; <$outfh> };
    my $err = do { local $/; <$errfh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $out ? $out : '',
        stderr => defined $err ? $err : '',
    };
}

sub run_karr { return run_bin( 'karr', @_ ) }

sub new_board {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    my $r = run_karr( $repo, 'init' );
    die "karr init failed: $r->{stderr}" unless $r->{exit} == 0;
    return $repo;
}

# An unwritable directory inside $parent, or a skip reason.
sub unwritable_dir {
    my ($parent) = @_;
    my $dir = path($parent)->child('locked');
    $dir->mkpath;
    chmod 0500, "$dir" or return;
    return $dir;
}

my $ROOT_USER = ( $> == 0 );

# ---------------------------------------------------------------------------

subtest 'karr outside a git repository says so and nothing else' => sub {
    my $nowhere = tempdir( CLEANUP => 1 );
    my $r = run_karr( $nowhere, 'list' );

    isnt $r->{exit}, 0, 'the command fails';
    like $r->{stderr}, qr/Not a git repository\. karr requires Git\./,
        'and says what is wrong';
    unlike $r->{stderr}, qr/ at \S+ line \d+/, 'no "at FILE line N." suffix'
        or diag "stderr was:\n$r->{stderr}";
    unlike $r->{stderr}, qr/BoardDiscovery\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";
    is scalar( grep { length } split /\n/, $r->{stderr} ), 1,
        'exactly one line of error'
        or diag "stderr was:\n$r->{stderr}";
};

subtest 'karr restore names the --input it could not read' => sub {
    my $repo = new_board();
    my $missing = path($repo)->child('no-such-backup.yml');
    my $r = run_karr( $repo, 'restore', '--yes', '--input', "$missing" );

    isnt $r->{exit}, 0, 'the restore fails';
    like $r->{stderr}, qr/Could not read \Q$missing\E/, 'the path the user typed is named';
    like $r->{stderr}, qr/No such file or directory/,   'the reason from the OS survives';
    unlike $r->{stderr}, qr/ at \S+ line \d+/, 'no source location'
        or diag "stderr was:\n$r->{stderr}";
    unlike $r->{stderr}, qr/Restore\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";
};

subtest 'karr backup reports an --output it cannot write' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $ROOT_USER;
    my $repo = new_board();
    my $dir = unwritable_dir($repo) or plan skip_all => "cannot chmod: $!";
    my $target = $dir->child('backup.yml');

    my $r = run_karr( $repo, 'backup', '--output', "$target" );
    chmod 0700, "$dir";

    isnt $r->{exit}, 0, 'the backup fails';
    like $r->{stderr}, qr/Could not write \Q$target\E/, 'the target is named';
    like $r->{stderr}, qr/Permission denied/,           'the reason survives';
    unlike $r->{stderr}, qr/ at \S+ line \d+/, 'no source location'
        or diag "stderr was:\n$r->{stderr}";
    unlike $r->{stderr}, qr/Backup\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";
};

subtest 'karr context --write reports an unwritable parent directory' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $ROOT_USER;
    my $repo = new_board();
    my $dir = unwritable_dir($repo) or plan skip_all => "cannot chmod: $!";
    my $target = $dir->child('context.md');

    my $r = run_karr( $repo, 'context', '--write-to', "$target" );
    chmod 0700, "$dir";

    isnt $r->{exit}, 0, 'the write fails';
    like $r->{stderr}, qr/Could not write \Q$target\E/, 'the target is named';
    like $r->{stderr}, qr/Permission denied/,           'the reason survives';
    unlike $r->{stderr}, qr/ at \S+ line \d+/, 'no source location'
        or diag "stderr was:\n$r->{stderr}";
    unlike $r->{stderr}, qr/Context\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";
};

subtest 'karr context --write still overwrites a read-only target file' => sub {
    plan skip_all => 'running as root: a read-only file is still writable'
        if $ROOT_USER;
    # Named in ticket #77 as the case that must NOT start failing: spew renames
    # a temp file into place, so the mode of the existing file is irrelevant --
    # only the directory has to be writable. Guarding the write must not turn
    # this into an error.
    my $repo = new_board();
    my $target = path($repo)->child('ctx.md');
    $target->spew_utf8("previous content\n");
    chmod 0400, "$target" or plan skip_all => "cannot chmod: $!";

    my $r = run_karr( $repo, 'context', '--write-to', "$target" );

    is $r->{exit}, 0, 'the write succeeds' or diag "stderr was:\n$r->{stderr}";
    like $target->slurp_utf8, qr/kanban-md context/, 'and the context really landed';
};

subtest 'karr init --claude-skill reports an unwritable .claude' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $ROOT_USER;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    my $claude = path($repo)->child('.claude');
    $claude->mkpath;
    chmod 0500, "$claude" or plan skip_all => "cannot chmod: $!";

    my $r = run_karr( $repo, 'init', '--claude-skill' );
    chmod 0700, "$claude";

    isnt $r->{exit}, 0, 'the install fails';
    like $r->{stderr}, qr/Could not create /,  'karr says what it could not do';
    like $r->{stderr}, qr/Permission denied/,  'the reason survives';
    unlike $r->{stderr}, qr/ at \S+ line \d+/, 'no source location'
        or diag "stderr was:\n$r->{stderr}";
    unlike $r->{stderr}, qr/Init\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";
};

subtest 'karr-foundation reports a broken config without leaking its own source' => sub {
    my $tmp = tempdir( CLEANUP => 1 );

    my $broken = path($tmp)->child('broken.yml');
    $broken->spew_utf8("foo: [unclosed\n");
    my $r = run_bin( 'karr-foundation', $tmp, '--config', "$broken" );
    isnt $r->{exit}, 0, 'an unparseable config fails the run';
    like $r->{stderr}, qr/Cannot parse config \Q$broken\E/, 'the config is named';
    # clean_error would keep only "YAML::XS::Load Error: The problem:" and throw
    # the diagnostic away, so this one passes the parser's own message through.
    like $r->{stderr}, qr/line: 2, column: 1/,
        "YAML::XS's line and column survive -- they are the whole point";
    unlike $r->{stderr}, qr/Foundation\.pm/, 'no karr module path'
        or diag "stderr was:\n$r->{stderr}";

    my $seq = path($tmp)->child('sequence.yml');
    $seq->spew_utf8("- a\n- b\n");
    my $s = run_bin( 'karr-foundation', $tmp, '--config', "$seq" );
    isnt $s->{exit}, 0, 'a config that is not a mapping fails the run';
    like $s->{stderr}, qr/Config must be a YAML mapping/, 'and says why';
    unlike $s->{stderr}, qr/ at \S+ line \d+/, 'no source location'
        or diag "stderr was:\n$s->{stderr}";
    unlike $s->{stderr}, qr/Foundation\.pm/, 'no karr module path'
        or diag "stderr was:\n$s->{stderr}";
};

# ---- the sync half: one call site gone, one copy of the git error ----------

{
    # Fails every pull with a distinctive multi-line error, the shape a per-ref
    # rejection has had since #84.
    package FailingGit;
    sub new { bless {}, shift }
    sub pull { 0 }
    sub push { 0 }
    sub push_rejections { [] }
    sub last_error {
        "the remote 'origin' refused the push:\n"
      . "    refs/karr/tasks/1/data: DISTINCTIVE-REASON"
    }
}

{
    package SyncBoard;
    use Moo;
    use MooX::Options;
    with 'App::karr::Role::SyncLifecycle';
    has git => ( is => 'ro', required => 1 );
}

sub capture_stderr {
    my ($code) = @_;
    my $buf = '';
    my $err;
    {
        local *STDERR;
        open STDERR, '>', \$buf or die "cannot redirect STDERR: $!";
        $err = do { local $@; eval { $code->(); 1 } ? undef : $@ };
    }
    return ( $buf, $err );
}

sub count_of {
    my ( $text, $needle ) = @_;
    my $n = 0;
    $n++ while $text =~ /\Q$needle\E/g;
    return $n;
}

subtest 'a failed sync carries no call site into its terminal message' => sub {
    for my $which (qw( sync_before sync_after )) {
        my ( undef, $err ) = capture_stderr( sub {
            SyncBoard->new( git => FailingGit->new, quiet => 1 )->$which;
        } );
        ok defined $err, "$which fails";
        unlike $err, qr/ at \S+ line \d+/, "$which raises no source location"
            or diag "exception was:\n$err";
        unlike $err, qr/\.pm/, "$which names no module path"
            or diag "exception was:\n$err";
    }
};

subtest 'the git error is printed once for the whole sync, not once more at the end' => sub {
    # Pre-fix, sync_before embedded a copy of the same multi-line git error in
    # its croak, so bin/karr printed it a second time under the user's nose --
    # the loop's own deduplication (#84) only ever covered attempts 2 and 3.
    for my $quiet ( 0, 1 ) {
        my ( $stderr, $err ) = capture_stderr( sub {
            SyncBoard->new( git => FailingGit->new, quiet => $quiet )->sync_before;
        } );
        my $seen_by_user = $stderr . ( defined $err ? $err : '' );

        is count_of( $seen_by_user, 'DISTINCTIVE-REASON' ), 1,
            "quiet=$quiet: everything the user sees carries the reason exactly once"
            or diag "output was:\n$seen_by_user";
        like $seen_by_user, qr/DISTINCTIVE-REASON/,
            "quiet=$quiet: --quiet never suppresses the error itself (#27)";
        like $err, qr/Pull failed after 3 attempts/,
            "quiet=$quiet: the verdict is still there";
    }
};

subtest 'a save on an unpersisted ref-backed task keeps its croak' => sub {
    # Deliberately NOT swept: this one is a programming error, so the call site
    # is the useful part of the message (ticket #77 says so in as many words).
    my $task = App::karr::Task->new( id => 1, title => 'nowhere' );
    eval { $task->save };
    like $@, qr/ref-backed tasks must be persisted/, 'it still refuses';
    like $@, qr/ at \S+ line \d+/,
        'and still names the caller, because that is who has to fix it';
};

done_testing;
