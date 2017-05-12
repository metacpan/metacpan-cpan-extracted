package AnyEvent::Beanstalk::Worker;

use 5.016001;
use strict;
use warnings;
use feature 'current_sub';
use AnyEvent;
use AnyEvent::Log;
use AnyEvent::Beanstalk;

our $VERSION = '0.05';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self => $class;

    my %args = @_;

    $self->{_cb}     = {};
    $self->{_event}  = {};
    $self->{_jobs}   = {};
    $self->{_events} = [];    ## event queue
    $self->{_handled_jobs} = 0;  ## simple job counter

    $self->{_running}        = 0;
    $self->{_stop_tries}     = 0;
    $self->{_max_stop_tries} = $args{max_stop_tries} // 3;
    $self->{_max_jobs}       = $args{max_jobs} || 0;
    $self->{_concurrency}    = $args{concurrency} || 1;
    $self->{_log_level}      = $args{log_level} // 4;

    $self->{_reserve_timeout}        = $args{reserve_timeout} || 1;
    $self->{_reserve_base}           = $self->{_reserve_timeout};
    $self->{_reserve_timeout_factor} = 1.1;
    $self->{_reserve_timeout_max}    = 4;
    $self->{_release_delay}          = $args{release_delay} || 3;

    $self->{_initial_state}          = $args{initial_state};

    $self->{_log_ctx} = AnyEvent::Log::ctx;
    $self->{_log_ctx}->title(__PACKAGE__);
    $self->{_log_ctx}->level($self->{_log_level});

    $self->{_log}          = {};
    $self->{_log}->{trace} = $self->{_log_ctx}->logger("trace");
    $self->{_log}->{debug} = $self->{_log_ctx}->logger("debug");
    $self->{_log}->{info}  = $self->{_log_ctx}->logger("info");
    $self->{_log}->{note}  = $self->{_log_ctx}->logger("note");

    $self->{_signal} = {};
    $self->{_signal}->{TERM} = AnyEvent->signal(
        signal => "TERM",
        cb =>
          sub { $self->{_log_ctx}->log( warn => "TERM received" ); $self->stop }
    );
    $self->{_signal}->{INT} = AnyEvent->signal(
        signal => "INT",
        cb =>
          sub { $self->{_log_ctx}->log( warn => "INT received" ); $self->stop }
    );
    $self->{_signal}->{USR2} = AnyEvent->signal(
        signal => "USR2",
        cb     => sub {
            $self->{_log_level} =
              ( $self->{_log_level} >= 9 ? 2 : $self->{_log_level} + 1 );
            $self->{_log_ctx}->level($self->{_log_level});
        }
    );

    $args{beanstalk_host} ||= 'localhost';
    $args{beanstalk_port} ||= 11300;

    unless ($args{beanstalk_watch}) {
        die "beanstalk_watch argument required\n";
    }

    $self->beanstalk(
        server  => $args{beanstalk_host} . ':' . $args{beanstalk_port},
        decoder => $args{beanstalk_decoder}
    );

    $self->beanstalk->watch( $args{beanstalk_watch} )->recv;

    $self->on(
        start => sub {
            my $self = shift;
            my $reason = shift || '(unknown)';

            $self->{_log}->{trace}->("in start: $reason");

            unless ( $self->{_running} ) {
                $self->{_log}->{trace}->("worker is not running");
                return;
            }

            unless ( $self->job_count < $self->concurrency ) {
                $self->{_log}->{trace}->( "worker running "
                      . $self->job_count
                      . " jobs; will not accept more jobs until others finish"
                );
                return;
            }

            if ( $self->max_jobs and $self->handled_jobs >= $self->max_jobs ) {
                $self->{_log}->{info}->("Handled " . $self->handled_jobs . "; will not accept more jobs");
                return;
            }

            if ( ! $self->job_count and $self->{_stop_tries} ) {
                $self->{_log}->{info}->("No jobs left; stopping as requested");
                return $self->stop;
            }

            $self->beanstalk->reserve(
                $self->{_reserve_timeout},
                sub {
                    my ( $qjob, $qresp ) = @_;
                    $qresp //= '';

                    if ( $qresp =~ /timed_out/i ) {
                        $self->{_reserve_timeout} *=
                          $self->{_reserve_timeout_factor}
                          unless $self->{_reserve_timeout} >=
                          $self->{_reserve_timeout_max};
                        $self->{_log}->{trace}
                          ->("beanstalk reservation timed out");
                        return $self->emit( start => ($qresp) );
                    }

                    unless ( $qresp =~ /reserved/i ) {
                        $self->{_log}->{note}->("beanstalk returned: $qresp")
                          unless $qresp =~ /deadline_soon/i;
                        return $self->emit( start => ($qresp) );
                    }

                    $self->{_reserve_timeout} = $self->{_reserve_base};

                    if ( $self->{_jobs}->{ $qjob->id } ) {
                        $self->{_log_ctx}->log( warn => "Already have "
                              . $qjob->id
                              . " reserved (must have expired)" );
                        return $self->emit( start => ("already reserved") );
                    }

                    $self->{_jobs}->{ $qjob->id } = 1;
                    $self->{_handled_jobs}++;

                    $self->{_log}->{info}->( "added job "
                          . $qjob->id
                          . "; outstanding jobs: "
                          . $self->job_count );

                    $self->{_log}->{trace}->( "reserved job " . $qjob->id );

                    if ($self->{_initial_state}) {
                        $self->emit( $self->{_initial_state} => @_ );
                    }

                    else {
                        $self->finish(
                            release => $qjob->id,
                            { delay => $self->{_release_delay} }
                        );
                    }

                    $self->emit( start => ('reserved') );
                }
            );
        }
    );

    ## FIXME: thinking about when to touch jobs, how to respond to
    ## FIXME: NOT_FOUND, etc. after timeouts

    ## FIXME: think about logging for clarity; figure out how to
    ## FIXME: filter 'note' level messages (for example)

    $self->init(@_);

    return $self;
}

sub init { }

sub start {
    my $self = shift;
    $self->{_running}    = 1;
    $self->{_stop_tries} = 0;
    $self->{_log}->{trace}->("starting worker");
    $self->emit( start => ('start sub') );
}

sub finish {
    my $self   = shift;
    my $action = shift;
    my $job_id = shift;
    my $cb     = pop;
    my $args   = shift;

    ## FIXME: find a clean way to execute our code *and* the callback
    if ( ref($cb) ne 'CODE' ) {
        $args = $cb;
        $cb = sub { };
    }

    my $internal = sub {
        delete $self->{_jobs}->{$job_id};    ## IMPORTANT

        if ( $self->job_count == $self->concurrency - 1 ) {
            ## we've been waiting for a slot to free up
            $self->emit( start => ('finish sub') );
        }

        $self->{_log}->{info}
          ->( "finished with $job_id ($action); outstanding jobs: "
              . $self->job_count );

#        $cb->($job_id);

        ## we're done
        if ( $self->max_jobs
             and $self->handled_jobs >= $self->max_jobs
             and ! $self->job_count ) {
            $self->{_log}->{info}->("Handled " . $self->handled_jobs . "; quitting");
            return $self->stop;
        }
    };

    eval {
        $self->beanstalk->$action( $job_id, ( $args ? $args : () ), $internal );
    };

    $self->{_log_ctx}->log(
        error => "first argument to finish() must be a beanstalk command: $@" )
      if $@;
}

sub stop {
    my $self = shift;
    $self->{_stop_tries}++;

    if ( $self->{_stop_tries} >= $self->{_max_stop_tries} ) {
        $self->{_log_ctx}->log(
            warn => "stop requested; impatiently quitting outstanding jobs" );
        exit;
    }

    if ( $self->job_count ) {
        $self->{_log_ctx}
          ->log( warn => "stop requested; waiting for outstanding jobs" );
        return;
    }

    $self->{_log_ctx}->log( fatal => "exiting" );
    exit;
}

sub on {
    my ( $self, $event, $cb ) = @_;

    $self->{_cb}->{$event} = $cb;

    $self->{_event}->{$event} = sub {
        my $evt = shift;
        AnyEvent->condvar(
            cb => sub {
                if ( ref( $self->{_cb}->{$evt} ) eq 'CODE' ) {
                    $self->{_log}->{trace}->("event: $evt");
                    my @data = $_[0]->recv;
                    $self->{_log}->{debug}->(
                        "shift event ($evt): " . shift @{ $self->{_events} } );
                    $self->{_log}->{debug}->(
                        "EVENTS (s): " . join( ' ' => @{ $self->{_events} } ) );
                    $self->{_cb}->{$evt}->(@data);
                }

                $self->{_event}->{$evt} = AnyEvent->condvar( cb => __SUB__ );
            }
        );
      }
      ->($event);
}

sub emit {
    my $self  = shift;
    my $event = shift;
    $self->{_log}->{debug}->("push event ($event)");
    push @{ $self->{_events} }, $event;
    $self->{_log}->{debug}
      ->( "EVENTS (p): " . join( ' ' => @{ $self->{_events} } ) );
    $self->{_event}->{$event}->send( $self, @_ );
}

sub beanstalk {
    my $self = shift;
    $self->{_beanstalk} = AnyEvent::Beanstalk->new(@_) if @_;
    return $self->{_beanstalk};
}

sub job_count { scalar keys %{ $_[0]->{_jobs} } }

sub handled_jobs { $_[0]->{_handled_jobs} }

sub max_jobs { $_[0]->{_max_jobs} }

sub concurrency {
    my $self = shift;

    if (@_) {
        $self->{_concurrency} = shift;
    }
    return $self->{_concurrency};
}

1;
__END__

=head1 NAME

AnyEvent::Beanstalk::Worker - Event-driven FSA for beanstalk queues

=head1 SYNOPSIS

  use AnyEvent::Beanstalk::Worker;
  use Data::Dumper;
  use JSON;

  my $w = AnyEvent::Beanstalk::Worker->new(
      concurrency       => 10,
      initial_state     => 'reserved',
      beanstalk_watch   => 'jobs',
      beanstalk_decoder => sub {
          eval { decode_json(shift) };
      }
  );

  $w->on(reserved => sub {
      my $self = shift;
      my ($qjob, $qresp) = @_;

      say "Got a job: " . Dumper($qjob->decode);

      shift->emit( my_next_state => $qjob );
  });

  $w->on(my_next_state => sub {
      my $self = shift;
      my $job  = shift;

      ## do something with job
      ...

      ## maybe not ready yet?
      unless ($job_is_ready) {
          return $self->finish(release => $job->id, { delay => 60 });
      }

      ## all done!
      $self->finish(delete => $job->id);
  });

  $w->start;
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

B<AnyEvent::Beanstalk::Worker> implements a simple, abstract
finite-state automaton for beanstalk queues. It can handle a
configurable number of concurrent jobs, and implements graceful worker
shutdown.

You are encouraged to subclass B<AnyEvent::Beanstalk::Worker> and
implement your own B<init> function, for example, so your object has
access to anything you need in subsequent states.

The L</SUPPLEMENTAL> section below contains additional information
about the various technolgies this module uses.

=head1 METHODS

B<AnyEvent::Beanstalk::Worker> implements these methods:

=head2 new

Create a new object. The B<new> method accepts the following arguments:

=over 4

=item initial_state

Specify an initial state to move to after a job has been reserved. The
handler for this state should expect to receive an
B<AnyEvent::Beanstalk::Job> object and the beanstalk queue response (a
string such as "RESERVED"). Default is undefined--you should supply an
initial state if you want your worker to do anything more than
accepting and deleting jobs from the queue.

=item concurrency

How many concurrent jobs this worker will handle. Set this to a higher
number to process more jobs simultaneously. Defaults to 1.

=item max_jobs

How many jobs this worker will handle before it exits. 0 means the
worker will never exit. Defaults to 0.

=item max_stop_tries

How many C<TERM> or C<INT> signals must be received before we quit,
regardless of outstanding jobs. Defaults to 3.

=item beanstalk_host

The hostname of the beanstalk server. Defaults to 'localhost'.

=item beanstalk_port

The port of the beanstalk server. Defaults to 11300.

=item beanstalk_decoder

A reference to a subroutine responsible for decoding a beanstalk job.
See L<AnyEvent::Beanstalk>.

=item beanstalk_watch

The beanstalk tube to watch. Set this to the same tube your producers
add jobs to. See L<AnyEvent::Beanstalk>.

=item log_level

The default log level. Defaults to 4 (meaning "error"). See
L<AnyEvent::Log>.

=item reserve_timeout

How long in seconds to wait for a job from beanstalk. Defaults to 1
second. After this time, the loop will run again looking for
additional events before trying to reserve another job.

=item release_delay

How long in seconds a job should wait before another worker can take
it. Defaults to 3 seconds.

=back

=head2 init

Called at the end of B<new>; by default this is an empty method. If
you want your worker object to have access to additional "things"
(such as a web user agent object), subclass
B<AnyEvent::Beanstalk::Worker> and implement B<init>:

  package WebWorker;

  use parent 'AnyEvent::Beanstalk::Worker';
  use Mojo::UserAgent;
  sub init { shift->{ua} = Mojo::UserAgent->new }

  1;

Now we can use our B<WebWorker> class:

  use WebWorker;
  use JSON;

  my $w = WebWorker->new(
      concurrency       => 50,
      initial_state     => 'reserved',
      beanstalk_watch   => 'web-jobs',
      beanstalk_decoder => sub {
          eval { decode_json(shift) };
      }
  );

  $w->on(reserved => sub {
      my $self = shift;
      my ($job, $resp) = @_;
      $self->{ua}->get($job->decode->{url},
                       sub { $self->emit(page_found => $job) });
  });

  $w->on(page_found => sub {...});

=head2 start

Starts the worker. Before B<start> is invoked, the worker does not
receive or emit events.

  $w->start;

=head2 stop

Tries to stop the worker. If I<max_stop_tries> is reached or there are
no outstanding jobs, the worker exits immediately. If
I<max_stop_tries> has not yet been reached I<and> the worker has
outstanding jobs, control returns to the event loop until the jobs
complete I<or> I<max_stop_tries> is reached. Sending a C<SIGINT> or
C<SIGTERM> invokes B<stop>.

  $w->stop;

=head2 finish

Should be called when a worker is finished with a job. The first
argument is the beanstalk method to call: C<release>, C<delete>, or
C<bury>.

The second argument is the beanstalk job id. An optional third
argument will be passed to the beanstalk method invoked in the first
argument.

  $w->finish(delete => $job->id);

=head2 on

Registers an event listener.

  $w->on(some_state => sub {
      my $self = shift;

      ...

      $self->emit(next_state => @args);
  });

=head2 emit

Emits an event with optional arguments.

  $self->emit(a_state => ());

=head1 EVENTS

B<AnyEvent::Beanstalk::Worker> emits some events internally, but these
should not be interesting to anyone using the module in most
cases. This module also provides its own handlers for each of these
events. You may override these handlers (via B<on>), but you should
know what you're doing if you do that.

If you use this module, you should emit your own states and provide
your own state handlers for those events, beginning with the handler
for the event you indicated in the constructor's I<initial_state>
argument, which this module will emit for you once a job has been
reserved from the queue.

The following list of internal events is provided for completeness
only and you should generally not emit nor handle these events:

=head2 start

=head2 reserved

=head1 ATTRIBUTES

B<AnyEvent::Beanstalk::Worker> implements the following attributes.

=head2 beanstalk

This is a handle to the internal B<AnyEvent::Beanstalk> object.

=head2 job_count

This returns the number of outstanding jobs this worker is handling.

=head2 handled_jobs

This returns the number of jobs this worker has reserved and begun
work on.

=head2 concurrency

Sets or gets the number of jobs this worker can handle at the same
time.

=head1 SIGNALS

B<AnyEvent::Beanstalk::Worker> receives the following signals:

=head2 INT

A C<INT> signal will cause the worker to invoke its B<stop> method,
which will process any outstanding events before shutting down.

=head2 TERM

A C<TERM> signal is handled in the same way as C<INT>.

=head2 USR2

A C<USR2> signal will bump the log level of the worker up until it
reaches I<trace>; after trace it wraps around and starts again at
I<critical>. See L<AnyEvent::Log> for available log levels.

=head1 LOGGING

B<AnyEvent::Beanstalk::Worker> implements logging via
B<AnyEvent::Log>; it probably doesn't do this as well as it could and
more work needs to be done here.

=head1 EXAMPLES

The F<eg> directory has several working examples of using this module,
including one that shows how to subclass it.

=head1 SUPPLEMENTAL

This section contains additional information not directly needed to
use this module, but may be useful for those unfamiliar with any of
the underlying technologies.

=head2 Caveat

This module represents the current results of an ongoing experiment
involving queues (beanstalk, AnyEvent::Beanstalk), non-blocking and
asynchronous events (AnyEvent), and state machines as means of a
simpler to understand method of event-driven programming.

=head2 Introduction to beanstalk

B<beanstalkd> is a small, fast work queue written in C. When you need
to do lots of jobs (work units--call them what you will), such as
sending an email, fetching and parsing a web page, image processing,
etc.), a I<producer> (a small worker that creates jobs) adds jobs to
the queue. One or more I<consumer> workers come along and ask for jobs
from the queue, and then work on them. When the consumer worker is
done, it deletes the job from the queue and asks for another job.

=head2 Introduction to AnyEvent

B<AnyEvent> is an elegantly designed, generic interface to a variety
of event loops.

=head2 Introduction to state machines

The idea behind state machines is you have a "machine" (or program
modeling a machine) with a set of I<states> and a set of events that
when triggered alter the state of the machine. For example, we could
model a web crawler as a state machine. Our states will be I<get url>,
I<fetch>, I<parse>, and I<add url>, and our events will be I<got url>,
I<fetched>, I<parsed>, and I<added>.

                +---------+
                | get url |
                +-/-----^-+
      (got url)  /       \
                /         \ (added)
         +-----v-+     +---\-----+
         | fetch |     | add url |
         +-----\-+     +-^-------+
      (fetched) \       /
                 \     / (parsed)
                +-v---/-+
                | parse |
                +-------+

In the I<get url> state, we take a URL from a list of URLs (perhaps we
seed it with one URL), then we emit the I<got url> event. This causes
our machine to move to the I<fetch> state. In the I<fetch> state, we
make an HTTP C<GET> request on that URL and then emit the I<fetched>
event, which moves our machine to the I<parse> state where we parse
the incoming web page. Then we add any URLs we find into the queue and
start over.

If we use our B<WebWorker> class above, the result might look like
this:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use feature 'say';

    use WebWorker;

    my $w = WebWorker->new
      ( concurrency     => 1,
        max_stop_tries  => 1,
        initial_state   => 'fetch',
        beanstalk_watch => "urls" );

    ## do this before we call start()
    $w->beanstalk->use("urls")->recv;

    $w->on(fetch => sub {
        my ($self, $job, $resp) = @_;

        say STDERR "fetching " . $job->data;
        $w->{ua}->get($job->data, sub { $self->emit(receive => $job, @_) });
    });

    $w->on(receive => sub {
        my ($self, $job, undef, $tx) = @_;

        if ( $tx->error ) {
            warn "Moved or some error: " . $tx->error;
            return $self->finish(delete => $job->id);
        }

        unless ($tx->res->headers->content_type =~ /html/i) {
            warn "Not HTML; skipping\n";
            return $self->finish(delete => $job->id);
        }

        say STDERR "parsing " . $job->data;
        eval {
            $tx->res->dom->at("html body")->find('a[href]')
              ->each(sub { $self->emit(add_url => shift->{href}) });
        };

        return $self->finish(delete => $job->id);
    });

    $w->on(add_url => sub {
        my ($self, $url) = @_;

        return unless $url =~ /^http/;

        $self->beanstalk
          ->put({ priority => 100,
                  ttr      => 15,
                  delay    => 1,
                  data     => $url },
                sub { say STDERR "URL $url added" });
    });

    $w->start;

    AnyEvent->condvar->recv;

We've just written a simple (and impolite--should read F<robots.txt>)
web crawler.

See F<eg/web-state.pl> and F<eg/web-state-add.pl> for this example.

=head2 Introduction to event loops

I couldn't find any gentle introductions into event loops; I was going
to write one myself but realized it would probably turn into a
book. Additionally, I'm not qualified to write said book. With that
disclaimer, here is a brief, "close enough" introduction to event
loops which may help some people get an approximate mental model, good
enough to begin event programming.

An event loop can be as simple as this:

    my @events = ();
    my %watchers = ();

    while (1) {
        my $event = pop @events;
        handle($event);
    }

    sub handle {
        my $event = shift;

        $_->($event) for @{$watchers{$event->{type}}};
    }

The C<@events> list (or queue, since events are read as a FIFO) might
be populated asynchronously from system events, such as receiving
signals, network data, disk I/O, timers, or other sources. The
C<handle()> subroutine checks the C<%watchers> hash to see if there
are any watchers or handlers for this event and calls those
subroutines as needed. Some of these subroutines may add more events
to the event queue. Then the loop starts again.

Most of the time you never see the event loop--you just start it. For
example, most of the time when I'm programming with B<EV>, this is all
I ever see of it:

    EV::run;

B<EV> receives all kinds of events from the system, but you can tell
it about more events. Then you register event I<handlers> to fire off
when a particular kind of event is received.

=head1 SEE ALSO

B<beanstalkd>, by Keith Rarick: L<http://kr.github.io/beanstalkd/>

B<AnyEvent::Beanstalk>, by Graham Barr: L<AnyEvent::Beanstalk>

B<AnyEvent>, by Marc Lehmann: L<http://anyevent.schmorp.de>

=head1 AUTHOR

Scott Wiersdorf, E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
