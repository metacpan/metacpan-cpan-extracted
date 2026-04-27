package Async::Redis::AutoPipeline;

use strict;
use warnings;
use 5.018;

use Future;
use Future::AsyncAwait;
use Future::IO;
use Async::Redis::Error::Disconnected;

sub new {
    my ($class, %args) = @_;

    return bless {
        redis         => $args{redis},
        max_depth     => $args{max_depth} // 1000,
        _queue        => [],
        _flush_pending => 0,
        _flushing     => 0,
    }, $class;
}

sub command {
    my ($self, @args) = @_;

    my $future = Future->new;
    push @{$self->{_queue}}, { cmd => \@args, future => $future };

    # Schedule flush exactly once per batch
    unless ($self->{_flush_pending}) {
        $self->{_flush_pending} = 1;
        $self->_schedule_flush;
    }

    return $future;
}

sub _schedule_flush {
    my ($self) = @_;

    # Use event loop's "next tick" mechanism
    # sleep(0) yields to event loop then immediately returns
    Future::IO->sleep(0)->on_done(sub {
        $self->_do_flush;
    });
}

sub _do_flush {
    my ($self) = @_;

    # Reentrancy guard
    return if $self->{_flushing};
    $self->{_flushing} = 1;

    # Reset pending flag before flush (allows new commands to queue)
    $self->{_flush_pending} = 0;

    # Take current queue atomically
    my @batch = splice @{$self->{_queue}};

    if (@batch) {
        # Respect depth limit
        my $max = $self->{max_depth};
        if (@batch > $max) {
            # Put excess back, schedule another flush
            unshift @{$self->{_queue}}, splice(@batch, $max);
            $self->{_flush_pending} = 1;
            $self->_schedule_flush;
        }

        $self->_send_batch(\@batch);
    }

    $self->{_flushing} = 0;
}

# Detach and return all queued-but-not-yet-flushed commands. Caller is
# responsible for failing their futures. Called by Async::Redis::_reader_fatal
# when the connection dies before a scheduled flush.
sub _detach_queued {
    my ($self) = @_;
    my $queued = $self->{_queue} // [];
    $self->{_queue} = [];
    $self->{_flush_pending} = 0;
    return $queued;
}

sub _send_batch {
    my ($self, $batch) = @_;
    my $redis = $self->{redis};

    my @commands = map { $_->{cmd}    } @$batch;
    my @futures  = map { $_->{future} } @$batch;

    my $submit = (async sub {
        my $buffer = '';
        my @deadlines;
        for my $cmd (@commands) {
            $buffer .= $redis->_build_command(@$cmd);
            push @deadlines, $redis->_calculate_deadline(@$cmd);
        }

        await $redis->_with_write_gate(sub {
            return (async sub {
                if (!$redis->{_socket_live}) {
                    if ($redis->_reconnect_enabled) {
                        await $redis->_ensure_connected;
                    } else {
                        die Async::Redis::Error::Disconnected->new(
                            message => "Not connected",
                        );
                    }
                }
                for my $i (0 .. $#commands) {
                    $redis->_add_inflight(
                        $futures[$i],
                        $commands[$i][0],
                        [ @{$commands[$i]}[1..$#{$commands[$i]}] ],
                        $deadlines[$i],
                        'fail',
                    );
                }
                await $redis->_send($buffer);
            })->();
        });

        $redis->_ensure_reader;
    })->();

    # Transport failure on submit cascades to every future that wasn't
    # already failed by _reader_fatal.
    $submit->on_fail(sub {
        my ($err) = @_;
        for my $f (@futures) {
            $f->fail($err) unless $f->is_ready;
        }
    });

    # Ownership: the client's Future::Selector (_tasks) owns this submit
    # task. Any caller currently awaiting inside run_until_ready sees a
    # submit failure propagated via the selector. No ->retain needed.
    $redis->{_tasks}->add(data => 'autopipe-submit', f => $submit);
}

1;

__END__

=head1 NAME

Async::Redis::AutoPipeline - Automatic command batching

=head1 DESCRIPTION

AutoPipeline transparently batches Redis commands issued in the same
event loop tick into a single pipeline, reducing network round-trips
without changing the caller's API.

=head2 How It Works

    # These three commands are batched automatically
    my $f1 = $redis->set('a', 1);
    my $f2 = $redis->set('b', 2);
    my $f3 = $redis->get('a');

    await Future->needs_all($f1, $f2, $f3);

When C<auto_pipeline =E<gt> 1>:

=over 4

=item 1.

Commands queue locally instead of sending immediately.

=item 2.

A next-tick flush is scheduled with C<< Future::IO->sleep(0) >>.

=item 3.

When the event loop yields, queued commands flush as a pipeline.

=item 4.

Responses are distributed to the original command futures.

=back

=head2 Invariants

=over 4

=item * C<_flush_pending> prevents double-scheduling

=item * C<_flushing> guard prevents reentrancy

=item * Depth limit triggers multiple batches if exceeded

=item * C<< Future::IO->sleep(0) >> provides the non-blocking yield point

=back

=cut
