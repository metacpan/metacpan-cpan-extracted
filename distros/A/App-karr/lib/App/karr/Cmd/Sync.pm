# ABSTRACT: Sync karr board with remote

package App::karr::Cmd::Sync;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use feature 'say';
use MooX::Options (
    usage_string => 'USAGE: karr sync [--push] [--pull] [--prune] [--accept-foreign-board]',
);
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';


option push => ( is => 'ro', default => 0, doc => 'Push refs to remote' );
option pull => ( is => 'ro', default => 0, doc => 'Pull refs from remote' );
option prune => (
    is      => 'ro',
    default => 0,
    doc     => 'Accept a pull that deletes every remaining board ref',
);
option accept_foreign_board => (
    is      => 'ro',
    default => 0,
    doc     => 'Accept a pull whose remote presents a different board identity',
);

sub execute {
    my ( $self, $args, $data ) = @_;

    my $git = $self->git;

    unless ( $git->is_repo ) {
        say "Not a git repository. Skipping sync.";
        return;
    }

    my $email = $git->git_user_email;
    my $name = $git->git_user_name;
    unless ($email) {
        say q(No git user.email configured. Run: git config --global user.email 'you@example.com');
        return;
    }

    say "User: $name <$email>";

    my $push_only = $self->push && !$self->pull;
    my $pull_only = $self->pull && !$self->push;

    # Both halves go through App::karr::Role::SyncLifecycle, which this command
    # has composed all along (via App::karr::Role::BoardAccess) without using.
    # It called $git->pull and $git->push exactly once each and died on a false
    # return -- so the command every failed sync is pointed at ("Run 'karr sync'
    # to retry") was the one command with no retry and no idea what contention
    # is, while #181 had already taught the role and the insurance push to spend
    # their three attempts on a push another push had merely beaten to a ref
    # (#183). Nothing is duplicated here: the retry-only output, the "errors
    # always on STDERR, --quiet silences only the banners" contract, and the
    # refusal-versus-contention verdict all live in the role.
    unless ($push_only) {
        print STDERR "Pulling refs/karr/ from remote...\n" unless $self->quiet;
        # --prune is the one place that may reconcile the board down to
        # nothing, and --accept-foreign-board the one place that may adopt a
        # remote whose board identity is not this board's; everywhere else
        # App::karr::Git refuses and says so (#82, #95). The role forwards both
        # to App::karr::Git::pull unchanged, on every attempt -- neither is ever
        # implied, and a retry does not quietly widen what was allowed.
        my @accept = (
            accept_wipe    => $self->prune,
            accept_foreign => $self->accept_foreign_board,
        );
        # sync_before is sync_pull plus a SyncGuard, and a guard left armed is
        # a push at process teardown -- exactly what --pull says not to do. So
        # the pull-only form takes the pull without the insurance.
        $pull_only ? $self->sync_pull(@accept) : $self->sync_before(@accept);
    }

    unless ($pull_only) {
        print STDERR "Pushing refs/karr/ to remote...\n" unless $self->quiet;
        $self->sync_after;
    }

    # The fleet namespace, second and in the same command (#190).
    #
    # In `karr sync` rather than in a command of its own: this is the command
    # every failed sync, every runbook and every skill doc already points at,
    # and a second one would be a second thing to remember whose failure mode
    # is silent -- a chain that quietly plans against a board it has not seen,
    # a run log no other machine can read. The ticket's counter-argument, that
    # coordination state has a different lifetime from board state, is real and
    # is spent elsewhere: the implicit sync every writing command makes
    # (sync_before/sync_after) stays board-only, so nothing outside this
    # explicitly-typed command pays for the fleet namespace.
    #
    # Second rather than first, and never on its own: the fleet namespace has
    # no board-identity check and no wholesale-wipe refusal of its own
    # (App::karr::Git/pull_foundation says why). It does not need them here,
    # because the board's run first, in this same command, against this same
    # remote -- a re-created origin, an edited remote URL or a swapped clone is
    # refused up there and this half never runs. Putting it first, or offering
    # a flag that runs it alone, would quietly remove that protection.
    unless ($push_only) {
        print STDERR "Pulling refs/karr-foundation/ from remote...\n"
          unless $self->quiet;
        $self->sync_pull_foundation;
    }

    unless ($pull_only) {
        # Silent and free where there is nothing to publish: push_foundation
        # returns without a round trip when this clone holds no fleet refs and
        # has no unpublished deletion, which is every repository that is not
        # the hub.
        print STDERR "Pushing refs/karr-foundation/ to remote...\n"
          unless $self->quiet;
        $self->sync_push_foundation;
    }

    say "Done.";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Sync - Sync karr board with remote

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr sync
    karr sync --pull
    karr sync --push

=head1 DESCRIPTION

Synchronises the C<refs/karr/*> namespace with the configured remote. Without
flags it fetches the remote ref state and then pushes the local ref state back,
plus one delete refspec for every ref this clone deleted and has not published
yet -- read off the tombstones under C<refs/karr-local/deleted/> -- so
destructive restore operations are mirrored correctly. The push itself does not
prune: a remote ref this clone has never seen is another agent's card, not a
leftover, and pruning it is how a card was lost outright
(L<App::karr::Git/push>).

It then does the same for C<refs/karr-foundation/*>, karr-foundation's shared
chain, run logs and question mailbox (L<App::karr::Foundation::ChainStore>) --
one command for both, because a second one would be a second thing to forget
and forgetting it is silent. The board half runs first and this half never runs
alone: the board's identity and wholesale-wipe refusals are what protects the
fleet namespace against a swapped remote, since it carries neither of its own
(L<App::karr::Git/pull_foundation>). C<--pull>, C<--push> and C<--quiet> apply
to both halves; C<--prune> and C<--accept-foreign-board> are board-only,
because they answer refusals only the board makes. A clone with nothing under
C<refs/karr-foundation/> and no unpublished deletion there pushes nothing, so
this costs an ordinary board repository one fetch and no push.

Both halves run through L<App::karr::Role::SyncLifecycle>, so this command
retries exactly as every writing command does: up to three attempts each, the
first silent and the retries announced from the second, errors always on
STDERR, and C<--quiet> silencing the progress lines and the retry
announcements but never an error. A push the remote refused ref by ref is
I<not> retried -- the far side gave its answer -- unless the refusal was only
contention, two pushes racing for the same ref, which the next attempt wins
(L<App::karr::Git/push_contention>). This is the command karr points every
failed sync at, and until #183 it was the only one that pushed once and gave
up.

=head1 OPTIONS

=over 4

=item * C<--pull>

Only fetches remote C<refs/karr/*>.

=item * C<--push>

Only pushes local C<refs/karr/*> state to the configured remote.

=item * C<--prune>

Accepts a reconciliation that would delete every remaining board ref. Any
other command refuses that and stops, because "the remote deliberately
dropped the board" and "the remote is empty for the wrong reason" -- a
re-created origin, an edited remote URL, a rolled-back hosting-side restore --
look exactly alike from here. Use it to let a C<karr destroy> performed on
another clone take effect on this one; check C<git remote -v> first.

=item * C<--accept-foreign-board>

Accepts a pull whose remote presents a different board identity than the one
this clone has been syncing with. Any other pull refuses that before
reconciling anything, because a swapped remote -- a re-initialised origin, an
edited remote URL, a stale clone pointed at the wrong repository -- would
otherwise replace this board with a stranger's, silently and totally. Use it
when the remote's board really is the one you want from now on; check
C<git remote -v> first.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Board>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Restore>

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
