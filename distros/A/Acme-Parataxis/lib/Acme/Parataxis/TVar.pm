use v5.40;
no warnings qw[experimental::class experimental::try recursion];
use feature 'class';
#
# STM (software transactional memory). A TVar is a versioned mutable cell whose
# reads and writes only take effect through Acme::Parataxis->atomically. The transaction
# log lives on the calling fiber's Locals-stash (the same slot Acme::Parataxis::Local
# uses), keyed so it can never collide with a Local id:
#
#   { reads => { refaddr => [ $tvar, $version ] },   # journaled reads (first read wins)
#     writes => { refaddr => [ $tvar, $new_value ] },# staged writes (invisible until commit)
#     reads_list => [ $tvar, ... ] }                 # first-read order, for retry parking
#
my $TXN_KEY = 'Acme::Parataxis::TVar:txn';
my %RETRY_REGS;    # fid => dereg: removes the fiber from every TVar's waiters list
#
class Acme::Parataxis::TVar v0.1.3 {
    use Acme::Parataxis;
    use Acme::Parataxis::Error;          # for the internal STM_Retry control-flow exception
    use Acme::Parataxis::Sync::Mutex;    # the global commit lock
    use builtin qw[refaddr];
    use Carp    qw[croak];
    field $value : reader : param;       # committed value
    field $version : reader = 0;         # bumped on every committed write; the conflict detector
    field @waiters;                      # fids parked by retry() whose read sets include this TVar

    # The current fiber's transaction log, or a croak when there is none. Every TVar
    # operation (and retry()) runs strictly inside an atomically block.
    method _txn () {
        my $fid = Acme::Parataxis->current_fid;
        croak 'TVar operations must occur inside a scheduled fiber' if $fid < 0;
        my $stash = Acme::Parataxis::_fiber_locals( Acme::Parataxis->by_id($fid) );
        croak 'TVar operations must occur inside an atomically block' unless $stash->{$TXN_KEY};
        return $stash->{$TXN_KEY};
    }

    # Read the committed value, journaling the read. Re-reading a TVar written earlier in
    # the SAME transaction returns the transaction's own write (read-your-writes).
    method get () {
        my $txn = $self->_txn;
        my $key = refaddr($self);
        return $txn->{writes}{$key}[1] if exists $txn->{writes}{$key};
        if ( !exists $txn->{reads}{$key} ) {
            $txn->{reads}{$key} = [ $self, $version ];
            push @{ $txn->{reads_list} }, $self;
        }
        return $value;
    }

    # Stage a write. The committed TVar is untouched until the outermost atomically
    # commits, i.e. only once every journaled read still matches its version.
    method set ($v) {
        my $txn = $self->_txn;
        $txn->{writes}{ refaddr($self) } = [ $self, $v ];
        return $v;
    }

    # The committed value, readable from anywhere (no transaction required). Use for
    # inspection and tests; reads that participate in a transaction go through get().
    method waiters()          { return scalar @waiters }    # retry waiters parked on this TVar
    method _add_waiter ($fid) { push @waiters, $fid; 1 }

    method _remove_waiter ($fid) {                          # unregister a retry waiter (idempotent)
        my $before = @waiters;
        @waiters = grep { $_ != $fid } @waiters;
        return $before - @waiters;
    }

    # Applied by a commit: publish the value, bump the version, wake every fiber parked by
    # retry() on a read set that includes this TVar. Waking runs the unregister first so a
    # fiber is never enqueued twice (once here, once by a second TVar committing later).
    method _commit_value ($v) {
        $value = $v;
        $version++;
        my @w = @waiters;
        @waiters = ();
        Acme::Parataxis::TVar::_wake_retry_waiter($_) for @w;
        return 1;
    }

    # The transaction engine: Runs $code as one transaction on the calling fiber. Nested atomically calls join the
    # outer transaction (no separate commit; retry() still aborts the whole thing).
    sub _atomically ($cb) {
        my $fid = Acme::Parataxis->current_fid;
        croak 'atomically() must be called from inside a scheduled fiber' if $fid < 0;
        my $fiber = Acme::Parataxis->by_id($fid);
        my $stash = Acme::Parataxis::_fiber_locals($fiber);
        my $want  = wantarray;
        if ( $stash->{$TXN_KEY} ) {
            my @r;
            if   ($want) { @r    = $cb->() }
            else         { $r[0] = $cb->() }
            return $want ? @r : $r[0];
        }
        my $txn = { reads => {}, writes => {}, reads_list => [] };
        $stash->{$TXN_KEY} = $txn;
        my @r;
        my $loop_ok = 1;
        my $loop_err;

        # The finally is load-bearing: the stash entry must be cleared on *every* exit, including
        # the abort path where a real error (or an interrupt out of _park_on_reads) throws out of
        # the loop, so a later atomically never inherits a stale transaction.
        try {
            while (1) {
                my $run_ok = 1;
                my $err;

                # Note the shape: catch()'s own variable is scoped to the catch block, so the error
                # has to be handed to the enclosing lexical *inside* the block or $err stays undef.
                try {
                    if   ($want) { @r    = $cb->() }
                    else         { $r[0] = $cb->() }
                }
                catch ($caught) { $run_ok = 0; $err = $caught }
                if ($run_ok) {
                    last if Acme::Parataxis::TVar::_commit($txn);
                    _wipe($txn);    # commit conflict: rerun from a clean slate
                    next;
                }
                if ( ref($err) && $err->isa('Acme::Parataxis::Error::STM_Retry') ) {
                    Acme::Parataxis::TVar::_park_on_reads($txn);
                    _wipe($txn);
                    next;
                }
                die $err;    # any real error: abort the transaction, surface it unchanged
            }
        }
        catch ($caught) { $loop_ok = 0; $loop_err = $caught }
        finally { delete $stash->{$TXN_KEY} }
        die $loop_err unless $loop_ok;
        return $want ? @r : $r[0];
    }

    # Commit under the global commit lock: every journaled read must still carry the version
    # it had when read, then the write set is flushed (each TVar bumps its version and wakes
    # its retry waiters). A stale read discards the transaction and reports a conflict.
    # The commit never yields, so the lock is uncontended in the cooperative scheduler; a
    # parked-wait behind it is the honest fallback if the executor ever goes parallel.
    sub _commit ($txn) {
        state $lock = Acme::Parataxis::Sync::Mutex->new;
        $lock->lock;
        my $ok = 1;
        for my $key ( keys %{ $txn->{reads} } ) {
            my ( $tv, $v ) = @{ $txn->{reads}{$key} };
            if ( $v != $tv->version ) { $ok = 0; last }
        }
        if ($ok) {
            for my $key ( keys %{ $txn->{writes} } ) {
                my ( $tv, $v ) = @{ $txn->{writes}{$key} };
                $tv->_commit_value($v);
            }
        }
        $lock->unlock;
        return $ok;
    }

    # Parks the fiber on the transaction's read set until any of those TVars changes, then
    # returns so _atomically can re-run the block with a fresh log. The deregistration
    # passed to _park removes the fiber from every TVar's waiter list on an interrupt, so a
    # cancelled transaction never leaves a stale fid that a later commit could wake.
    sub _park_on_reads ($txn) {
        my $fid = Acme::Parataxis->current_fid;
        my @tv  = @{ $txn->{reads_list} };
        croak 'retry with an empty read set would never wake; read at least one TVar before retry()' if !@tv;
        $_->_add_waiter($fid) for @tv;
        my $dereg = sub { $_->_remove_waiter($fid) for @tv };
        $RETRY_REGS{$fid} = $dereg;
        my $ok = 1;
        my $err;
        try { Acme::Parataxis::_park( 'STM retry', 3, $dereg ) }
        catch ($caught) { $ok = 0; $err = $caught }

        # Both cleanups must run even when the park throws (an interrupt), or a cancelled
        # transaction would leave a stale fid on every TVar in its read set.
        finally {
            delete $RETRY_REGS{$fid};
            $dereg->();    # a commit wake already unregistered; strip any lists that did not change (idempotent)
        }
        die $err unless $ok;    # interrupt (timeout/cancel): the transaction aborts
        return;
    }

    # Wakes a retry-parked fiber once: unregisters it from every TVar's waiters list, then
    # enqueues it. The unregister keeps a single commit from turning into multiple wakes.
    sub _wake_retry_waiter ($fid) {
        return unless defined Acme::Parataxis->by_id($fid);
        if ( my $dereg = delete $RETRY_REGS{$fid} ) { $dereg->() }
        Acme::Parataxis::_scheduler_enqueue_by_id($fid);
    }

    # The retry() implementation: aborts the current transaction. The STM_Retry exception
    # is caught by _atomically, which parks on the read set and re-runs the block.
    sub _retry () {
        my $fid = Acme::Parataxis->current_fid;
        croak 'retry() must be called from inside a scheduled fiber' if $fid < 0;
        my $stash = Acme::Parataxis::_fiber_locals( Acme::Parataxis->by_id($fid) );
        croak 'retry() must be called from inside an atomically block' unless $stash->{$TXN_KEY};
        die Acme::Parataxis::Error::STM_Retry->new;
    }
    sub _wipe ($txn) { $txn->{reads} = {}; $txn->{writes} = {}; $txn->{reads_list} = []; }
};
#
1;
