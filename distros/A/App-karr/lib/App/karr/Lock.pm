# ABSTRACT: Lock management via Git refs

package App::karr::Lock;
our $VERSION = '0.500';
use strict;
use warnings;
use App::karr::Git;


# Fallback when the caller names no TTL. App::karr::Cmd::Pick passes the board's
# `lock_timeout` instead; this only covers direct programmatic use.
use constant DEFAULT_TTL => 300;

# Outside refs/karr/, so no board refspec can reach it -- the same shape as the
# refs/karr-remote/ mirror and the refs/karr-conflict/ parking area in
# App::karr::Git, and for the same reason: state that must never be published.
use constant LOCK_ROOT => 'refs/karr-local/tasks/';

# Where locks were before #93. Read, never written.
use constant LEGACY_LOCK_ROOT => 'refs/karr/tasks/';

sub new {
    my ( $class, %args ) = @_;
    my $git = $args{git};
    unless ($git) {
        $git = App::karr::Git->new( dir => $args{dir} // '.' );
    }
    return bless {
        git     => $git,
        task_id => $args{task_id},
        ttl     => $args{ttl},
    }, $class;
}


sub task_id { shift->{task_id} }
sub git     { shift->{git} }


sub ttl {
    my ($self) = @_;
    return defined $self->{ttl} ? $self->{ttl} : DEFAULT_TTL;
}


sub ref_name {
    my ( $self, $task_id ) = @_;
    $task_id //= $self->task_id;
    return LOCK_ROOT . "$task_id/lock";
}


sub legacy_ref_name {
    my ( $self, $task_id ) = @_;
    $task_id //= $self->task_id;
    return LEGACY_LOCK_ROOT . "$task_id/lock";
}


sub get {
    my ( $self, $task_id ) = @_;
    my $ref = $self->ref_name($task_id);
    my $content = $self->git->read_ref($ref);
    return $content;
}


# Acquisition is one compare-and-swap per attempt, never a read followed by an
# unguarded write. The old version checked the ref and then wrote it, so every
# contender passed the check and every contender was told it had the lock --
# 16 forked agents, 16 "acquired" (#46).
#
# The OID read here is what the write is guarded against, so any outcome other
# than "the ref is still exactly as I judged it" fails and is retried against a
# fresh read. That is also what makes the expiry/steal below safe: a holder that
# refreshes its lock between the moment we decide it is stale and the moment we
# take it over moves the ref, and the takeover loses instead of overwriting a
# live lock.
sub acquire {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);
    my $git = $self->git;

    return $git->retry_contended( "the lock on task $task_id", sub {
        my ( $oid, $current ) = $git->read_ref_with_oid($ref);

        my $broke = '';
        if ( defined $oid && length $current && $current ne $email ) {
            # Held by somebody else: a final answer, not contention. Say so
            # rather than dying, which is what the raw libgit2 lock error used
            # to do -- unless the lock has expired, in which case its holder is
            # gone and leaving it there would make the task unpickable forever.
            return ( 0, "locked by $current" ) unless $self->expired($oid);
            $broke = " (broke stale lock held by $current)";
        }

        # $oid undef => create-if-absent, the exclusive case. $oid set => this
        # is our own lock being refreshed, or a stale one being taken over;
        # either way the write is guarded against the ref not having moved since
        # the read above.
        return () unless $git->write_ref_cas( $ref, $email, $oid );
        return ( 1, "acquired$broke" );
    } );
}


# Whether the lock commit $oid points at is older than the TTL. Takes the OID
# rather than a task id so the age judged and the OID a takeover is guarded
# against are the same revision.
sub expired {
    my ( $self, $oid ) = @_;
    my $ttl = $self->ttl;
    return 0 unless $ttl && $ttl > 0;   # a zero/negative TTL disables expiry
    my $held_since = $self->git->commit_time($oid);
    # No readable timestamp is no evidence the holder is dead, and refusing to
    # steal is the safe direction -- `karr unlock` is still there.
    return 0 unless defined $held_since;
    return ( time - $held_since ) > $ttl ? 1 : 0;
}


# Every lock currently held, with its holder, its age, and whether it has
# expired. Reported rather than acted on: seeing who holds what and for how long
# is the first half of getting out of a stuck board (#45).
#
# Both namespaces are walked, and a lock still sitting in the board namespace is
# marked rather than hidden. Those are the ones a clone cannot have written
# itself -- an older karr, or a pull from a remote that was given one (#93) --
# and leaving them out of the only command that can see locks would make them
# invisible as well as inert.
sub locks {
    my ($self) = @_;
    my @locks;
    for my $root ( LOCK_ROOT, LEGACY_LOCK_ROOT ) {
        for my $ref ( $self->git->list_refs($root) ) {
            next unless $ref =~ m{\A\Q$root\E(\d+)/lock\z};
            my $id = $1;
            my ( $oid, $owner ) = $self->git->read_ref_with_oid($ref);
            next unless defined $oid;
            my $held_since = $self->git->commit_time($oid);
            push @locks, {
                task_id    => 0 + $id,
                owner      => $owner,
                held_since => $held_since,
                age        => defined $held_since ? time - $held_since : undef,
                expired    => $self->expired($oid) ? 1 : 0,
                legacy     => $root eq LEGACY_LOCK_ROOT ? 1 : 0,
            };
        }
    }
    return sort { $a->{task_id} <=> $b->{task_id}
               || $a->{legacy}  <=> $b->{legacy} } @locks;
}


# Drop a lock regardless of who holds it or how old it is. release() refuses to
# touch another agent's lock, which is right for the pick path and useless as an
# escape hatch -- the whole problem is that the holder is never coming back.
#
# Clears the legacy ref as well, because that is the only way a board that was
# published with locks in it (#93) ever gets clean again.
sub break_lock {
    my ( $self, $task_id ) = @_;
    $task_id //= $self->task_id;

    my $owner;
    my $broke = 0;
    for my $ref ( $self->ref_name($task_id), $self->legacy_ref_name($task_id) ) {
        next unless $self->git->ref_exists($ref);
        $owner //= $self->git->read_ref($ref);

        # The return value is deliberately not consulted: after
        # App::karr::Git::delete_ref, the lock is gone whether this call
        # removed it or another unlock did in the same breath, and a delete
        # that was refused raises instead of answering. That is what makes
        # $broke honest -- until #119 it only meant "the ref was there when I
        # looked", and a refused delete was announced as a broken lock while
        # the holder kept the card. Anything that goes back to reading a soft
        # answer out of delete_ref has to earn this line again.
        $self->git->delete_ref($ref);
        $broke = 1;
    }
    return ( 0, "not locked" ) unless $broke;
    return ( 1, $owner );
}


# Giving a lock back is a guarded delete: the holder is re-read and the removal
# is guarded against that exact revision, so a lock that was broken and re-taken
# between the two is not dropped by whoever held it before (#94). An unguarded
# delete here could evict a live holder that has nothing to do with this call.
sub release {
    my ( $self, $task_id, $email ) = @_;
    $task_id //= $self->task_id;
    my $ref = $self->ref_name($task_id);
    my $git = $self->git;

    return $git->retry_contended( "the lock on task $task_id", sub {
        my ( $oid, $current ) = $git->read_ref_with_oid($ref);

        # Nothing of ours to give back: already released, already broken, or
        # expired and taken over. Not an error -- release is the tail of a pick
        # that has otherwise finished.
        return ( 1, "released" ) unless defined $oid;
        return ( 0, "locked by $current" )
            if length $current && $current ne $email;

        return () unless $git->delete_ref_cas( $ref, $oid );
        return ( 1, "released" );
    } );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Lock - Lock management via Git refs

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    my $lock = App::karr::Lock->new(git => $git, ttl => 300);
    my ($ok, $msg) = $lock->acquire(12, 'agent@example.com');

=head1 DESCRIPTION

L<App::karr::Lock> manages lightweight per-task locks stored in Git refs. It is
used by commands such as C<karr pick> to avoid concurrent agents selecting the
same task at the same time.

The lock is an optimisation, not the thing that makes C<karr pick> exclusive.
Its holder identity is the clone's C<user.email>, which every agent on one
machine shares, so it cannot separate them from each other at all; what actually
binds a pick is the compare-and-swap on the task card itself
(L<App::karr::BoardStore/save_task_cas>). What the lock buys is that agents do
not all pile onto the same candidate and lose the same race.

=head2 Expiry

A lock has a TTL, because an agent that dies between C<acquire> and C<release>
otherwise leaves a ref that no future run will ever clear -- and that task then
stays unpickable forever, with no way out from inside karr (#45). Age is the
committer time of the commit the lock ref points at, so it needs no payload of
its own and travels with the ref.

A lock past its TTL may be taken over. The takeover is itself a compare-and-swap
against the OID whose age was judged, so a holder that refreshes its lock in
between wins and is never silently evicted. The TTL is deliberately B<not>
C<claim_timeout>: see L<App::karr::Cmd::Pick>.

=head2 Locks are local, and live outside the board

Lock refs live under C<refs/karr-local/>, which nothing pushes, fetches, prunes
or snapshots. A lock says "this process, in this clone, is mid-pick right now",
and that sentence has no meaning anywhere else: a clone that receives one cannot
tell whether the holder is still alive, and has no way to find out.

They used to live at C<refs/karr/tasks/N/lock>, inside the namespace C<karr>
pushes. Any sync that fired while a lock was held published it, other clones
pulled it, and it then blocked their picks until somebody ran C<karr unlock> --
a lock that outlived the process holding it and the machine it ran on (#93). It
also turned every board backup into a snapshot of somebody's momentary lock.
Moving the refs out is what makes that impossible, rather than making it depend
on the timing of when a lock happens to be released.

Locks left in the old place by a C<karr> older than this one -- or pulled from a
remote that still has them -- are not acted on: they cannot say anything about
this process, and a pick's exclusivity does not rest on them anyway. They are
not ignored either. C<locks> reports them, marked C<legacy>, and C<break_lock>
clears them, so C<karr unlock> is the way out of the mess the old layout left
behind.

=head2 new

    my $lock = App::karr::Lock->new( git => $git, task_id => 12, ttl => 300 );
    my $lock = App::karr::Lock->new( dir => '.' );   # builds its own Git

Takes C<git> (an L<App::karr::Git> instance), or C<dir> to build one via
C<< App::karr::Git->new(dir => $dir) >> when no C<git> is given. C<task_id>
and C<ttl> are both optional -- see L</task_id> and L</ttl>.

=head2 task_id

The task this lock instance was constructed for. Every method that names a
lock (L</ref_name>, L</legacy_ref_name>, L</get>, L</acquire>, L</release>,
L</break_lock>) takes an explicit C<$task_id> and falls back to this only
when none is given, so one C<App::karr::Lock> can be reused across tasks by
always passing C<$task_id> explicitly -- as C<karr pick> does, trying one
candidate after another with a single lock object -- or dedicated to one
task by setting this instead.

=head2 git

The L<App::karr::Git> instance the lock reads and writes refs through. Set
from the C<git> argument to L</new>, or built there from C<dir> when not
given.

=head2 ttl

Seconds a lock may be held before L</expired> considers it stale and
L</acquire> is allowed to take it over. Falls back to C<300> (the
C<DEFAULT_TTL> constant) when not given at L</new> -- but direct
construction is the exception: C<karr pick> builds its lock with the
board's own C<lock_timeout> config value instead (see
L<App::karr::Cmd::Pick/LOCK EXPIRY>), so that is what governs expiry in
practice. A C<ttl> of C<0> or a negative number disables expiry outright:
L</expired> always answers false and no lock built with it is ever taken
over.

=head2 ref_name

    my $ref = $lock->ref_name(12);   # 'refs/karr-local/tasks/12/lock'
    my $ref = $lock->ref_name;       # uses $lock->task_id

The current-layout ref name for a task's lock, under C<refs/karr-local/> --
outside every namespace C<karr> pushes, fetches, prunes or snapshots (see
L</Locks are local, and live outside the board>). C<$task_id> defaults to
L</task_id> when omitted.

=head2 legacy_ref_name

    my $ref = $lock->legacy_ref_name(12);   # 'refs/karr/tasks/12/lock'

The pre-#93 ref name for a task's lock, inside the board namespace C<karr>
pushes. Nothing in this module writes here any more; it exists so L</locks>
can find locks a pre-#93 C<karr>, or a board that synced one in before the
fix, left behind, and so L</break_lock> can clear them. See
L</Locks are local, and live outside the board>.

=head2 get

    my $holder = $lock->get(12);   # e.g. 'agent@example.com', or undef

The identity currently holding the lock on C<$task_id> (defaulting to
L</task_id>), or C<undef> if it is not held. Reads only the current-layout
ref; a stray L</legacy_ref_name> lock is not reported here, see L</locks>.

=head2 acquire

    my ( $ok, $msg ) = $lock->acquire( 12, 'agent@example.com' );

Tries to take the lock on C<$task_id> (defaulting to L</task_id>) for
C<$email>. Always returns a two-element list for its ordinary outcomes,
rather than throwing:

=over 4

=item * C<(1, "acquired")> -- taken, nobody held it.

=item * C<(1, "acquired (broke stale lock held by $prior)")> -- taken over
from a holder whose lock had passed its L</ttl>; see L</expired>.

=item * C<(0, "locked by $current")> -- held by somebody else and not
expired. This is a final answer, not contention: the caller should treat it
as "somebody else has this one" and try a different task, not retry.

=back

The lock is not what makes a pick exclusive by itself -- see
L</DESCRIPTION> -- so losing the race here means trying a different task,
not that a concurrent pick is unsafe.

Acquisition is a single compare-and-swap per attempt, retried automatically
against Git ref contention (L<App::karr::Git/retry_contended>). That retry
loop, not this method, is what throws: if the ref stays contended across
every retry -- many agents writing the board at once -- the C<die> from
L<App::karr::Git/retry_contended> propagates uncaught. That is a distinct
failure from "locked by somebody else" above and is not expected in
ordinary use.

=head2 expired

    my $stale = $lock->expired($oid);

Whether the lock commit C<$oid> points at is older than L</ttl>. Takes the
commit OID a lock ref currently resolves to, not a C<$task_id> -- taken from
L</locks>, or from the OID L</acquire> reads before deciding whether to
steal. Guarding a takeover against the exact OID whose age was judged is
what keeps a holder that refreshes its lock mid-check from being evicted;
see L</acquire>.

Returns false (never expired) when L</ttl> is C<0> or negative, and also
when C<$oid>'s commit time cannot be read at all -- a missing timestamp is
not evidence the holder is dead, and refusing to steal is the safe
direction; C<karr unlock> remains the way out.

=head2 locks

    my @held = $lock->locks;
    # [ { task_id => 12, owner => 'a@x', held_since => 1712345678,
    #     age => 40, expired => 0, legacy => 0 }, ... ]

Every lock currently held, across both L</ref_name> and L</legacy_ref_name>
namespaces, sorted by task id and then current-before-legacy. Each entry is
a hashref with C<task_id>, C<owner>, C<held_since> (epoch seconds, or
C<undef> if unreadable), C<age> (seconds, or C<undef> to match), an
C<expired> flag (see L</expired>), and a C<legacy> flag marking a lock found
at L</legacy_ref_name> rather than L</ref_name>. Reporting only -- nothing
here acts on what it finds; that is L</break_lock>.

=head2 break_lock

    my ( $ok, $owner ) = $lock->break_lock(12);

Clears the lock on C<$task_id> (defaulting to L</task_id>) unconditionally
-- regardless of who holds it or whether L</expired> says it is stale -- at
both L</ref_name> and L</legacy_ref_name>. Returns C<(1, $owner)> naming
whoever held it (the current-layout holder if both were set), or
C<(0, "not locked")> if neither ref existed. This is the escape hatch
L</release> deliberately is not: C<karr unlock> is built on this, not on
L</release>, because the whole problem it solves is a holder that is never
coming back to release anything.

C<(1, $owner)> means the lock is really gone. When a lock ref exists and
refuses to be removed, this C<die>s with the C<karr: could not delete ...>
message from L<App::karr::Git/delete_ref> instead of reporting a break that
did not happen (#119) -- an escape hatch that lies leaves the card locked for
every other agent with nobody left to look at it.

=head2 release

    my ( $ok, $msg ) = $lock->release( 12, 'agent@example.com' );

Gives back the lock on C<$task_id> (defaulting to L</task_id>) held by
C<$email>. Like L</acquire>, returns a two-element list for its ordinary
outcomes and only lets L<App::karr::Git/retry_contended>'s exhaustion
C<die> through:

=over 4

=item * C<(1, "released")> -- released, or already gone (nothing held,
already broken, or taken over after expiring). Not an error: release is
normally the tail end of a pick that already finished its work.

=item * C<(0, "locked by $current")> -- held by a different identity, left
untouched.

=back

The delete is itself a compare-and-swap against the holder read moments
before, so a lock that was broken and re-taken between the read and the
delete is not dropped out from under its new holder (#94).

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
