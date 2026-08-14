# ABSTRACT: Role providing sync lifecycle with retry and guard insurance

package App::karr::Role::SyncLifecycle;
our $VERSION = '0.500';
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
);

# Holds the SyncGuard for the duration of a command so its DESTROY-insurance
# actually spans the command body. sync_before stashes it here; sync_after
# neutralises it after a successful push. Without this the guard returned by
# sync_before was discarded in void context and pushed prematurely (#28).
has _sync_guard => (
    is      => 'rw',
    default => sub { undef },
);



sub sync_before {
    my ($self) = @_;
    my $git = $self->can('git') ? $self->git : $self->store->git;

    my $ok    = 0;
    my $err   = '';
    my $shown = '';
    for my $attempt ( 1 .. 3 ) {
        # Retry-only: attempt 1 is silent; only announce the actual retries.
        print STDERR "Pull retry $attempt of 3...\n"
          if $attempt > 1 && !$self->quiet;
        $ok = $git->pull;
        if ($ok) {
            print STDERR "Pull succeeded.\n" if $attempt > 1 && !$self->quiet;
            last;
        }
        # Errors always reach STDERR, even under --quiet (#27). But the same
        # error once per attempt is not three pieces of information, and
        # last_error is multi-line now that a rejection lists a reason per ref
        # (#84) -- three copies of that buries the one thing worth reading. A
        # repeat of what was just printed is dropped; a *different* error still
        # gets its own line.
        $err = "git pull failed: " . ( $git->last_error // 'unknown error' );
        print STDERR "  $err\n" if $err ne $shown;
        $shown = $err;
        sleep 1 if $attempt < 3;
    }
    # The git error is not repeated here. It was printed above the moment it
    # happened, and embedding a copy in the terminal message meant one failed
    # sync showed the same multi-line git output twice -- under --quiet too,
    # which silences the retry banners and nothing else (#27, #77). This half
    # now matches sync_after, which has always ended on the verdict alone.
    App::karr::Error::user_error(
        "Pull failed after 3 attempts. Nothing was changed.\n"
      . "Run 'karr sync' to retry." ) unless $ok;

    # Stash the guard on the object so it outlives sync_before's return and
    # covers the whole command body; sync_after neutralises it on success.
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => $self->quiet );
    $self->_sync_guard($guard);
    return $guard;
}


sub sync_after {
    my ($self) = @_;
    my $git = $self->can('git') ? $self->git : $self->store->git;

    my $ok       = 0;
    my $err      = '';
    my $shown    = '';
    my $rejected = 0;
    for my $attempt ( 1 .. 3 ) {
        # Retry-only: attempt 1 is silent; only announce the actual retries.
        print STDERR "Push retry $attempt of 3...\n"
          if $attempt > 1 && !$self->quiet;
        $ok = $git->push;
        if ($ok) {
            print STDERR "Push succeeded.\n" if $attempt > 1 && !$self->quiet;
            last;
        }
        # Always shown, never three times over -- see sync_before.
        $err = "git push failed: " . ( $git->last_error // 'unknown error' );
        print STDERR "  $err\n" if $err ne $shown;
        $shown = $err;

        # A per-ref rejection is final (#84): the remote was reached and said
        # no, so two more attempts would only collect the same refusal twice
        # more, at a second each, on every writing command. The `can` is for
        # the duck-typed git objects the sync tests drive this role with.
        $rejected = $git->can('push_rejections')
                 && @{ $git->push_rejections } ? 1 : 0;
        last if $rejected;

        sleep 1 if $attempt < 3;
    }
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

version 0.500

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

=head1 METHODS

=head2 sync_before

    $self->sync_before;

Pulls refs from remote with up to 3 attempts. Output is retry-only: the first
attempt is silent, retries are announced from attempt 2 ("Pull retry 2 of
3..."), and errors always reach STDERR. C<--quiet> additionally suppresses the
retry announcements but never the errors. Each distinct error is shown once:
neither a repeat of the previous attempt's error nor the message that ends the
command prints it again. Creates a L<App::karr::SyncGuard>,
retains it on the object (so it outlives the call and covers the command body),
and also returns it for callers that want to manage it explicitly. C<sync_after>
clears it on a successful push.

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
which the error message carries ref by ref.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
