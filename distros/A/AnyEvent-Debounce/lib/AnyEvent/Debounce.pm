package AnyEvent::Debounce;
BEGIN {
  $AnyEvent::Debounce::VERSION = '0.01';
}
# ABSTRACT: condense multiple temporally-nearby events into one
use Moose;
use AnyEvent;

has 'front_triggered' => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
    documentation => 'if true, trigger immediately after the first event is received',
);

has 'always_reset_timer' => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 0,
    documentation => 'if true, reset the timer after each event',
);

has 'delay' => (
    is            => 'ro',
    isa           => 'Num',
    default       => 1,
    documentation => 'number of seconds to wait before considering events separate',
);

has 'cb' => (
    is            => 'ro',
    isa           => 'CodeRef',
    required      => 1,
    documentation => 'coderef to run when debounced events are ready',
);

has '_queued_events' => (
    traits   => ['Array'],
    reader   => 'queued_events',
    isa      => 'ArrayRef',
    default  => sub { [] },
    lazy     => 1,
    clearer  => 'clear_queued_events',
    handles  => { 'queue_event' => 'push', 'event_count' => 'count' },
);

has 'timer' => (
    reader     => 'timer',
    lazy_build => 1,
);

sub _build_timer {
    my $self = shift;
    return AnyEvent->timer(
        after    => $self->delay,
        interval => 0,
        cb       => sub { $self->send_events_now },
    );
}

sub send_events_now {
    my $self = shift;
    my $events = $self->queued_events;
    my $count  = $self->event_count;
    $self->clear_timer;
    $self->clear_queued_events;
    $self->cb->(@$events) if $count > 0;
    return;
}

sub send {
    my ($self, @args) = @_;

    my $timer_running = $self->has_timer;
    $self->clear_timer if $self->always_reset_timer;
    $self->timer; # resets the timer if we don't have one

    if($self->front_triggered && !$timer_running){
        $self->cb->([@args]);
    }
    elsif(!$self->front_triggered){
        $self->queue_event([@args]);
    }
    else {
        # warn "discarding event"
    }

    return;
}

1;



=pod

=head1 NAME

AnyEvent::Debounce - condense multiple temporally-nearby events into one

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Create a debouncer:

   my $damper = AnyEvent::Debounce->new( cb => sub {
       my (@events) = @_;
       say "Got ", scalar @events, " event(s) in the batch";
       say "Got event with args: ", join ',', @$_ for @events;
   });

Send it events in rapid succession:

   $damper->send(1,2,3);
   $damper->send(2,3,4);

Watch the output:

   Got 2 events in the batch
   Got event with args: 1,2,3
   Got event with args: 2,3,4

Send it more evnts:

   $damper->send(1);
   sleep 5;
   $damper->send(2);

And notice that there was no need to "debounce" this time:

   Got 1 event in the batch
   Got event with args: 1

   Got 1 event in the batch
   Got event with args: 2

=head1 INITARGS

=head1 cb

The callback to be called when some events are ready to be handled.
Each "event" is an arrayref of the args passed to C<send>.

=head1 delay

The time to wait after receiving an event before sending it, in case
more events happen in the interim.

=head1 always_reset_timer

Normally, when an event is received and it's the first of a series, a
timer is started, and when that timer expires, all events are sent.
If you set this initarg to a true value, then the timer is reset after
each event is received.

For example, if you set the delay to 1, and ten events arrive at 0.5
second intervals, then with this flag set to true, you will get one
event after 5 seconds.  With this flag set to false, you will get an
event once a second for 5 seconds.

By default, this is false, because setting it to true can lead to
events never being sent.  (Imagine you set delay to 10 seconds, and
someone sends an event ever 9.9 seconds.  You'll never get any
events.)

=head1 front_triggered

This flag, when set to true, causes an event to be sent immediately
upon receiving the first event.  Then, you won't get any events for
C<delay> seconds, even if they occur.  These events are lost, you will
never see them.

By default, this is false.

If you also set C<always_reset_timer> to true, the same timer-reset
logic as described above occurs.

=head1 METHODS

=head1 send

Send an event; the handler callback will get everything you pass in.

=head1 REPOSITORY

L<http://github.com/jrockway/anyevent-debounce>

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

