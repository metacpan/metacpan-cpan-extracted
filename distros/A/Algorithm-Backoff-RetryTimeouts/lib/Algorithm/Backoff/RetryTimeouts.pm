package Algorithm::Backoff::RetryTimeouts;

use utf8;
use strict;
use warnings;

use Algorithm::Backoff::Exponential;
use base qw< Algorithm::Backoff::Exponential >;

use Storable    qw< dclone >;
use Time::HiRes qw< time   >;

use namespace::clean;

# ABSTRACT: A backoff-style retry algorithm with adjustable timeout support
use version;
our $VERSION = 'v1.0.0'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod     use Algorithm::Backoff::RetryTimeouts;
#pod
#pod     my $retry_algo = Algorithm::Backoff::RetryTimeouts->new(
#pod         # common adjustments (defaults shown)
#pod         max_attempts          => 8,
#pod         max_actual_duration   => 50,
#pod         jitter_factor         => 0.1,
#pod         timeout_jitter_factor => 0.1,
#pod         adjust_timeout_factor => 0.5,
#pod         min_adjust_timeout    => 5,
#pod
#pod         # other defaults
#pod         initial_delay         => sqrt(2),
#pod         exponent_base         => sqrt(2),
#pod         delay_on_success      => 0,
#pod         min_delay             => 0,
#pod         max_delay             => undef,
#pod         consider_actual_delay => 1,
#pod     );
#pod
#pod     my ($delay, $timeout);
#pod     $timeout = $retry_algo->timeout;
#pod
#pod     my $is_successful = 0;
#pod     while (!$is_successful) {
#pod         $actionee->timeout( $timeout );
#pod         $is_successful = $actionee->do_the_thing;
#pod
#pod         ($delay, $timeout) = $is_successful ? $retry_algo->success : $retry_algo->failure;
#pod         die "Ran out of time" if $delay == -1;
#pod         sleep $delay;
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module is a subclass of L<Algorithm::Backoff::Exponential> that adds support for
#pod adjustable timeouts during each retry.  This also comes with a sane set of defaults as a
#pod good baseline for most kinds of retry operations.
#pod
#pod A combination of features solves for most problems that would arise from retry operations:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod B<Maximum attempts> - Forces the algorithm to give up if repeated attempts don't yield
#pod success.
#pod
#pod =item *
#pod
#pod B<Maximum duration> - Forces the algorithm to give up if no successes happen within a
#pod certain time frame.
#pod
#pod =item *
#pod
#pod B<Exponential backoff> - A C<sqrt(2)> exponential delay keeps single retries from waiting
#pod too long, while spreading out repeated retries that may fail too quickly and run out of
#pod max attempts.  This also decreases the congestion that happens with repeated attempts.
#pod
#pod =item *
#pod
#pod B<Jitter> - Adding random jitter to the retry delays solves for the Thundering Herd
#pod problem.
#pod
#pod =item *
#pod
#pod B<Adjustable timeouts> - Providing an adjustable timeout after each request solves the
#pod opposite problem of exponential backoffs: slower, unresponsive errors that gobble up all
#pod of the max duration time in one go.  Each new timeout is a certain percentage of the time
#pod left.
#pod
#pod =back
#pod
#pod =head2 Typical scenario
#pod
#pod Here's an example scenario of the algorithm with existing defaults:
#pod
#pod     $retry_algo is created, and timer starts
#pod
#pod     Initial timeout is 25s
#pod
#pod     1st attempt fails instantly
#pod
#pod     $retry_algo says to wait 1.4s (±10% jitter), and use a timeout of 24.3s
#pod
#pod     2nd attempt fails instantly
#pod
#pod     $retry_algo says to wait 2s (±10% jitter), and use a timeout of 23.3s
#pod
#pod     3rd attempt fails after the full 23.3s timeout
#pod
#pod     $retry_algo says to not wait (since the attempt already used up the delay), and use
#pod     a timeout of 11.7s
#pod
#pod     4th attempt succeeds
#pod
#pod =cut

our %SPEC = %{ dclone \%Algorithm::Backoff::Exponential::SPEC };

{
    my $args = $SPEC{new}{args};

    # Our defaults
    $args->{consider_actual_delay}{default} = 1;
    $args->{max_attempts         }{default} = 8;
    $args->{max_actual_duration  }{default} = 50;
    $args->{jitter_factor        }{default} = 0.1;
    $args->{initial_delay        }{default} = sqrt(2);
    $args->{exponent_base        }{default} = sqrt(2);

    # No need to require what already has a default
    $args->{initial_delay}{req} = 0;

    # New arguments
    $args->{adjust_timeout_factor} = {
        summary => 'How much of the time left to use in the adjustable timeout',
        schema  => ['ufloat*', between=>[0, 1]],
        default => 0.5,
    };
    $args->{min_adjust_timeout} = {
        summary => 'Minimum adjustable timeout, in seconds',
        schema  => 'ufloat*',
        default => 5,
    };
    $args->{timeout_jitter_factor} = {
        summary => 'How much randomness to add to the adjustable timeout',
        schema  => ['float*', between=>[0, 0.5]],
        default => 0.1,
    };
}

#pod =head1 CONSTRUCTOR
#pod
#pod The L<"new"|Algorithm::Backoff::Exponential/new> constructor takes all of the base options
#pod from L<Algorithm::Backoff::Exponential>. Some of the defaults are changed (also shown in
#pod the L</SYNOPSIS> above), but otherwise function the same way.
#pod
#pod =over
#pod
#pod =item * L<max_attempts|Algorithm::Backoff::Exponential/new> => I<uint> (default: 8)
#pod
#pod =item * L<max_actual_duration|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 50)
#pod
#pod =item * L<jitter_factor|Algorithm::Backoff::Exponential/new> => I<float> (default: 0.1)
#pod
#pod =item * L<initial_delay|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: C<sqrt(2)>)
#pod
#pod =item * L<exponent_base|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: C<sqrt(2)>)
#pod
#pod =item * L<delay_on_success|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 0)
#pod
#pod =item * L<min_delay|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 0)
#pod
#pod =item * L<max_delay|Algorithm::Backoff::Exponential/new> => I<ufloat>
#pod
#pod =item * L<consider_actual_delay|Algorithm::Backoff::Exponential/new> => I<bool> (default: 1)
#pod
#pod =back
#pod
#pod The following new options are added in this module:
#pod
#pod =over
#pod
#pod =item * adjust_timeout_factor => I<ufloat> (default: 0.5)
#pod
#pod How much of the remaining time to use for the next attempt's timeout, as a
#pod factor between 0 and 1.
#pod
#pod In order to prevent a single attempt from using up all of the remaining time, an
#pod adjustable timeout will force the attempt to only use a portion of the time.  By default,
#pod only 50% of the remaining time will be set as the next timeout value.
#pod
#pod =item * min_adjust_timeout => I<ufloat> (default: 5)
#pod
#pod Minimum timeout value, in seconds.
#pod
#pod This value bypasses any C<max_actual_duration> checks, so the total time spent on
#pod sleeping and attempts may end up exceeding that value by a small amount (up to
#pod C<max_actual_duration + min_adjust_timeout>).  In this case, future failures will return
#pod a delay of C<-1> as expected.
#pod
#pod =item * timeout_jitter_factor => I<float> (default: 0.1)
#pod
#pod How much randomness to add to the adjustable timeout.
#pod
#pod Delay jitter may not be enough to desynchronize two processes that are consistently
#pod timing out on the same problem.  In those cases, the delay will usually be zero and won't
#pod have any sort of jitter to solve the problem itself.  A jitter factor against the timeout
#pod will ensure simultaneous attempts have slightly different timeout windows.
#pod
#pod =back
#pod
#pod =head1 METHODS
#pod
#pod =head2 success
#pod
#pod     my ($delay, $timeout) = $retry_algo->success([ $timestamp ]);
#pod
#pod Log a successful attempt.  If not specified, C<$timestamp> defaults to current time.
#pod Unlike the L<base class|Algorithm::Backoff>, this method will return a list containing
#pod both the L<suggested delay|/delay> and the L<suggested timeout|/timeout> for the next
#pod attempt.
#pod
#pod =head2 failure
#pod
#pod     my ($delay, $timeout) = $retry_algo->failure([ $timestamp ]);
#pod
#pod Log a failed attempt.  If not specified, C<$timestamp> defaults to current time.
#pod Unlike the L<base class|Algorithm::Backoff>, this method will return a list containing
#pod both the L<suggested delay|/delay> and the L<suggested timeout|/timeout> for the next
#pod attempt.
#pod
#pod =cut

sub failure {
    my ($self, $timestamp) = @_;
    $timestamp //= time;

    my ($delay, $timeout) = $self->SUPER::failure($timestamp);

    # Fix certain values if the check failed max duration/attempts checks
    $timeout //= $self->timeout;
    if ($delay == -1) {
        $self->{_attempts}++;
        $self->{_last_timestamp} = $timestamp;
    }

    return ($delay, $timeout);
}

#pod =head2 delay
#pod
#pod     my $delay = $retry_algo->delay;
#pod
#pod Returns the last suggested delay, in seconds.
#pod
#pod The delay will return C<-1> to suggest that the process should give up and fail, if
#pod C<max_attempts> or C<max_actual_duration> have been reached.
#pod
#pod =cut

sub delay {
    my $self = shift;
    return $self->{_prev_delay} // 0;
}

#pod =head2 timeout
#pod
#pod     my $timeout = $retry_algo->delay;
#pod
#pod Returns the last suggested timeout, in seconds.  If no attempts have been logged,
#pod it will suggest an initial timeout to start with.
#pod
#pod This will be a floating-point number, so you may need to convert it to an integer if your
#pod timeout system doesn't support decimals.
#pod
#pod A timeout of C<-1> will be returned if C<max_actual_duration> was forcefully turned off.
#pod
#pod =cut

sub timeout {
    my $self = shift;

    my $last_timeout   = $self->{_last_timeout};
    my $min_time       = $self->{min_adjust_timeout};
    my $max_time       = $self->{max_actual_duration};
    my $timeout_factor = $self->{adjust_timeout_factor};

    return $last_timeout if defined $last_timeout;
    return -1 unless $max_time;

    my $timeout = $max_time * $timeout_factor;
    $timeout = $self->_add_timeout_jitter($timeout) if $self->{timeout_jitter_factor};
    $timeout = $min_time if $min_time > $timeout;
    return $timeout;
}

sub _set_last_timeout {
    my ($self, $delay, $timestamp) = @_;

    my $start_time     = $self->{_start_timestamp};
    my $min_time       = $self->{min_adjust_timeout};
    my $max_time       = $self->{max_actual_duration};
    my $timeout_factor = $self->{adjust_timeout_factor};
    return ($delay // 0, -1) unless defined $start_time && $max_time;

    $timestamp //= $self->{_last_timestamp} // $self->{_start_timestamp};

    # Calculate initial timeout
    my $actual_time_used = $timestamp - $start_time;
    my $actual_time_left = $max_time - $actual_time_used;
    my $timeout          = $actual_time_left * $timeout_factor;

    # Ensure the delay+timeout time isn't going to go over the limit
    $delay //= 0;
    my $max_delay = $actual_time_left * (1 - $timeout_factor);
    $delay = $max_delay if $delay > $max_delay;

    # Re-adjust the timeout based on the final delay and min timeout setting
    $timeout = ($actual_time_left - $delay) * $timeout_factor;
    $timeout = $self->_add_timeout_jitter($timeout) if $self->{timeout_jitter_factor};
    $timeout = $min_time if $min_time > $timeout;

    $self->{_prev_delay}   = $delay;
    $self->{_last_timeout} = $timeout;

    return ($delay, $timeout);
}

sub _add_timeout_jitter {
    my ($self, $timeout) = @_;
    my $jitter = $self->{timeout_jitter_factor};
    return $timeout unless $timeout && $jitter;

    my $min = $timeout * (1 - $jitter);
    my $max = $timeout * (1 + $jitter);
    return $min + ($max - $min) * rand();
}

sub _consider_actual_delay {
    my $self = shift;

    # See https://github.com/perlancar/perl-Algorithm-Backoff/issues/1
    $self->{_last_delay} = $self->{_prev_delay} //= 0;

    return $self->SUPER::_consider_actual_delay(@_);
}

sub _success_or_failure {
    my ($self, $is_success, $timestamp) = @_;

    # If this is the first time, the _last_timestamp should be set to the start, not
    # $timestamp.  This will prevent issues with the first attempt causing unnecessary
    # delays (ie: waiting 1.4s after the first attempt took longer than that).
    $self->{_last_timestamp} //= $self->{_start_timestamp};

    my $delay = $self->SUPER::_success_or_failure($is_success, $timestamp);
    return $self->_set_last_timeout($delay, $timestamp);
}

#pod =head1 SEE ALSO
#pod
#pod L<Algorithm::Backoff> - Base distro for this module
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Backoff::RetryTimeouts - A backoff-style retry algorithm with adjustable timeout support

=head1 VERSION

version v1.0.0

=head1 SYNOPSIS

    use Algorithm::Backoff::RetryTimeouts;

    my $retry_algo = Algorithm::Backoff::RetryTimeouts->new(
        # common adjustments (defaults shown)
        max_attempts          => 8,
        max_actual_duration   => 50,
        jitter_factor         => 0.1,
        timeout_jitter_factor => 0.1,
        adjust_timeout_factor => 0.5,
        min_adjust_timeout    => 5,

        # other defaults
        initial_delay         => sqrt(2),
        exponent_base         => sqrt(2),
        delay_on_success      => 0,
        min_delay             => 0,
        max_delay             => undef,
        consider_actual_delay => 1,
    );

    my ($delay, $timeout);
    $timeout = $retry_algo->timeout;

    my $is_successful = 0;
    while (!$is_successful) {
        $actionee->timeout( $timeout );
        $is_successful = $actionee->do_the_thing;

        ($delay, $timeout) = $is_successful ? $retry_algo->success : $retry_algo->failure;
        die "Ran out of time" if $delay == -1;
        sleep $delay;
    }

=head1 DESCRIPTION

This module is a subclass of L<Algorithm::Backoff::Exponential> that adds support for
adjustable timeouts during each retry.  This also comes with a sane set of defaults as a
good baseline for most kinds of retry operations.

A combination of features solves for most problems that would arise from retry operations:

=over

=item *

B<Maximum attempts> - Forces the algorithm to give up if repeated attempts don't yield
success.

=item *

B<Maximum duration> - Forces the algorithm to give up if no successes happen within a
certain time frame.

=item *

B<Exponential backoff> - A C<sqrt(2)> exponential delay keeps single retries from waiting
too long, while spreading out repeated retries that may fail too quickly and run out of
max attempts.  This also decreases the congestion that happens with repeated attempts.

=item *

B<Jitter> - Adding random jitter to the retry delays solves for the Thundering Herd
problem.

=item *

B<Adjustable timeouts> - Providing an adjustable timeout after each request solves the
opposite problem of exponential backoffs: slower, unresponsive errors that gobble up all
of the max duration time in one go.  Each new timeout is a certain percentage of the time
left.

=back

=head2 Typical scenario

Here's an example scenario of the algorithm with existing defaults:

    $retry_algo is created, and timer starts

    Initial timeout is 25s

    1st attempt fails instantly

    $retry_algo says to wait 1.4s (±10% jitter), and use a timeout of 24.3s

    2nd attempt fails instantly

    $retry_algo says to wait 2s (±10% jitter), and use a timeout of 23.3s

    3rd attempt fails after the full 23.3s timeout

    $retry_algo says to not wait (since the attempt already used up the delay), and use
    a timeout of 11.7s

    4th attempt succeeds

=head1 CONSTRUCTOR

The L<"new"|Algorithm::Backoff::Exponential/new> constructor takes all of the base options
from L<Algorithm::Backoff::Exponential>. Some of the defaults are changed (also shown in
the L</SYNOPSIS> above), but otherwise function the same way.

=over

=item * L<max_attempts|Algorithm::Backoff::Exponential/new> => I<uint> (default: 8)

=item * L<max_actual_duration|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 50)

=item * L<jitter_factor|Algorithm::Backoff::Exponential/new> => I<float> (default: 0.1)

=item * L<initial_delay|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: C<sqrt(2)>)

=item * L<exponent_base|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: C<sqrt(2)>)

=item * L<delay_on_success|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 0)

=item * L<min_delay|Algorithm::Backoff::Exponential/new> => I<ufloat> (default: 0)

=item * L<max_delay|Algorithm::Backoff::Exponential/new> => I<ufloat>

=item * L<consider_actual_delay|Algorithm::Backoff::Exponential/new> => I<bool> (default: 1)

=back

The following new options are added in this module:

=over

=item * adjust_timeout_factor => I<ufloat> (default: 0.5)

How much of the remaining time to use for the next attempt's timeout, as a
factor between 0 and 1.

In order to prevent a single attempt from using up all of the remaining time, an
adjustable timeout will force the attempt to only use a portion of the time.  By default,
only 50% of the remaining time will be set as the next timeout value.

=item * min_adjust_timeout => I<ufloat> (default: 5)

Minimum timeout value, in seconds.

This value bypasses any C<max_actual_duration> checks, so the total time spent on
sleeping and attempts may end up exceeding that value by a small amount (up to
C<max_actual_duration + min_adjust_timeout>).  In this case, future failures will return
a delay of C<-1> as expected.

=item * timeout_jitter_factor => I<float> (default: 0.1)

How much randomness to add to the adjustable timeout.

Delay jitter may not be enough to desynchronize two processes that are consistently
timing out on the same problem.  In those cases, the delay will usually be zero and won't
have any sort of jitter to solve the problem itself.  A jitter factor against the timeout
will ensure simultaneous attempts have slightly different timeout windows.

=back

=head1 METHODS

=head2 success

    my ($delay, $timeout) = $retry_algo->success([ $timestamp ]);

Log a successful attempt.  If not specified, C<$timestamp> defaults to current time.
Unlike the L<base class|Algorithm::Backoff>, this method will return a list containing
both the L<suggested delay|/delay> and the L<suggested timeout|/timeout> for the next
attempt.

=head2 failure

    my ($delay, $timeout) = $retry_algo->failure([ $timestamp ]);

Log a failed attempt.  If not specified, C<$timestamp> defaults to current time.
Unlike the L<base class|Algorithm::Backoff>, this method will return a list containing
both the L<suggested delay|/delay> and the L<suggested timeout|/timeout> for the next
attempt.

=head2 delay

    my $delay = $retry_algo->delay;

Returns the last suggested delay, in seconds.

The delay will return C<-1> to suggest that the process should give up and fail, if
C<max_attempts> or C<max_actual_duration> have been reached.

=head2 timeout

    my $timeout = $retry_algo->delay;

Returns the last suggested timeout, in seconds.  If no attempts have been logged,
it will suggest an initial timeout to start with.

This will be a floating-point number, so you may need to convert it to an integer if your
timeout system doesn't support decimals.

A timeout of C<-1> will be returned if C<max_actual_duration> was forcefully turned off.

=head1 SEE ALSO

L<Algorithm::Backoff> - Base distro for this module

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 - 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
