# ABSTRACT: Push guard with automatic retry on scope exit

package App::karr::SyncGuard;
our $VERSION = '0.500';
use Moo;
use strict;
use warnings;
use Scalar::Util qw( refaddr weaken );
use App::karr::Git;


# Process-wide registry of armed guards, keyed by refaddr with weakened values
# so a guard that is released normally is not kept alive here. done() and
# DESTROY deregister, flush_armed() drains. In practice a karr process holds at
# most one guard; this is a registry rather than a single slot only because
# nothing guarantees that, and a stale single slot would push the wrong guard.
our %ARMED;

sub BUILD {
    my ($self) = @_;
    my $key = refaddr $self;
    $ARMED{$key} = $self;
    weaken $ARMED{$key};
    return;
}

has git => (
    is       => 'ro',
    required => 1,
);

has _done => (
    is       => 'rw',
    default  => 0,
);

has quiet => (
    is      => 'ro',
    default => 0,
);

has _errors => (
    is       => 'ro',
    default  => sub { [] },
);


sub done {
    my ($self) = @_;
    $self->{_done} = 1;
    delete $ARMED{ refaddr $self };
    return;
}


sub flush_armed {
    my ($class) = @_;

    # Drain first: whatever happens below, these guards have been dealt with,
    # and a guard freed mid-loop must not leave a dangling registry key.
    my @guards = grep { defined } values %ARMED;
    %ARMED = ();

    return 0 unless $App::karr::Git::WRITES;

    my $flushed = 0;
    for my $guard (@guards) {
        next if $guard->{_done};
        $flushed++;
        eval { $guard->_insurance_push; 1 }
          or warn 'Push insurance failed: ' . ( $@ || 'unknown error' );
        # Spent either way: on failure _insurance_push has already warned with
        # the "run karr sync" guidance, so DESTROY must not report it again.
        $guard->{_done} = 1;
    }
    return $flushed;
}


sub errs {
    my ($self) = @_;
    return @{$self->{_errors}};
}

sub DESTROY {
    my ($self) = @_;

    # A guard only reaped during global destruction cannot push. By then Perl
    # is destroying blessed objects in no defined order, and App::karr::Git's
    # libgit2/FFI layer is explicitly not re-entrant in that phase -- attempting
    # it recursed until the machine was out of memory (#34). Report instead of
    # pushing; the refs are still on disk.
    #
    # Reaching this at all means nobody called flush_armed (#37) -- the CLI
    # does, from an END block, so this is the embedder's last resort.
    #
    # Nothing here may touch $self->{git}: it is a blessed object and may
    # already have been reaped, which is exactly what made this branch
    # nondeterministic before. $App::karr::Git::WRITES is a plain package
    # scalar, still readable throughout this phase, so "the body died before
    # writing anything" is decided on real state rather than on teardown order.
    # %ARMED is likewise left alone here: deregistering from a hash the same
    # teardown is freeing buys nothing when the process is already ending.
    if ( ${^GLOBAL_PHASE} eq 'DESTRUCT' ) {
        return if $self->{_done};
        return unless $App::karr::Git::WRITES;
        warn "Push skipped: karr exited before the board was pushed.\n"
          . "Local refs are intact. Run 'karr sync' to push them.\n";
        return;
    }

    delete $ARMED{ refaddr $self };
    return if $self->{_done};
    $self->_insurance_push;
    return;
}

# The insurance push itself: up to 3 attempts, retry-only output (#27), never
# fatal. Shared by DESTROY and flush_armed so the die path behaves identically
# whether the guard is released by scope exit or drained at process teardown.
sub _insurance_push {
    my ($self) = @_;

    my $git  = $self->git;
    my $ok   = 0;
    my $err  = '';

    for my $attempt ( 1 .. 3 ) {
        # Retry-only (#27): the first attempt is silent; only announce retries,
        # and honour --quiet. Errors and the final guidance are always shown.
        print STDERR "Push retry $attempt of 3...\n"
          if $attempt > 1 && !$self->{quiet};
        $ok = $git->push;
        if ($ok) {
            $self->{_done} = 1;
            return 1;
        }
        # Native Git::Native/libgit2 ops set no shell exit code; the failure
        # detail lives in $git->last_error (see App::karr::Git).
        $err = "git push failed: " . ( $git->last_error // 'unknown error' );
        push @{$self->{_errors}}, $err;
        print STDERR "  $err\n";

        # A push the far side refused ref by ref is not a lost connection: the
        # remote was reached and gave its answer, so the other two attempts
        # would collect the same refusal twice more, a second apart, on a
        # command that has already died. App::karr::Role::SyncLifecycle stops
        # on the same signal (#84); this path is the one that runs *after* a
        # command failed, so reporting the least here was backwards (#96).
        #
        # The `can` is for the duck-typed git objects the sync tests drive this
        # class with, and matches how SyncLifecycle asks the same question.
        last if $git->can('push_rejections') && @{ $git->push_rejections };

        sleep 1 if $attempt < 3;
    }

    # Never die() here: DESTROY typically runs while another exception unwinds
    # the stack, where a die is turned into a swallowed "(in cleanup)" warning
    # (or lost entirely during global destruction), masking this message. Warn
    # so the guidance always reaches STDERR.
    #
    # Which guidance depends on what failed. "Run 'karr sync' to retry" is only
    # true when retrying can work; after a refusal it sends the user to a
    # command that will be refused identically, and says nothing about the one
    # thing they need to know -- that the remote, not the network, said no. The
    # per-ref reasons are in the error printed just above.
    warn $self->_rejected
      ? "Push rejected by the remote. Local refs are intact.\n"
        . "The refs above were refused, not lost in transit, so pushing again "
        . "would only be refused again.\n"
      : "Push failed after 3 attempts. Local refs are intact.\n"
        . "Run 'karr sync' to retry.\n"
        . "Errors: " . join( ', ', $self->errs ) . "\n";
    return 0;
}

# Whether the last push failed because the remote refused refs, rather than
# because it could not be reached.
sub _rejected {
    my ($self) = @_;
    my $git = $self->git;
    return 0 unless $git && $git->can('push_rejections');
    my $rejected = $git->push_rejections;
    return $rejected && @$rejected ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::SyncGuard - Push guard with automatic retry on scope exit

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    my $guard = $self->sync_before;  # git pull + return guard
    # ... command logic ...
    $self->sync_after;               # explicit push
    $guard->done;                    # mark guard as done (DESTROY no-ops)
    undef $guard;

    # If die/croak happens before sync_after:
    # Guard DESTROY retries the push 3 times, then warns with a clear error

    # Process teardown, from F<bin/karr>'s END block:
    App::karr::SyncGuard->flush_armed;

=head1 DESCRIPTION

L<App::karr::SyncGuard> is created by L<App::karr::Role::SyncLifecycle/sync_before>.
It acts as an insurance policy: if the command body dies or croaks before
L<App::karr::Role::SyncLifecycle/sync_after> is called explicitly, the guard's
DESTROY runs sync_after with retry logic, ensuring refs are pushed even on failure.

That works whenever the guard is released while the interpreter is still whole
-- a lexical guard going out of scope, an embedder dropping its command object.
It does B<not> work on the CLI, where F<bin/karr> wraps the run in an C<eval>
and exits from the error handler: the command object stays reachable from the
L<MooX::Cmd> command chain, so the guard is first reaped in global destruction.
L<App::karr::Git> is not re-entrant in that phase -- pushing from there drove
L<FFI::Platypus>'s type parser into unbounded recursion until the machine was
out of memory -- so DESTROY refuses to push once C<${^GLOBAL_PHASE}> is
C<DESTRUCT> and only reports.

L</flush_armed> is what makes the insurance real on that path. Every armed
guard registers itself in a process-wide registry, and F<bin/karr> flushes that
registry from an C<END> block: C<END> is the last point before global
destruction, and it also covers the C<exit> calls inside command bodies. The
DESTRUCT branch of DESTROY remains as the last resort for embedders that do not
flush.

Both the DESTRUCT report and L</flush_armed> gate on
C<$App::karr::Git::WRITES>, so a command that died before writing any ref
neither pushes nor advises a sync. DESTROY reads that package scalar rather
than the C<git> attribute because blessed objects are destroyed in undefined
order in this phase. Local refs are untouched either way, so C<karr sync>
always completes the push.

=head1 METHODS

=head2 done

    $guard->done;

Marks the guard as spent: its DESTROY becomes a no-op and L</flush_armed> skips
it. L<App::karr::Role::SyncLifecycle/sync_after> calls this both after a
successful push and after one that failed all three attempts -- in the failure
case the retries are already exhausted and the croak carries the guidance, so
repeating them from the flush would only duplicate the noise.

=head2 flush_armed

    my $count = App::karr::SyncGuard->flush_armed;

Runs the insurance push for every guard that is still armed, then empties the
registry; returns the number of guards it pushed for. Called from F<bin/karr>'s
C<END> block, which is the last moment a push is safe.

Does nothing at all when C<$App::karr::Git::WRITES> is zero: no ref was written
in this process, so there is nothing to push.

Never dies. A push that fails warns, exactly as the DESTROY path does, and
anything unexpected thrown by one guard is caught and warned so the remaining
guards still get their turn. That matters because the only caller is an C<END>
block on an already-failing exit path: an exception there would abort perl's
END queue and replace karr's documented exit code with perl's own. Each flushed
guard is marked done, so DESTROY does not repeat the attempt afterwards.

A push the remote refused ref by ref is not retried, and the warning does not
advise one: the far side already gave its answer, so it names what was refused
instead of pointing at a C<karr sync> that would be refused identically.

=head2 errs

    my @errors = $guard->errs;

Returns the list of error messages from retry attempts.

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
