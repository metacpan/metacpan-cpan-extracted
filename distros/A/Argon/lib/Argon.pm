package Argon;
# ABSTRACT: Simple, fast, and flexible distributed computing
$Argon::VERSION = '0.18';
use strict;
use warnings;
use Carp;

our $ALLOW_EVAL = 0;
sub ASSERT_EVAL_ALLOWED { $Argon::ALLOW_EVAL || croak 'not permitted: $Argon::ALLOW_EVAL is not set' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon - Simple, fast, and flexible distributed computing

=head1 VERSION

version 0.18

=head1 DESCRIPTION

Argon is a distributed processing platform built for Perl. It is designed to
offer a simple, flexible, system for quickly building scalable systems with the
minimum impact on existing workflows and code structure.

=head1 QUICK START

An argon system is controlled by a I<manager> process, whose job it is to
schedule tasks among registered I<workers>.

=head2 MANAGER

A manager process is started with C<ar-manager>. The manager, workers, and
clients must all use the same key (a file containing a key phrase used for
encryption).

  ar-manager --host localhost --port 8000 --key path/to/secret --verbose 7

=head2 WORKER

Workers are started with C<ar-worker> and must use the same C<key> as the
manager.

  ar-worker --mgr mgrhost:8000 --capacity 8 --key path/to/secret --verbose 7

=head2 CLIENT

Connecting to an Argon service is straightforward.

  use Argon::Client;
  use AnyEvent;

  # Connect
  my $cv = AnyEvent->condvar;

  my $ar = Argon::Client->new(
    host    => 'mgrhost',
    port    => 8000,
    keyfile => 'path/to/key',
    ready   => $cv,
    retry   => 1,
  );

  # Connected!
  $cv->recv;

A code ref (or any callable reference) may be passed using the C<ready>
parameter which will be called once the client is connected. The example uses a
condition variable (see L<AnyEvent/CONDITION VARIABLES>) to sleep until it
is called, making the connection blocking.

=head1 RUNNING TASKS

Once connected, there are a number of ways to schedule tasks with the manager,
the most basic being the L<Argon::Client/queue> method.

  $client->queue('My::Task::Class', $arg_list, sub {
    my $reply = shift;
    my $result = $reply->result;
  });

There are a couple things to note here. The task class is any class that
defines both a C<new> and a C<run> method. The C<$arg_list> will be passed to
C<new>. A subroutine is passed which is called when the result is ready. The
call to the C<result> method will C<croak> if the task failed.

If C<retry> was set when the client was connected, the task will retry on a
logarithmic backoff until the server has the capacity to process the task
(see L<Argon/PREDICTABLE PERFORMANCE DEGREDATION>).

If the workers were started with the C<--allow-eval> switch, the client may
pass code references directly to be evaluated by the workers using the
L<Argon::Client/process> method.

  local $Argon::ALLOW_EVAL = 1;

  $client->process(sub { ... }, $arg_list, sub {
    ...
  });

=head1 PREDICTABLE PERFORMANCE DEGREDATION

One of the key problems with many task queue implementations is the manner in
which the system recovers from an interruption in service. In most cases, tasks
continue to pile up while the system is unavailable. Once the service is again
ready to process tasks, a significant backlog has built up, creating further
delay for new tasks added to the queue. This creates a log jam that is often
accompanied by incidental service slowdowns that can be difficult to diagnose
(for example, overloaded workers clearing out the backlog tie up the database,
causing other services to slow down).

Argon prevents these cases by placing the responsibility for the backlog on the
client. When the manager determines that the system has reached max capacity,
new tasks are I<rejected> until there is room in the queue. From the
perspective of the client, there is still a delay in the processing of tasks,
but the task queue itself never becomes overloaded and the performance
degredation will never overflow onto neighborhing systems as a result.

Another adavantage of having a bounded queue is that clients are aware of the
backlog and may report this to callers. System administrators may effectively
plan for and respond to increased load by spinning up new servers as needed
because they can reliably predict the performance of the system under load
given a reliable estimate of the cost imposed by the tasks being performed.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
