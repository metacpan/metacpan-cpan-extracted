
package Coro::ProcessPool::Pipeline;
# ABSTRACT: A producer/consumer pipeline for Coro::ProcessPool
$Coro::ProcessPool::Pipeline::VERSION = '0.30';
use common::sense;
use Carp;
use Coro;
use Try::Catch;

sub new {
  my ($class, %param) = @_;
  my $pool = $param{pool} || croak 'expected parameter "pool"';

  bless {
    pool          => $pool,
    auto_shutdown => $param{auto_shutdown} || 0,
    shutting_down => 0,
    is_shutdown   => 0,
    num_pending   => 0,
    complete      => Coro::Channel->new,
  }, $class;
}


sub next {
  my $self = shift;
  my $finished = $self->{complete}->get or return;
  my ($result, $error) = @$finished;
  if ($error) {
    croak $error;
  } else {
    return $result;
  }
}


sub queue {
  my ($self, @args) = @_;
  croak 'pipeline is shut down' if $self->{is_shutdown};
  croak 'pipeline is shutting down' if $self->{shutting_down};

  my $deferred = $self->{pool}->defer(@args);

  async_pool {
    my ($self, $deferred) = @_;

    try {
      my $result = $deferred->recv;
      $self->{complete}->put([$result, undef]);
    }
    catch {
      $self->{complete}->put([undef, $_]);
    }
    finally {
      if (--$self->{num_pending} == 0) {
        if ($self->{shutting_down} || $self->{auto_shutdown}) {
          $self->{complete}->shutdown;
          $self->{is_shutdown} = 1;
          $self->{shutting_down} = 0;
        }
      }
    };

  } $self, $deferred;

  ++$self->{num_pending};
}


sub shutdown {
  my $self = shift;
  $self->{shutting_down} = 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Coro::ProcessPool::Pipeline - A producer/consumer pipeline for Coro::ProcessPool

=head1 VERSION

version 0.30

=head1 SYNOPSIS

  my $pool = Coro::ProcesPool->new();
  my $pipe = $pool->pipeline;

  # Start producer thread to queue tasks
  my $producer = async {
    while (my $task = get_next_task()) {
      $pipe->queue('Some::TaskClass', $task);
    }

    # Let the pipeline know no more tasks are coming
    $pipe->shutdown;
  };

  # Collect the results of each task as they are received
  while (my $result = $pipe->next) {
    do_stuff_with($result);
  }

=head1 DESCRIPTION

Provides an iterative mechanism for feeding tasks into the process pool and
collecting results. A pool may have multiple pipelines.

=head1 ATTRIBUTES

=head2 pool (required)

The L<Coro::ProcessPool> in which to queue tasks.

=head2 auto_shutdown (default: false)

When set to true, the pipeline will shut itself down as soon as the number of
pending tasks hits zero. At least one task must be sent for this to be
triggered.

=head1 METHODS

=head2 next

Cedes control until a previously queued task is complete and the result is
available.

=head2 queue($task, $args)

Queues a new task. Arguments are identical to L<Coro::ProcessPool/process> and
L<Coro::ProcessPool/defer>.

=head2 shutdown

Signals shutdown of the pipeline. A shutdown pipeline may not be reused.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
