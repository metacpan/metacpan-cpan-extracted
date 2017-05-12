package AnyEvent::Retry;
BEGIN {
  $AnyEvent::Retry::VERSION = '0.03';
}
# ABSTRACT: try something until it works
use Moose;
use MooseX::Types::Common::Numeric qw(PositiveNum);
use AnyEvent::Retry::Types qw(Interval);

use AnyEvent;
use Try::Tiny;
use Scalar::Util qw(weaken);

use true;
use namespace::autoclean;

has 'after' => (
    is      => 'ro',
    isa     => PositiveNum,
    default => 0,
);

has 'interval' => (
    is       => 'ro',
    isa      => Interval,
    required => 1,
    coerce   => 1,
);

has '_sent_result' => (
    accessor => '_sent_result',
    isa      => 'Bool',
    default  => 0,
);

has [qw/try on_failure on_success/] => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has 'max_tries' => (
    is      => 'ro',
    isa     => PositiveNum,
    default => 0,
);

has 'autostart' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has '_timer' => (
    init_arg  => undef,
    writer    => '_set_timer',
    clearer   => 'kill_timer',
    predicate => 'has_timer',
);

sub BUILD {
    my $self = shift;
    $self->start if $self->autostart;
}

sub DEMOLISH {
    my $self = shift;
    $self->kill_timer;

    if(!$self->_sent_result){
        $self->_sent_result(1);
        $self->on_failure->(demolish => 'DEMOLISH');
    }
}

# set a timer to call handle_tick in the future
sub set_timer {
    my ($self, $time, $i) = @_;
    return $self->handle_tick($i) if $time <= 0;

    weaken $self;
    $self->_set_timer(
        AnyEvent->timer( after => $time, cb => sub {
            $self->kill_timer;
            $self->handle_tick($i);
        }),
    );

    return;
}

# called when the timer ticks; start the user's code running
sub handle_tick {
    my ($self, $this_i) = @_;
    $self->run_code;
}

# called when the user's code signals success or error
sub handle_result {
    my ($self, $success, $status, $msg) = @_;

    # if we hit these two cases, we are done forever
    if($success){
        $self->_sent_result(1);
        $self->on_success->($msg);
        return;
    }
    elsif($status =~ /error/){
        $self->_sent_result(1);
        $self->on_failure->( exception => $msg, $status );
        return;
    }

    # no error, but not success (try again later)
    my ($next_time, $next_i) = $self->interval->next;
    if($self->max_tries > 0 && $next_i > $self->max_tries){
        # done forever
        $self->_sent_result(1);
        $self->on_failure->( max_tries => $self->max_tries );
        return;
    }

    # we didn't get the result this time, and we haven't exceeded
    # $max_tries, so set the timer and do the whole thing again
    $self->set_timer( $next_time, $next_i );
    return;
}

# start the user's code running, with a continuation-passing-style
# callback to call when the result is ready
sub run_code {
    my ($self) = @_;

    # we weaken $self here so that if the user does "undef $retry", we
    # DEMOLISH the object and silently discard the results of the
    # running code.  feel free to subclass if want to keep the class
    # alive arbitrarily.
    weaken $self;

    my $success = sub {
        my $result = shift;
        return unless defined $self;
        $self->handle_result(($result ? 1 : 0), 'success', $result);
        return;
    };

    my $error = sub {
        my $msg = shift;
        return unless defined $self;
        $self->handle_result(0, 'run error', $msg);
        return;
    };

    try   { $self->try->($success, $error) }
    catch { $self->handle_result(0, 'startup error', $_) };
    return;
}

# if the timer is running, stop it until resume is called
sub pause {
    my $self = shift;
    $self->kill_timer;
}

# fake a timer tick; run the user code, and set the timer to retry if
# necessary
sub resume {
    my $self = shift;
    $self->kill_timer; # just in case
    $self->handle_tick(0);
}

# start the process.  if the timer is running, die.  if the timer is
# not running, start completely over.
sub start {
    my $self = shift;
    confess 'the job is already running' if $self->has_timer;

    $self->interval->reset;
    $self->_sent_result(0);
    $self->set_timer( $self->after, 0 );
    return;
}

__PACKAGE__->meta->make_immutable;



=pod

=head1 NAME

AnyEvent::Retry - try something until it works

=head1 VERSION

version 0.03

=head1 SYNOPSIS

This module lets you retry a non-blocking task at timed intervals
until it succeeds.

If you work for Aperture Science, something like this might be good:

    my $r = AnyEvent::Retry->new(
        on_failure => sub {
            my ($error_type, $error_message) = @_;
            $condvar->croak($error_message);
        },
        on_success => sub {
            my ($result) = @_;
            $condvar->send($result);
        },
        max_tries => 100, # eventually give up
        interval  => { Constant => { interval => 1 } }, # try every second
        try       => {
            my ($success, $error) = @_;
            $error->('out of cake!') if $cake-- < 0;
            do_science( on_success => $success, on_error => $error );
        },

    );

    $r->start; # keep on trying until you run out of cake
    my $neat_gun = $condvar->recv;

Now, as long as you have cake, you will keep doing science (every
second).  When your science results in the creation of a neat gun,
$neat_gun will contain it.  If there's an error, C<< $condvar->recv >>
will die.

This sort of thing is also good for networking or sysadmin tasks; poll
the mail server until you get an email message, poll a webserver until
the super-hot tickets go on sale (and then buy them), etc.

=head1 METHODS

=head2 new({INITARGS})

Create a new, un-C<start>-ed retry-er object.  If you C<undef> this object,
your job is cancelled and your C<on_failure> callback is notified.

See the INITARGS section below for information on what params to pass.

=head2 start

Start the job.  Dies if the job is already running.

(You can call this again when the job is done to run the job again.)

=head2 pause

Stop the timer, pausing the job until C<resume> is called.

=head2 resume

Resume the task as though the last-running timer just expired.

=head1 INITARGS

=head2 try

Required.  This is the coderef to run repeatedly.  It is passed two
coderefs as args, C<success_cb> and C<error_cb>.  Your coderef must
call one of those; success with a true value if the process is
complete and should not run again, success with a false value if the
process should run again, or error with an error message if the
process failed (and will not run again).

This is "continuation passing style".  It's necessary so that your
C<try> block can kick off asynchronous jobs.

=head2 on_failure

Required.  Callback to call when the job fails.  Called a maximum of one time.

When called, it will be called with two args; the type of error, and
the error message.

The type of error can be C<max_tries>, C<exception>, or C<demolish>.

Note that if C<on_failure> is called, it's guaranteed that
C<on_success> will never be called.

=head2 on_success

Required. Called when your job succeeds.  Called a maximum of one
time.

When called, it will be called with one arg; the value your try block
code passed to the C<success_cb>.

Note that if C<on_success> is called, it's guaranteed that
C<on_failure> will never be called.

=head2 max_tries

Optional.  The maximum number of times to run your job before
considering it failed.

If it's set to 0, then your job will be run an infinite number of
times, subject to the continued existence of the Universe.

Defaults to 0.

=head2 autostart

Optional.  Boolean.  Defaults to 0.

If set to 1, the job will start as soon as the constructor is
finished.  You need not call C<start>.

=head2 interval

Required.  Controls how long to wait between retries.  It must be a
blessed Moose object that does the L<AnyEvent::Retry::Interval> role.

Some existing interval classes are L<AnyEvent::Retry::Constant>,
L<AnyEvent::Retry::Fibonacci>, and L<AnyEvent::Retry::Multi>.

This attribute has a coercion from strings and hashrefs.  If you pass
a string, it will be treated as a class name (under
C<AnyEvent::Retry::Interval::>, unless it is prefxed with a C<+>) to
instantiate.

If you pass a hashref, the first key will be treated as a class name
as above, and the value of that key will be treated as the args to
pass to C<new>.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

