=head1 NAME

AnyEvent::Fork::Pool - simple process pool manager on top of AnyEvent::Fork

=head1 SYNOPSIS

   use AnyEvent;
   use AnyEvent::Fork;
   use AnyEvent::Fork::Pool;

   # all possible parameters shown, with default values
   my $pool = AnyEvent::Fork
      ->new
      ->require ("MyWorker")
      ->AnyEvent::Fork::Pool::run (
           "MyWorker::run", # the worker function

           # pool management
           max        => 4,   # absolute maximum # of processes
           idle       => 0,   # minimum # of idle processes
           load       => 2,   # queue at most this number of jobs per process
           start      => 0.1, # wait this many seconds before starting a new process
           stop       => 10,  # wait this many seconds before stopping an idle process
           on_destroy => (my $finish = AE::cv), # called when object is destroyed

           # parameters passed to AnyEvent::Fork::RPC
           async      => 0,
           on_error   => sub { die "FATAL: $_[0]\n" },
           on_event   => sub { my @ev = @_ },
           init       => "MyWorker::init",
           serialiser => $AnyEvent::Fork::RPC::STRING_SERIALISER,
        );

   for (1..10) {
      $pool->(doit => $_, sub {
         print "MyWorker::run returned @_\n";
      });
   }

   undef $pool;

   $finish->recv;

=head1 DESCRIPTION

This module uses processes created via L<AnyEvent::Fork> (or
L<AnyEvent::Fork::Remote>) and the RPC protocol implement in
L<AnyEvent::Fork::RPC> to create a load-balanced pool of processes that
handles jobs.

Understanding of L<AnyEvent::Fork> is helpful but not critical to be able
to use this module, but a thorough understanding of L<AnyEvent::Fork::RPC>
is, as it defines the actual API that needs to be implemented in the
worker processes.

=head1 PARENT USAGE

To create a pool, you first have to create a L<AnyEvent::Fork> object -
this object becomes your template process. Whenever a new worker process
is needed, it is forked from this template process. Then you need to
"hand off" this template process to the C<AnyEvent::Fork::Pool> module by
calling its run method on it:

   my $template = AnyEvent::Fork
                     ->new
                     ->require ("SomeModule", "MyWorkerModule");

   my $pool = $template->AnyEvent::Fork::Pool::run ("MyWorkerModule::myfunction");

The pool "object" is not a regular Perl object, but a code reference that
you can call and that works roughly like calling the worker function
directly, except that it returns nothing but instead you need to specify a
callback to be invoked once results are in:

   $pool->(1, 2, 3, sub { warn "myfunction(1,2,3) returned @_" });

=over 4

=cut

package AnyEvent::Fork::Pool;

use common::sense;

use Scalar::Util ();

use Guard ();
use Array::Heap ();

use AnyEvent;
use AnyEvent::Fork::RPC;

# these are used for the first and last argument of events
# in the hope of not colliding. yes, I don't like it either,
# but didn't come up with an obviously better alternative.
my $magic0 = ':t6Z@HK1N%Dx@_7?=~-7NQgWDdAs6a,jFN=wLO0*jD*1%P';
my $magic1 = '<~53rexz.U`!]X[A235^"fyEoiTF\T~oH1l/N6+Djep9b~bI9`\1x%B~vWO1q*';

our $VERSION = 1.2;

=item my $pool = AnyEvent::Fork::Pool::run $fork, $function, [key => value...]

The traditional way to call the pool creation function. But it is way
cooler to call it in the following way:

=item my $pool = $fork->AnyEvent::Fork::Pool::run ($function, [key => value...])

Creates a new pool object with the specified C<$function> as function
(name) to call for each request. The pool uses the C<$fork> object as the
template when creating worker processes.

You can supply your own template process, or tell C<AnyEvent::Fork::Pool>
to create one.

A relatively large number of key/value pairs can be specified to influence
the behaviour. They are grouped into the categories "pool management",
"template process" and "rpc parameters".

=over 4

=item Pool Management

The pool consists of a certain number of worker processes. These options
decide how many of these processes exist and when they are started and
stopped.

The worker pool is dynamically resized, according to (perceived :)
load. The minimum size is given by the C<idle> parameter and the maximum
size is given by the C<max> parameter. A new worker is started every
C<start> seconds at most, and an idle worker is stopped at most every
C<stop> second.

You can specify the amount of jobs sent to a worker concurrently using the
C<load> parameter.

=over 4

=item idle => $count (default: 0)

The minimum amount of idle processes in the pool - when there are fewer
than this many idle workers, C<AnyEvent::Fork::Pool> will try to start new
ones, subject to the limits set by C<max> and C<start>.

This is also the initial amount of workers in the pool. The default of
zero means that the pool starts empty and can shrink back to zero workers
over time.

=item max => $count (default: 4)

The maximum number of processes in the pool, in addition to the template
process. C<AnyEvent::Fork::Pool> will never have more than this number of
worker processes, although there can be more temporarily when a worker is
shut down and hasn't exited yet.

=item load => $count (default: 2)

The maximum number of concurrent jobs sent to a single worker process.

Jobs that cannot be sent to a worker immediately (because all workers are
busy) will be queued until a worker is available.

Setting this low improves latency. For example, at C<1>, every job that
is sent to a worker is sent to a completely idle worker that doesn't run
any other jobs. The downside is that throughput is reduced - a worker that
finishes a job needs to wait for a new job from the parent.

The default of C<2> is usually a good compromise.

=item start => $seconds (default: 0.1)

When there are fewer than C<idle> workers (or all workers are completely
busy), then a timer is started. If the timer elapses and there are still
jobs that cannot be queued to a worker, a new worker is started.

This sets the minimum time that all workers must be busy before a new
worker is started. Or, put differently, the minimum delay between starting
new workers.

The delay is small by default, which means new workers will be started
relatively quickly. A delay of C<0> is possible, and ensures that the pool
will grow as quickly as possible under load.

Non-zero values are useful to avoid "exploding" a pool because a lot of
jobs are queued in an instant.

Higher values are often useful to improve efficiency at the cost of
latency - when fewer processes can do the job over time, starting more and
more is not necessarily going to help.

=item stop => $seconds (default: 10)

When a worker has no jobs to execute it becomes idle. An idle worker that
hasn't executed a job within this amount of time will be stopped, unless
the other parameters say otherwise.

Setting this to a very high value means that workers stay around longer,
even when they have nothing to do, which can be good as they don't have to
be started on the netx load spike again.

Setting this to a lower value can be useful to avoid memory or simply
process table wastage.

Usually, setting this to a time longer than the time between load spikes
is best - if you expect a lot of requests every minute and little work
in between, setting this to longer than a minute avoids having to stop
and start workers. On the other hand, you have to ask yourself if letting
workers run idle is a good use of your resources. Try to find a good
balance between resource usage of your workers and the time to start new
workers - the processes created by L<AnyEvent::Fork> itself is fats at
creating workers while not using much memory for them, so most of the
overhead is likely from your own code.

=item on_destroy => $callback->() (default: none)

When a pool object goes out of scope, the outstanding requests are still
handled till completion. Only after handling all jobs will the workers
be destroyed (and also the template process if it isn't referenced
otherwise).

To find out when a pool I<really> has finished its work, you can set this
callback, which will be called when the pool has been destroyed.

=back

=item AnyEvent::Fork::RPC Parameters

These parameters are all passed more or less directly to
L<AnyEvent::Fork::RPC>. They are only briefly mentioned here, for
their full documentation please refer to the L<AnyEvent::Fork::RPC>
documentation. Also, the default values mentioned here are only documented
as a best effort - the L<AnyEvent::Fork::RPC> documentation is binding.

=over 4

=item async => $boolean (default: 0)

Whether to use the synchronous or asynchronous RPC backend.

=item on_error => $callback->($message) (default: die with message)

The callback to call on any (fatal) errors.

=item on_event => $callback->(...) (default: C<sub { }>, unlike L<AnyEvent::Fork::RPC>)

The callback to invoke on events.

=item init => $initfunction (default: none)

The function to call in the child, once before handling requests.

=item serialiser => $serialiser (defailt: $AnyEvent::Fork::RPC::STRING_SERIALISER)

The serialiser to use.

=back

=back

=cut

sub run {
   my ($template, $function, %arg) = @_;

   my $max        = $arg{max}        || 4;
   my $idle       = $arg{idle}       || 0,
   my $load       = $arg{load}       || 2,
   my $start      = $arg{start}      || 0.1,
   my $stop       = $arg{stop}       || 10,
   my $on_event   = $arg{on_event}   || sub { },
   my $on_destroy = $arg{on_destroy};

   my @rpc = (
      async      =>        $arg{async},
      init       =>        $arg{init},
      serialiser => delete $arg{serialiser},
      on_error   =>        $arg{on_error},
   );

   my (@pool, @queue, $nidle, $start_w, $stop_w, $shutdown);
   my ($start_worker, $stop_worker, $want_start, $want_stop, $scheduler);

   my $destroy_guard = Guard::guard {
      $on_destroy->()
         if $on_destroy;
   };

   $template
      ->require ("AnyEvent::Fork::RPC::" . ($arg{async} ? "Async" : "Sync"))
      ->eval ('
           my ($magic0, $magic1) = @_;
           sub AnyEvent::Fork::Pool::retire() {
              AnyEvent::Fork::RPC::event $magic0, "quit", $magic1;
           }
        ', $magic0, $magic1)
   ;

   $start_worker = sub {
      my $proc = [0, 0, undef]; # load, index, rpc

      $proc->[2] = $template
         ->fork
         ->AnyEvent::Fork::RPC::run ($function,
              @rpc,
              on_event => sub {
                 if (@_ == 3 && $_[0] eq $magic0 && $_[2] eq $magic1) {
                    $destroy_guard if 0; # keep it alive

                    $_[1] eq "quit" and $stop_worker->($proc);
                    return;
                 }

                 &$on_event;
              },
           )
      ;

      ++$nidle;
      Array::Heap::push_heap_idx @pool, $proc;

      Scalar::Util::weaken $proc;
   };

   $stop_worker = sub {
      my $proc = shift;

      $proc->[0]
         or --$nidle;

      Array::Heap::splice_heap_idx @pool, $proc->[1]
         if defined $proc->[1];

      @$proc = 0; # tell others to leave it be
   };

   $want_start = sub {
      undef $stop_w;

      $start_w ||= AE::timer $start, $start, sub {
         if (($nidle < $idle || @queue) && @pool < $max) {
            $start_worker->();
            $scheduler->();
         } else {
            undef $start_w;
         }
      };
   };

   $want_stop = sub {
      $stop_w ||= AE::timer $stop, $stop, sub {
         $stop_worker->($pool[0])
            if $nidle;

         undef $stop_w
            if $nidle <= $idle;
      };
   };

   $scheduler = sub {
      if (@queue) {
         while (@queue) {
            @pool or $start_worker->();

            my $proc = $pool[0];

            if ($proc->[0] < $load) {
               # found free worker, increase load
               unless ($proc->[0]++) {
                  # worker became busy
                  --$nidle
                     or undef $stop_w;

                  $want_start->()
                     if $nidle < $idle && @pool < $max;
               }

               Array::Heap::adjust_heap_idx @pool, 0;

               my $job = shift @queue;
               my $ocb = pop @$job;

               $proc->[2]->(@$job, sub {
                  # reduce load
                  --$proc->[0] # worker still busy?
                     or ++$nidle > $idle # not too many idle processes?
                     or $want_stop->();

                  Array::Heap::adjust_heap_idx @pool, $proc->[1]
                     if defined $proc->[1];

                  &$ocb;

                  $scheduler->();
               });
            } else {
               $want_start->()
                  unless @pool >= $max;

               last;
            }
         }
      } elsif ($shutdown) {
         undef $_->[2]
            for @pool;

         undef $start_w;
         undef $start_worker; # frees $destroy_guard reference

         $stop_worker->($pool[0])
            while $nidle;
      }
   };

   my $shutdown_guard = Guard::guard {
      $shutdown = 1;
      $scheduler->();
   };

   $start_worker->()
      while @pool < $idle;

   sub {
      $shutdown_guard if 0; # keep it alive

      $start_worker->()
         unless @pool;

      push @queue, [@_];
      $scheduler->();
   }
}

=item $pool->(..., $cb->(...))

Call the RPC function of a worker with the given arguments, and when the
worker is done, call the C<$cb> with the results, just like calling the
RPC object durectly - see the L<AnyEvent::Fork::RPC> documentation for
details on the RPC API.

If there is no free worker, the call will be queued until a worker becomes
available.

Note that there can be considerable time between calling this method and
the call actually being executed. During this time, the parameters passed
to this function are effectively read-only - modifying them after the call
and before the callback is invoked causes undefined behaviour.

=cut

=item $cpus = AnyEvent::Fork::Pool::ncpu [$default_cpus]

=item ($cpus, $eus) = AnyEvent::Fork::Pool::ncpu [$default_cpus]

Tries to detect the number of CPUs (C<$cpus> often called CPU cores
nowadays) and execution units (C<$eus>) which include e.g. extra
hyperthreaded units). When C<$cpus> cannot be determined reliably,
C<$default_cpus> is returned for both values, or C<1> if it is missing.

For normal CPU bound uses, it is wise to have as many worker processes
as CPUs in the system (C<$cpus>), if nothing else uses the CPU. Using
hyperthreading is usually detrimental to performance, but in those rare
cases where that really helps it might be beneficial to use more workers
(C<$eus>).

Currently, F</proc/cpuinfo> is parsed on GNU/Linux systems for both
C<$cpus> and C<$eus>, and on {Free,Net,Open}BSD, F<sysctl -n hw.ncpu> is
used for C<$cpus>.

Example: create a worker pool with as many workers as CPU cores, or C<2>,
if the actual number could not be determined.

   $fork->AnyEvent::Fork::Pool::run ("myworker::function",
      max => (scalar AnyEvent::Fork::Pool::ncpu 2),
   );

=cut

BEGIN {
   if ($^O eq "linux") {
      *ncpu = sub(;$) {
         my ($cpus, $eus);

         if (open my $fh, "<", "/proc/cpuinfo") {
            my %id;

            while (<$fh>) {
               if (/^core id\s*:\s*(\d+)/) {
                  ++$eus;
                  undef $id{$1};
               }
            }

            $cpus = scalar keys %id;
         } else {
            $cpus = $eus = @_ ? shift : 1;
         }
         wantarray ? ($cpus, $eus) : $cpus
      };
   } elsif ($^O eq "freebsd" || $^O eq "netbsd" || $^O eq "openbsd") {
      *ncpu = sub(;$) {
         my $cpus = qx<sysctl -n hw.ncpu> * 1
                 || (@_ ? shift : 1);
         wantarray ? ($cpus, $cpus) : $cpus
      };
   } else {
      *ncpu = sub(;$) {
         my $cpus = @_ ? shift : 1;
         wantarray ? ($cpus, $cpus) : $cpus
      };
   }
}

=back

=head1 CHILD USAGE

In addition to the L<AnyEvent::Fork::RPC> API, this module implements one
more child-side function:

=over 4

=item AnyEvent::Fork::Pool::retire ()

This function sends an event to the parent process to request retirement:
the worker is removed from the pool and no new jobs will be sent to it,
but it still has to handle the jobs that are already queued.

The parentheses are part of the syntax: the function usually isn't defined
when you compile your code (because that happens I<before> handing the
template process over to C<AnyEvent::Fork::Pool::run>, so you need the
empty parentheses to tell Perl that the function is indeed a function.

Retiring a worker can be useful to gracefully shut it down when the worker
deems this useful. For example, after executing a job, it could check the
process size or the number of jobs handled so far, and if either is too
high, the worker could request to be retired, to avoid memory leaks to
accumulate.

Example: retire a worker after it has handled roughly 100 requests. It
doesn't matter whether you retire at the beginning or end of your request,
as the worker will continue to handle some outstanding requests. Likewise,
it's ok to call retire multiple times.

   my $count = 0;

   sub my::worker {

      ++$count == 100
         and AnyEvent::Fork::Pool::retire ();

      ... normal code goes here
   }

=back

=head1 POOL PARAMETERS RECIPES

This section describes some recipes for pool parameters. These are mostly
meant for the synchronous RPC backend, as the asynchronous RPC backend
changes the rules considerably, making workers themselves responsible for
their scheduling.

=over 4

=item low latency - set load = 1

If you need a deterministic low latency, you should set the C<load>
parameter to C<1>. This ensures that never more than one job is sent to
each worker. This avoids having to wait for a previous job to finish.

This makes most sense with the synchronous (default) backend, as the
asynchronous backend can handle multiple requests concurrently.

=item lowest latency - set load = 1 and idle = max

To achieve the lowest latency, you additionally should disable any dynamic
resizing of the pool by setting C<idle> to the same value as C<max>.

=item high throughput, cpu bound jobs - set load >= 2, max = #cpus

To get high throughput with cpu-bound jobs, you should set the maximum
pool size to the number of cpus in your system, and C<load> to at least
C<2>, to make sure there can be another job waiting for the worker when it
has finished one.

The value of C<2> for C<load> is the minimum value that I<can> achieve
100% throughput, but if your parent process itself is sometimes busy, you
might need higher values. Also there is a limit on the amount of data that
can be "in flight" to the worker, so if you send big blobs of data to your
worker, C<load> might have much less of an effect.

=item high throughput, I/O bound jobs - set load >= 2, max = 1, or very high

When your jobs are I/O bound, using more workers usually boils down to
higher throughput, depending very much on your actual workload - sometimes
having only one worker is best, for example, when you read or write big
files at maximum speed, as a second worker will increase seek times.

=back

=head1 EXCEPTIONS

The same "policy" as with L<AnyEvent::Fork::RPC> applies - exceptions
will not be caught, and exceptions in both worker and in callbacks causes
undesirable or undefined behaviour.

=head1 SEE ALSO

L<AnyEvent::Fork>, to create the processes in the first place.

L<AnyEvent::Fork::Remote>, likewise, but helpful for remote processes.

L<AnyEvent::Fork::RPC>, which implements the RPC protocol and API.

=head1 AUTHOR AND CONTACT INFORMATION

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/AnyEvent-Fork-Pool

=cut

1

