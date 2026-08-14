use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Carp qw( croak );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Error qw( user_error clean_error );

# Ticket #77: user-facing errors leaked karr's own source locations, because
# Carp appends " at F<Some/Module.pm> line N." even when the message already
# ends in a newline, and because exceptions from underneath karr (Path::Tiny,
# libgit2, captured git stderr) carry the same suffix plus extra lines.
#
# Probed pre-fix, `karr skill install` into an unwritable directory:
#
#   mkpath failed for .claude/skills/karr: Permission denied at
#   /.../lib/App/karr/Cmd/Skill.pm line 134.
#
# App::karr::Error is the single place that turns such an error into one clean
# line. This file pins the mechanism and its use in App::karr::Cmd::Skill; the
# rest of the sweep -- App::karr::Role::BoardDiscovery, the two sync failures in
# App::karr::Role::SyncLifecycle, App::karr::Foundation, its Runner, and the
# raw Path::Tiny errors from `karr restore` / `backup` / `init` / `context` --
# is pinned in t/120-error-message-sweep.t. App::karr::Git::_ref_error, which
# used to carry its own inline copy of the same reduction, now calls
# clean_error.

subtest 'croak really does ignore the trailing-newline convention' => sub {
    # The premise of the whole ticket. If this ever stops being true, the
    # mechanism below is solving a problem that no longer exists.
    eval { croak "already newline terminated\n" };
    like $@, qr/ at \S+ line \d+/,
        'croak appends a call site even to a newline-terminated message';

    eval { die "already newline terminated\n" };
    is $@, "already newline terminated\n",
        'die honours it, which is why user_error uses die';
};

subtest 'user_error raises exactly the message it was given' => sub {
    eval { user_error('Task 7 not found') };
    is $@, "Task 7 not found\n", 'one line, newline terminated, nothing appended';

    eval { user_error( 'Could not write ', '/some/path', ': ', 'Permission denied' ) };
    is $@, "Could not write /some/path: Permission denied\n", 'parts are concatenated';

    eval { user_error("trailing whitespace and newlines \n\n") };
    is $@, "trailing whitespace and newlines\n", 'trailing whitespace collapses to one newline';

    eval { user_error( 'defined', undef, ' parts only' ) };
    is $@, "defined parts only\n", 'undef parts are dropped';

    eval { user_error('anything') };
    unlike $@, qr/ at \S+ line \d+/, 'no file or line number anywhere in it';
    unlike $@, qr/\.pm/, 'no module path either';
};

subtest 'clean_error reduces an internal error to one line' => sub {
    is clean_error("boom at /some/where/Module.pm line 42.\n"), 'boom',
        'a die string loses its call site';

    is clean_error("boom at /some/where/Module.pm line 42.\n\t...propagated at x line 9.\n"),
        'boom', 'and everything Carp propagated after it';

    is clean_error("first line of git noise\nsecond line\nthird line\n"),
        'first line of git noise', 'a multi-line backend error keeps only its first line';

    is clean_error("no call site here"), 'no call site here', 'a clean message passes through';
    is clean_error(''),      'unknown error', 'an empty error still says something';
    is clean_error("  \n "), 'unknown error', 'so does a whitespace-only one';
};

{
    # Stand-in for a libgit2 exception, which carries its text in ->message.
    package KarrTestErrorObject;
    sub message { return "libgit2 style message at /somewhere/Git.pm line 7.\n" }
}

subtest 'clean_error handles the exception objects karr actually meets' => sub {
    my $pt = eval { path('/nonexistent-karr-test-dir/nope')->slurp_utf8; 1 } ? undef : $@;
    isa_ok $pt, 'Path::Tiny::Error', 'Path::Tiny raised an object';
    like "$pt", qr/ at \S+ line \d+/, 'which stringifies with a call site';
    my $clean = clean_error($pt);
    unlike $clean, qr/ at \S+ line \d+/, 'clean_error strips it';
    unlike $clean, qr/\n/,               'and leaves a single line';
    like $clean, qr/No such file or directory/, 'while keeping the reason';

    # libgit2 raises objects that carry their text in ->message.
    my $obj = bless {}, 'KarrTestErrorObject';
    is clean_error($obj), 'libgit2 style message', 'an object with ->message is read through it';
};

subtest 'karr skill install reports an unwritable target without a source location' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $> == 0;

    my $ROOT = abs_path('.');
    my $home = tempdir( CLEANUP => 1 );
    path($home)->child('.claude/skills')->mkpath;
    chmod 0500, path($home)->child('.claude/skills')->stringify
        or plan skip_all => "cannot chmod the target directory: $!";

    my $old = getcwd();
    chdir $home or die "chdir $home: $!";
    my $errfh = gensym;
    my $pid = open3( undef, my $outfh, $errfh,
        $^X, "-I$ROOT/lib", "$ROOT/bin/karr", 'skill', 'install', '--agent', 'claude-code' );
    my $out = do { local $/; <$outfh> };
    my $err = do { local $/; <$errfh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";
    chmod 0700, path($home)->child('.claude/skills')->stringify;

    isnt $exit, 0, 'the failed install is reported as a failure';
    like $err, qr/Could not write /, 'stderr says what karr could not do';
    like $err, qr/Permission denied/, 'and keeps the reason from the OS';
    unlike $err, qr/ at \S+ line \d+/, 'no "at FILE line N." suffix'
        or diag "stderr was:\n$err";
    unlike $err, qr/Skill\.pm/, 'no karr module path leaks'
        or diag "stderr was:\n$err";
    my @lines = split /\n/, $err;
    is scalar(@lines), 1, 'exactly one line of error'
        or diag "stderr was:\n$err";
};

done_testing;
