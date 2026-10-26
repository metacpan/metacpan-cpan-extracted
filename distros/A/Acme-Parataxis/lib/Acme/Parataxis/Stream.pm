use v5.40;
use feature 'class';
no warnings qw[experimental::class recursion];
use Time::HiRes qw[time];

# A chainable FRP pipeline over bounded Channels: async stream stages. Every stage is a
# factory: it allocates its own bounded output Channel, spawns a background fiber that loops the input applying a
# callback, and returns a new Stream wrapping the output. Backpressure is free - a full bounded channel parks the
# stage's producer all the way upstream, which is exactly what t/057's parked_puts() counts.
#
# Teardown is the same everywhere: each stage's fiber ends its `while (my $x = $src->get)` loop when the upstream
# Channel shuts down, then shuts its own output down in turn, so a consume()'d chain unwinds fiber-by-fiber back to
# the source. `shutdown` releases the parked get()ers (Channel.pm's shutdown adjusts the get semaphore by 1e9), so no
# stage can park forever on a source that quit - the "zero leaked fibers" guarantee holds from the very
# first from_channel.
class Acme::Parataxis::Stream v0.1.1 {
    use Carp qw[croak];
    use Acme::Parataxis qw[fiber await_sleep];
    use Acme::Parataxis::Channel;
    field $src   : param;                     # the Channel this stage reads from
    field $chain : reader;                    # the upstream Stream this stage was built from (undef at the head)
    field $cap   : param : reader //= 128;    # bounded output Channel size shared by every stage of the pipeline

    method map ($cb) {
        croak 'map() requires a CODE ref' unless ref $cb eq 'CODE';
        return $self->chain_factory( map => $cb );
    }

    method filter ($cb) {
        croak 'filter() requires a CODE ref' unless ref $cb eq 'CODE';
        return $self->chain_factory( filter => $cb );
    }

    method batch ($n) {
        $n >= 1 or croak "batch size must be >= 1 (got $n)\n";
        return $self->chain_factory( batch_count => $n );
    }

    method batch_time ($ms) {
        $ms >= 0 or croak "batch_time must be >= 0 (got $ms)\n";
        return $self->chain_factory( batch_deadline => $ms );
    }

    method throttle ($per_s) {
        $per_s >= 1 or croak "throttle rate must be >= 1/s (got $per_s)\n";
        return $self->chain_factory( throttle => $per_s );
    }

    method chain_factory (%op) {
        my $out = Acme::Parataxis::Channel->new( capacity => $self->cap );    # bounded: a slow consume parks upstream for free
        my $op  = ( keys %op )[0];
        my $val = $op{$op};
        my $fid = fiber {
            if ( $op eq 'throttle' ) {

                # At most $val emissions a second: schedule the next emission one gap ahead and sleep only the
                # remainder. A stage held up by backpressure emits immediately (it never "catches up") and pushes the
                # next slot forward from the actual emission, so the rate is an upper bound, reached from idle below.
                my $gap_ms = 1000 / $val;
                my $next   = 0;
                while ( defined( my $x = $src->get ) ) {
                    if ($next) {
                        my $remaining = $next - Acme::Parataxis::_now_ms();
                        await_sleep($remaining) if $remaining > 0;
                    }
                    $out->put($x);
                    $next = Acme::Parataxis::_now_ms() + $gap_ms;
                }
            }
            elsif ( $op eq 'batch_count' ) {
                my @g;
                while ( defined( my $x = $src->get ) ) {
                    push @g, $x;
                    if ( @g >= $val ) { $out->put( [@g] ); @g = () }
                }
                $out->put( [@g] ) if @g;
            }
            elsif ( $op eq 'batch_deadline' ) {

                # The first item of a batch arms an absolute deadline; the stage then waits with get-with-deadline so
                # the deadline fires even with no further items. Enough items (or the deadline) flushes the batch and
                # the next item re-arms. A source that quits mid-batch flushes what it has as the final partial batch.
                my @g;
                my $deadline = 0;    # 0 = no batch open yet
                while (1) {
                    my ( $ch, $item );
                    if ($deadline) {
                        my $remaining = $deadline - Acme::Parataxis::_now_ms();
                        if ( $remaining <= 0 ) {
                            $out->put( [@g] );
                            @g        = ();
                            $deadline = 0;
                            next;
                        }
                        ( $ch, $item ) = $src->select( [ $src, 'get' ], timeout => $remaining );
                        if ( !defined $ch ) {    # our own deadline fired
                            $out->put( [@g] );
                            @g        = ();
                            $deadline = 0;
                            next;
                        }
                    }
                    else {
                        ( $ch, $item ) = ( $src, $src->get );
                    }
                    last unless defined $item;    # source shutdown delivers undef; flush the partial below
                    push @g, $item;
                    $deadline = Acme::Parataxis::_now_ms() + $val unless $deadline;
                }
                $out->put( [@g] ) if @g;
            }
            else {    # map | filter
                while ( defined( my $x = $src->get ) ) {
                    if ( $op eq 'filter' ) { $out->put($x) if $val->($x) }
                    else                   { $out->put( $val->($x) ) }
                }
            }
            $out->shutdown;    # upstream ended: release any downstream parked get()ers; the chain unwinds one fiber at a time
            1;
        };
        my $chain = __CLASS__->new( src => $out, cap => $self->cap );
        $chain->_link($self);    # chain heads back toward the raw source (introspection)
        return $chain;
    }
    method _link ($up) { $chain = $up; 1 }

    method consume ($cb) {
        croak 'consume() requires a CODE ref' unless ref $cb eq 'CODE';
        my $ffid = fiber {
            while ( defined( my $x = $src->get ) ) {
                if   ( ref $x && ref $x eq 'ARRAY' ) { $cb->(@$x) }
                else                                 { $cb->($x) }
            }
            1;
        };
        return $ffid;    # the fiber handle so the caller can ->await it; the fiber ends when the source shuts down
    }
    method shutdown () { $src->shutdown; $self->chain->shutdown if $self->chain; 1 }

    # from_channel() is the chain head constructor, called as Acme::Parataxis::Stream->from_channel($ch, ...),
    # so like Channel->select it is a plain package sub: it builds a new stream rather than dispatching on one,
    # and takes the class as $class.
    sub from_channel ( $class, $ch, %opts ) {
        my $cap = $opts{stage_capacity} // 128;
        return $class->new( src => $ch, cap => $cap );
    }
};
#
1;
