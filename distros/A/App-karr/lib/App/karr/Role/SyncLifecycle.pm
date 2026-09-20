# ABSTRACT: Role providing sync lifecycle with retry and guard insurance

package App::karr::Role::SyncLifecycle;
our $VERSION = '0.601';
use Moo::Role;
use MooX::Options;
# Loaded without importing, and every call below is qualified: a Moo::Role
# composes every sub in its package into its consumers, imported ones included,
# so an imported user_error would become a method on every syncing command
# (#38). App::karr::Role::Output and App::karr::Role::TaskMutation say the same.
use App::karr::Error ();
use App::karr::SyncGuard;

option quiet => (
    is  => 'ro',
    doc => 'Suppress sync progress and retry messages (errors are still shown)',
    # Every syncing command carries --quiet. Per-command help suppresses it for
    # the same reason --dir is hidden (ticket k276): the page should list what
    # is interesting about THIS command, and --quiet is the same on all of them.
    hidden => 1,
);

option local_only => (
    is  => 'ro',
    default => 0,
    doc => 'Write to the local board refs only; skip the fetch and the push',
    # Left visible where --quiet is hidden (k291). --quiet and --dir are hidden
    # because they are the same uninteresting plumbing on every command; this is
    # a per-invocation behaviour change -- it is exactly how you keep a `karr
    # move`/`edit`/`handoff`/`create` from blocking on an unreachable remote --
    # so the command's own help page is where an agent hitting a transport
    # timeout should find it.
);

# Holds the SyncGuard for the duration of a command so its DESTROY-insurance
# actually spans the command body. sync_before stashes it here; sync_after
# neutralises it after a successful push. Without this the guard returned by
# sync_before was discarded in void context and pushed prematurely (#28).
has _sync_guard => (
    is      => 'rw',
    default => sub { undef },
);



sub sync_pull {
    my ( $self, %opt ) = @_;
    my $git = $self->_sync_git;

    my ($ok) = $self->_sync_attempts( 'Pull', $git,
        sub { $git->pull( undef, %opt ) } );

    # The git error is not repeated here. It was printed above the moment it
    # happened, and embedding a copy in the terminal message meant one failed
    # sync showed the same multi-line git output twice -- under --quiet too,
    # which silences the retry banners and nothing else (#27, #77). This half
    # now matches sync_after, which has always ended on the verdict alone.
    App::karr::Error::user_error(
        "Pull failed after 3 attempts. Nothing was changed.\n"
      . "Run 'karr sync' to retry." ) unless $ok;

    return 1;
}

# The git handle every method here works through. The duck-typed doubles the
# sync tests drive this role with expose it directly; the commands get it from
# App::karr::Role::BoardDiscovery.
sub _sync_git {
    my ($self) = @_;
    return $self->can('git') ? $self->git : $self->store->git;
}

# The retry loop -- the only one. Three attempts, the first silent, the retries
# announced from the second, errors always on STDERR and --quiet silencing the
# announcements but never an error.
#
# $label is 'Pull' or 'Push' and appears in both the banner and the git error
# line, so the wording every existing test pins is produced here and nowhere
# else. Returns ( $ok, $rejected ); $rejected is only ever true when
# check_rejection was asked for.
sub _sync_attempts {
    my ( $self, $label, $git, $attempt, %opt ) = @_;

    my $ok       = 0;
    my $err      = '';
    my $shown    = '';
    my $rejected = 0;
    for my $try ( 1 .. 3 ) {
        # Retry-only: attempt 1 is silent; only announce the actual retries.
        print STDERR "$label retry $try of 3...\n"
          if $try > 1 && !$self->quiet;
        $ok = $attempt->();
        if ($ok) {
            print STDERR "$label succeeded.\n" if $try > 1 && !$self->quiet;
            last;
        }
        # Errors always reach STDERR, even under --quiet (#27). But the same
        # error once per attempt is not three pieces of information, and
        # last_error is multi-line now that a rejection lists a reason per ref
        # (#84) -- three copies of that buries the one thing worth reading. A
        # repeat of what was just printed is dropped; a *different* error still
        # gets its own line.
        $err = 'git ' . lc($label) . ' failed: '
             . ( $git->last_error // 'unknown error' );
        print STDERR "  $err\n" if $err ne $shown;
        $shown = $err;

        if ( $opt{check_rejection} ) {
            # A per-ref rejection is final (#84): the remote was reached and
            # said no, so two more attempts would only collect the same
            # refusal twice more, at a second each, on every writing command.
            # The `can` is for the duck-typed git objects the sync tests drive
            # this role with.
            #
            # Except when the answer was "another push got to this ref first",
            # which is contention and not a refusal: the same refspec lands on
            # the next attempt. That is what the retry loop is for, and
            # skipping it turned a `karr create` that had already written its
            # card into a failed command on every parallel run (#181). Only a
            # push whose rejections are *all* contention is retried, so one
            # protected ref still ends it the way #84 requires.
            $rejected = $git->can('push_rejections')
                     && @{ $git->push_rejections } ? 1 : 0;
            $rejected = 0
              if $rejected && $git->can('push_contention') && $git->push_contention;
            last if $rejected;
        }

        sleep 1 if $try < 3;
    }
    return ( $ok, $rejected );
}


sub sync_before {
    my ( $self, %opt ) = @_;

    # --local-only writes to the board's local refs and never reaches the
    # remote, so the fetch is skipped. The command still writes, so a guard is
    # created for the callers that capture one (Backup/Repair/Unlock call ->done
    # on it), but it is spent immediately: with the push skipped in sync_after,
    # neither the guard's DESTROY nor bin/karr's END-block flush may turn that
    # skip into a push at process teardown.
    $self->sync_pull(%opt) unless $self->local_only;

    # Stash the guard on the object so it outlives sync_before's return and
    # covers the whole command body; sync_after neutralises it on success.
    my $git = $self->_sync_git;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => $self->quiet );
    $guard->done if $self->local_only;
    $self->_sync_guard($guard);
    return $guard;
}


sub sync_after {
    my ($self) = @_;

    # --local-only skipped the fetch and spent the guard in sync_before; skip
    # the push to match, so nothing here reaches the remote. The refs are on the
    # local board, and `karr sync` publishes them once the remote is reachable
    # again.
    return if $self->local_only;

    my $git = $self->_sync_git;

    my ( $ok, $rejected ) = $self->_sync_attempts( 'Push', $git,
        sub { $git->push }, check_rejection => 1 );

    # Neutralise the insurance guard on both outcomes.
    #
    # On success: so its DESTROY does not fire a second, redundant push once
    # the command body returns (#28).
    #
    # On failure: the three attempts the insurance would make have just been
    # made and the error below carries the same "run karr sync" guidance, so
    # leaving the guard armed would only make the END flush in bin/karr (#37)
    # repeat the identical failing push, doubling both the delay and the noise
    # on an already-failing command. On a per-ref rejection the attempts were
    # not spent, but the answer was given (#84), so it holds there too.
    $self->_release_guard;

    return if $ok;

    App::karr::Error::user_error(
        "Push rejected by the remote. Local refs are intact.\n"
      . "The refs above were refused, not lost in transit, so pushing again "
      . "would only be refused again." ) if $rejected;

    App::karr::Error::user_error(
        "Push failed after 3 attempts. Local refs are intact.\n"
      . "Run 'karr sync' to retry." );
}


sub sync_pull_foundation {
    my ($self) = @_;
    my $git = $self->_sync_git;

    my ($ok) = $self->_sync_attempts( 'Pull', $git,
        sub { $git->pull_foundation } );

    App::karr::Error::user_error(
        "Pull of refs/karr-foundation/ failed after 3 attempts.\n"
      . "The board is synced; the fleet namespace is not.\n"
      . "Run 'karr sync' to retry." ) unless $ok;

    return 1;
}


sub sync_push_foundation {
    my ($self) = @_;
    my $git = $self->_sync_git;

    my ( $ok, $rejected ) = $self->_sync_attempts( 'Push', $git,
        sub { $git->push_foundation }, check_rejection => 1 );
    return if $ok;

    App::karr::Error::user_error(
        "Push of refs/karr-foundation/ was rejected by the remote. Local refs "
      . "are intact.\n"
      . "The refs above were refused, not lost in transit, so pushing again "
      . "would only be refused again." ) if $rejected;

    App::karr::Error::user_error(
        "Push of refs/karr-foundation/ failed after 3 attempts. Local refs "
      . "are intact.\n"
      . "Run 'karr sync' to retry." );
}

sub _release_guard {
    my ($self) = @_;
    if ( my $guard = $self->_sync_guard ) {
        $guard->done;
        $self->_sync_guard(undef);
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::SyncLifecycle - Role providing sync lifecycle with retry and guard insurance

=head1 VERSION

version 0.601

=head1 DESCRIPTION

This role provides C<sync_before> and C<sync_after> methods that wrap Git pull
and push operations with retry logic. C<sync_before> creates a
L<App::karr::SyncGuard> and retains it on the object as insurance: if the
command body dies or croaks before C<sync_after> runs, the guard's DESTROY
pushes with 3 retries. Because the guard is held by the role (not by the
caller), commands may call both methods in void context; C<sync_after>
neutralises the guard so it never pushes twice.

Holding the guard on the command object is also why the CLI cannot rely on
DESTROY alone: L<MooX::Cmd>'s command chain keeps that object alive past
F<bin/karr>'s error handler, so on the die path the guard is only reaped in
global destruction, where pushing is forbidden. F<bin/karr> therefore drains
L<App::karr::SyncGuard/flush_armed> from an C<END> block.

Commands that compose this role must also have a C<store> attribute (provided
by L<App::karr::Role::BoardDiscovery>) with a C<git> accessor.

L</sync_pull_foundation> and L</sync_push_foundation> are the same two halves
for C<refs/karr-foundation/*> (#190). They share the retry loop rather than
copying it -- there is exactly one in this file, and every attempt count, retry
banner and C<--quiet> rule is decided in it.

=head2 Local-only mode

The C<--local-only> option (k291) makes a writing command write to the board's
local C<refs/karr/*> and touch the remote in neither direction: L</sync_before>
skips the fetch and L</sync_after> skips the push. It exists for the
multi-board case where a mutating command (C<move>, C<edit>, C<handoff>,
C<create>, and every other command that composes this role) would otherwise
block in the caller's timeout on an unreachable or silent I<configured> remote,
because the fetch and push are inline and each is bounded only by
C<KARR_TRANSPORT_TIMEOUT> per attempt over three attempts.

A board with B<no> configured remote already syncs as a clean no-op -- both
L<App::karr::Git/pull> and L<App::karr::Git/push> return early on C<has_remote>
without a round trip -- so C<--local-only> is not needed there and changes
nothing. It is the reachable-but-slow or unreachable I<configured> remote that
it removes from the command's critical path. The default is unchanged: without
the option the fetch and push run exactly as before. The refs written under
C<--local-only> are canonical local board state; C<karr sync> publishes them
once the remote is reachable again.

=head1 METHODS

=head2 sync_pull

    $self->sync_pull;                          # the ordinary guarded pull
    $self->sync_pull( accept_wipe => 1 );      # karr sync --prune
    $self->sync_pull( accept_foreign => 1 );   # karr sync --accept-foreign-board

Pulls refs from remote with up to 3 attempts, and nothing else. Output is
retry-only: the first attempt is silent, retries are announced from attempt 2
("Pull retry 2 of 3..."), and errors always reach STDERR. C<--quiet>
additionally suppresses the retry announcements but never the errors. Each
distinct error is shown once: neither a repeat of the previous attempt's error
nor the message that ends the command prints it again.

Any named arguments are handed to L<App::karr::Git/pull> unchanged, on every
attempt. That is how C<karr sync>'s two safety valves reach the pull -- and
they are passed only when the caller passes them, so a command that calls this
(or L</sync_before>) bare still gets the wholesale-wipe and board-identity
refusals (#82, #95). Those refusals C<die> out of L<App::karr::Git/pull>
rather than returning false, so they end the pull on the first attempt instead
of being retried: they are the remote's state, not a transport failure.

This is L</sync_before> without the L<App::karr::SyncGuard>, for the one
caller that pulls and is not going to push -- C<karr sync --pull>, where an
armed guard would be a push at process teardown that the flag exists to
prevent. Everything that pulls in order to write calls C<sync_before>.

=head2 sync_before

    $self->sync_before;
    $self->sync_before( accept_wipe => 1 );   # options reach Git::pull

L</sync_pull> plus the insurance: it runs the same retrying pull, forwarding
any named arguments to L<App::karr::Git/pull>, and then creates a
L<App::karr::SyncGuard>, retains it on the object (so it outlives the call and
covers the command body), and also returns it for callers that want to manage
it explicitly. C<sync_after> clears it on a successful push.

Under C<--local-only> (see L</Local-only mode>) the pull is skipped and the
returned guard is handed back already spent, so the callers that call
C<< $guard->done >> on it still get an object and no push can fire at teardown.

=head2 sync_after

    $self->sync_after;  # push with up to 3 attempts

Pushes refs to remote with up to 3 attempts, using the same retry-only output
convention as L</sync_before> (silent first attempt, retries announced from
attempt 2, errors always on STDERR, C<--quiet> silencing only the
announcements). It marks the retained guard done and clears it on both
outcomes: after a successful push there is nothing left to insure, and after a
failed one the guard's three attempts have just been spent, so re-running them
from L<App::karr::SyncGuard/flush_armed> would only repeat the failure.

A push the remote I<rejected> per ref (a pre-receive hook, a protected ref)
is not retried at all: the connection worked and the far side gave its answer,
which the error message carries ref by ref. A rejection that is only
contention -- two pushes racing for the same ref, see
L<App::karr::Git/push_contention> -- is retried like any other transient
failure, because the same refspec lands on the next attempt.

Under C<--local-only> (see L</Local-only mode>) this returns immediately without
pushing: the fetch was skipped and the guard already spent in L</sync_before>,
so the local refs stay put until C<karr sync>.

=head2 sync_pull_foundation

    $self->sync_pull_foundation;

L</sync_pull> for C<refs/karr-foundation/*> -- karr-foundation's shared chain,
run logs and question mailbox (L<App::karr::Foundation::ChainStore>). Same three
attempts, same retry-only output, same C<--quiet> contract, because it is the
same loop; only what it calls differs (L<App::karr::Git/pull_foundation>).

The terminal message is its own, and that is the point: this half runs behind
the board's, so "Nothing was changed" would be a lie about a board that has
just been synced. There are no C<accept_wipe>/C<accept_foreign> options to
forward, because the fleet namespace has neither guard -- see
L<App::karr::Git/pull_foundation>.

C<karr sync> is the only caller. The implicit sync every writing command makes
(L</sync_before>, L</sync_after>) stays board-only: a stale chain costs a
planning round, a stale board costs correctness, and nothing outside the fleet
should pay for a namespace it does not have.

=head2 sync_push_foundation

    $self->sync_push_foundation;

L</sync_after> for C<refs/karr-foundation/*>, minus the
L<App::karr::SyncGuard>: the guard insures a command body that wrote board refs
and died, and nothing in a command body writes this namespace. The rejection
verdict is the same one L</sync_after> uses, contention included, since it is
the same remote answering.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
