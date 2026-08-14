use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Git::Native;
use App::karr::Git;
use App::karr::Lock;

# Ticket #119: App::karr::Git::delete_ref answered 0 for two unrelated things --
# "the ref was never there" and "libgit2 refused to remove it" -- so no caller
# could tell a no-op from a failure.
#
# App::karr::Lock::break_lock is the caller that got it wrong, and it is the
# worst one to get wrong: `karr unlock` is the escape hatch for a holder that
# never came back. It set $broke because the ref existed when it looked, not
# because the ref was gone afterwards, so a refused delete was announced as
# "Broke lock on task N (was held by X)" -- and under --json as broken: true --
# while the lock still stood and every other agent stayed shut out of the card.
#
# delete_ref now dies on a refusal, the way delete_ref_cas, write_ref and
# write_ref_cas already did. 0 means "not on the board", never "we could not
# tell". The two callers that must survive a refusal -- delete_refs behind
# `karr destroy` and replace_board_refs behind `karr restore` -- say so by
# catching it, instead of every caller getting the soft answer by default.

sub repo {
    my $dir = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $dir ) == 0            or die "git init failed";
    system( 'git', '-C', $dir, 'config', 'user.email', 'a@karr.test' ) == 0
        or die "git config failed";
    system( 'git', '-C', $dir, 'config', 'user.name', 'agent-a' ) == 0
        or die "git config failed";
    return App::karr::Git->new( dir => $dir );
}

# What libgit2 raises when the removal itself goes wrong -- a permissions
# problem, a corrupt packed-refs -- as opposed to the GIT_ELOCKED /
# GIT_EMODIFIED / GIT_ENOTFOUND family App::karr::Git already treats as
# contention and retries. Injected at the libgit2 boundary so the whole path
# below it is the real one.
sub refusal {
    return Git::Native::Error->new(
        message => 'failed to delete reference: permission denied',
        code    => -1,
        klass   => 4,
    );
}

# Run $code with libgit2 refusing to delete exactly @refs.
sub refusing {
    my ( $refs, $code ) = @_;
    my %refuse = map { $_ => 1 } @$refs;
    my $orig   = \&Git::Native::Repository::reference_delete;
    no warnings 'redefine';
    local *Git::Native::Repository::reference_delete = sub {
        my ( $repo, $name ) = @_;
        die refusal() if $refuse{$name};
        return $orig->(@_);
    };
    return $code->();
}

my $LOCK = 'refs/karr-local/tasks/12/lock';

subtest 'a refused delete is not the answer for a ref that was never there' => sub {
    my $git = repo();
    $git->write_ref( 'refs/karr/tasks/1/data', "one\n" );

    is $git->delete_ref('refs/karr/tasks/404/data'), 0,
        'nothing to delete is still a plain 0, not an exception';

    my $before = App::karr::Git->pending_writes;
    my $err = refusing( ['refs/karr/tasks/1/data'], sub {
        local $@;
        eval { $git->delete_ref('refs/karr/tasks/1/data'); 1 } ? '' : $@;
    } );

    like $err, qr/^karr: could not delete refs\/karr\/tasks\/1\/data: /,
        'a delete libgit2 refused says so instead of answering like a no-op';
    like $err, qr/permission denied/, 'and carries the reason it was given';
    unlike $err, qr/ at \S+ line \d+/, 'as one clean line, not a stack trace';
    ok $git->ref_exists('refs/karr/tasks/1/data'), 'the ref is still there';
    is( App::karr::Git->pending_writes, $before,
        'and a refused delete is still not counted as a write' );
};

subtest 'break_lock cannot announce a lock it did not break' => sub {
    my $git = repo();
    $git->write_ref( $LOCK, "held\@example.com\n" );
    my $lock = App::karr::Lock->new( git => $git );

    my @answer;
    my $err = refusing( [$LOCK], sub {
        local $@;
        eval { @answer = $lock->break_lock(12); 1 } ? '' : $@;
    } );

    like $err, qr/could not delete \Q$LOCK\E/,
        'the refusal reaches `karr unlock` instead of a cheerful (1, $owner)'
        or diag "break_lock returned: @answer";
    ok $git->ref_exists($LOCK), 'and the lock really is still held';
};

subtest 'break_lock still answers for the locks it does clear' => sub {
    my $git  = repo();
    my $lock = App::karr::Lock->new( git => $git );

    my ( $ok, $msg ) = $lock->break_lock(12);
    is $ok,  0,            'no lock at all is reported, not raised';
    is $msg, 'not locked', 'with the message it always gave';

    $git->write_ref( $LOCK, "held\@example.com\n" );
    ( $ok, my $owner ) = $lock->break_lock(12);
    is $ok, 1, 'an ordinary break still succeeds';
    is $owner, 'held@example.com', 'naming the holder';
    ok !$git->ref_exists($LOCK), 'and the lock is gone';
};

subtest 'a lock that went in the same breath is still a broken lock' => sub {
    my $git  = repo();
    my $lock = App::karr::Lock->new( git => $git );

    # Two `karr unlock` runs on one task: the ref is there when this one looks
    # and gone by the time it deletes. delete_ref answers 0 -- nothing to
    # remove -- and that is not a failure: the lock is off the card either way,
    # which is all the caller asked for.
    my $orig = \&App::karr::Git::ref_exists;
    my ( $ok, $owner );
    {
        no warnings 'redefine';
        local *App::karr::Git::ref_exists = sub {
            my ( $self, $ref ) = @_;
            return 1 if $ref eq $LOCK;
            return $orig->(@_);
        };
        ( $ok, $owner ) = $lock->break_lock(12);
    }

    is $ok, 1, 'the lock is reported broken, not raised over';
    ok !$git->ref_exists($LOCK), 'and it is not there';
};

subtest 'delete_refs names the refusal that stopped a destroy' => sub {
    my $git = repo();
    $git->write_ref( "refs/karr/tasks/$_/data", "task $_\n" ) for 1 .. 3;
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );

    my $err = refusing( ['refs/karr/tasks/2/data'], sub {
        local $@;
        eval { $git->delete_refs('refs/karr/'); 1 } ? '' : $@;
    } );

    like $err, qr/could not delete refs\/karr\/tasks\/2\/data/,
        'the ref that refused is named';
    like $err, qr/permission denied/, 'together with why it refused';
    is_deeply [ $git->list_refs('refs/karr/') ], ['refs/karr/tasks/2/data'],
        'and the refusal did not stop the other refs from being cleared';
};

subtest 'restore survives a stray ref that refuses to go' => sub {
    my $git = repo();
    $git->write_ref( 'refs/karr/config',       "board:\n  name: demo\n" );
    $git->write_ref( 'refs/karr/tasks/1/data', "old one\n" );
    $git->write_ref( 'refs/karr/tasks/9/data', "not in the snapshot\n" );

    my %snapshot = (
        'refs/karr/config'       => "board:\n  name: restored\n",
        'refs/karr/tasks/1/data' => "restored one\n",
    );

    my @warned;
    my $ok = refusing( ['refs/karr/tasks/9/data'], sub {
        local $SIG{__WARN__} = sub { push @warned, $_[0] };
        $git->replace_board_refs( \%snapshot );
    } );

    is $ok, 1, 'the restore still reports success -- its data is in place';
    is $git->read_ref('refs/karr/tasks/1/data'), 'restored one',
        'and the snapshot really landed';
    like join( '', @warned ), qr/could not remove refs\/karr\/tasks\/9\/data/,
        'the stray ref that refused is warned about rather than swallowed';
};

done_testing;
