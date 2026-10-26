use v5.40;
no warnings qw[experimental::class recursion];
use feature 'class';
class Acme::Parataxis::Sync::RwLock v0.1.1 : isa(Acme::Parataxis::Sync) {
    use Acme::Parataxis;
    use Carp qw[croak];
    field $writer : reader;           # fiber id holding the exclusive write lock; undef when no writer holds it
    field $readers : reader = 0;      # outstanding read holds (a fiber may hold more than one)
    field %read_holders;              # fiber id => how many read holds that fiber owns
    field @read_waiters  : reader;    # fiber ids parked for a shared read lock, FIFO
    field @write_waiters : reader;    # fiber ids parked for the exclusive write lock, FIFO

    #
    method owner        {$writer}                                            # Sign of a poor API...
    method read_holders { scalar keys %read_holders }
    method waiters      { scalar(@read_waiters) + scalar(@write_waiters) }

    # Take (or deepen) a shared read hold, parking only when a writer holds the lock or is queued behind one.
    method read_lock {
        my $fid = $self->_fid('RwLock read_lock must occur inside a scheduled fiber');

        # Re-entering while this fiber already holds a read lock deepens the hold in place instead of parking.
        # Parking here would deadlock: a queued writer waits for this hold to drain, and this read would wait for
        # that writer.
        if ( $read_holders{$fid} ) {
            $read_holders{$fid}++;
            $readers++;
            return 1;
        }

        # This fiber already holds the write lock, so it has exclusive access already. Take the read hold in
        # place -- parking would be waiting for the writer (this very fiber) to release.
        if ( defined $writer && $writer == $fid ) {
            $self->_grant_read($fid);
            return 1;
        }

        # Writer-preferring: once a writer holds the lock or is queued for it, no *new* reader may jump ahead,
        # otherwise a steady read stream would starve writers forever.
        if ( !defined $writer && !@write_waiters ) {
            $self->_grant_read($fid);
            return 1;
        }
        push @read_waiters, $fid;
        $self->_park(
            'RwLock read lock',
            sub {
                # A writer's release may have granted us a read hold an instant before an interrupt fired. The
                # interrupt throws before read_lock() returns, so pass the hold on rather than stranding a read
                # on a fiber id that is about to die (and later be reused).
                $self->_drop_reads($fid) if $read_holders{$fid};
                $self->remove_read_waiter($fid);
            }
        );
        return 1;    # _pump granted the hold before waking us
    }

    # Release one read hold. When the last hold goes the lock may finally be handed on. Only a fiber that actually
    # holds one may call it.
    method read_unlock {
        my $fid = $self->_fid('RwLock read_unlock must occur inside a scheduled fiber');
        croak 'RwLock read_unlock: this fiber holds no read lock' unless $read_holders{$fid};

        # Release exactly one hold per call, so a nested read_guard's DESTROY only frees its own hold and cannot
        # strand the outer guard on a lock it no longer owns.
        $read_holders{$fid}--;
        delete $read_holders{$fid} unless $read_holders{$fid};
        $readers--;
        $self->_pump if $readers == 0;
        return 1;
    }

    # Non-blocking shared acquisition: false instead of parking when a writer holds the lock or is queued.
    method try_read_lock {
        my $fid = $self->_fid('RwLock try_read_lock must occur inside a scheduled fiber');
        if ( $read_holders{$fid} ) {
            $read_holders{$fid}++;
            $readers++;
            return 1;
        }
        if ( defined $writer && $writer == $fid ) { $self->_grant_read($fid); return 1 }    # already exclusive
        return 0 if defined $writer || @write_waiters;                                      # never steal ahead of a waiting writer
        $self->_grant_read($fid);
        return 1;
    }

    # Take the exclusive write lock, parking until every reader has drained and no writer is queued ahead.
    method write_lock {
        my $fid = $self->_fid('RwLock write_lock must occur inside a scheduled fiber');
        croak 'RwLock is not reentrant: this fiber already holds the write lock'                          if defined $writer && $writer == $fid;
        croak 'RwLock write_lock: this fiber holds a read lock; upgrading read to write is not supported' if $read_holders{$fid};
        if ( !defined $writer && $readers == 0 && !@write_waiters ) {
            $writer = $fid;
            return 1;
        }
        push @write_waiters, $fid;
        $self->_park(
            'RwLock write lock',
            sub {
                # A release may have handed us the write lock just as an interrupt fired. That hand-off is never
                # collected -- the interrupt throws before write_lock() returns -- so clear it and let _pump pass
                # ownership on instead of leaving it stranded on a dying fiber id.
                $writer = undef if defined $writer && $writer == $fid;
                $self->remove_write_waiter($fid);
                $self->_pump;    # we may have been the writer every reader was waiting behind
            }
        );
        return 1;                # _pump handed us the lock before waking us
    }

    # Release the exclusive write lock to the next queued writer (or to the waiting readers). Only the current
    # writer may call it.
    method write_unlock {
        my $fid = $self->_fid('RwLock write_unlock must occur inside a scheduled fiber');
        croak 'RwLock write_unlock: the lock is not write-held'         unless defined $writer;
        croak 'RwLock write_unlock from a fiber that is not the writer' unless $writer == $fid;
        $writer = undef;
        $self->_pump;
        return 1;
    }

    # Non-blocking exclusive acquisition: false instead of parking. Never cuts ahead of a queued writer.
    method try_write_lock {
        my $fid = $self->_fid('RwLock try_write_lock must occur inside a scheduled fiber');
        croak 'RwLock is not reentrant: this fiber already holds the write lock'                              if defined $writer && $writer == $fid;
        croak 'RwLock try_write_lock: this fiber holds a read lock; upgrading read to write is not supported' if $read_holders{$fid};
        return 0 if defined $writer || $readers > 0 || @write_waiters;
        $writer = $fid;
        return 1;
    }

    method read_guard {
        $self->read_lock;
        Acme::Parataxis::Sync::RwLock::Guard->new( lock => $self, mode => 'read' );
    }

    method write_guard {
        $self->write_lock;
        Acme::Parataxis::Sync::RwLock::Guard->new( lock => $self, mode => 'write' );
    }

    method remove_read_waiter ($fid) {
        my $before = @read_waiters;
        @read_waiters = grep { $_ != $fid } @read_waiters;
        return $before - @read_waiters;
    }

    method remove_write_waiter ($fid) {
        my $before = @write_waiters;
        @write_waiters = grep { $_ != $fid } @write_waiters;
        return $before - @write_waiters;
    }

    # Record a read hold for $fid, dropping it out of the reader queue if it was parked there.
    method _grant_read ($fid) {
        $read_holders{$fid}++;
        $readers++;
        $self->remove_read_waiter($fid);
        return 1;
    }

    # Give back every read hold $fid owns; when the last one goes, the lock may finally be handed on. Only the
    # interruption path uses this - the fiber is unwinding, so any hold left on it would be stranded.
    method _drop_reads ($fid) {
        my $n = delete $read_holders{$fid};
        return 0 unless defined $n;
        $readers -= $n;
        $self->_pump if $readers == 0;
        return 1;
    }

    # The lock may have become available: hand it to the next living writer, else to every waiting reader.
    # Writers go first (writer preference) so a queued writer is served as soon as the readers drain.
    method _pump {
        return 0 if defined $writer || $readers > 0;    # still busy; whoever frees it last calls us again
        if (@write_waiters) {
            my $next;
            while (@write_waiters) {
                my $waiter = shift @write_waiters;
                next unless defined Acme::Parataxis->by_id($waiter);
                $next = $waiter;
                last;
            }
            if ( defined $next ) {

                # Hand-off is atomic: the lock is recorded before the waiter is woken, so nobody can take it
                # in between and the waiter only ever has to collect what is already its own.
                $writer = $next;
                Acme::Parataxis::_scheduler_enqueue_by_id($next);
                return 1;
            }
        }
        my @grant = grep { defined Acme::Parataxis->by_id($_) } @read_waiters;
        @read_waiters = ();
        return 0 unless @grant;

        # Readers share, so every parked reader is granted in the same pass rather than one per release.
        $self->_grant_read($_) for @grant;
        Acme::Parataxis::_scheduler_enqueue_by_id($_) for @grant;
        return 1;
    }
};

# Util. A classic package, not feature::class: a perlclass 'method DESTROY' is one trigger of the perl_clone access
# violation behind threads->create on some 5.42.x builds (Acme::Parataxis::Blocking's spawn_blocking), so guard classes
# are kept as classic blessed packages. Note: the Sync::* namespaces themselves still hit a separate, name-dependent
# clone crash on affected perls regardless of this - see Acme::Parataxis::Blocking's pod warning.
package Acme::Parataxis::Sync::RwLock::Guard v0.1.1 {

    sub new ( $class, %args ) {
        return bless { lock => $args{lock}, mode => $args{mode} }, $class;
    }

    sub DESTROY {
        my $self = shift;
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        $self->{mode} eq 'write' ? $self->{lock}->write_unlock : $self->{lock}->read_unlock;
    }
}
#
1;
