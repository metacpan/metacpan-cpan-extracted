package Async::Redis::AutoPipeline;

use strict;
use warnings;
use 5.018;

use Future;
use Future::IO;

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

sub _send_batch {
    my ($self, $batch) = @_;

    my $redis = $self->{redis};

    # Build pipeline commands
    my @commands = map { $_->{cmd} } @$batch;
    my @futures  = map { $_->{future} } @$batch;

    # Execute pipeline and distribute results
    # Keep reference to the pipeline future to prevent it from being lost
    my $pipeline_f = $redis->_execute_pipeline(\@commands);

    $pipeline_f->on_done(sub {
        my ($results) = @_;

        for my $i (0 .. $#$results) {
            my $result = $results->[$i];
            my $future = $futures[$i];

            # Check if result is an error string
            if (defined $result && "$result" =~ /^Redis error:/) {
                $future->fail($result);
            }
            else {
                $future->done($result);
            }
        }
    });

    $pipeline_f->on_fail(sub {
        my ($error) = @_;

        # Transport failure - fail all futures
        for my $future (@futures) {
            $future->fail($error) unless $future->is_ready;
        }
    });

    # Retain the future to keep the async operation alive
    $pipeline_f->retain;
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

1. Commands queue locally instead of sending immediately
2. A "next tick" callback is scheduled
3. When event loop yields, all queued commands flush as pipeline
4. Responses distributed to original futures

=head2 Invariants

=over 4

=item * C<_flush_pending> prevents double-scheduling

=item * C<_flushing> guard prevents reentrancy

=item * Depth limit triggers multiple batches if exceeded

=item * C<Future::IO-E<gt>later> is non-blocking next-tick

=back

=cut
