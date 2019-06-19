package Algorithm::Backoff;

our $DATE = '2019-06-18'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Time::HiRes qw(time);

our %SPEC;

our %attr_consider_actual_delay = (
    consider_actual_delay => {
        summary => 'Whether to consider actual delay',
        schema => ['bool*'],
        default => 0,
        tags => ['common'],
        description => <<'_',

If set to true, will take into account the actual delay (timestamp difference).
For example, when using the Constant strategy of delay=2, you log failure()
again right after the previous failure() (i.e. specify the same timestamp).
failure() will then return ~2+2 = 4 seconds. On the other hand, if you waited 2
seconds before calling failure() again (i.e. specify the timestamp that is 2
seconds larger than the previous timestamp), failure() will return 2 seconds.
And if you waited 4 seconds or more, failure() will return 0.

_
    },
);

our %attr_max_actual_duration = (
    max_actual_duration => {
        summary => 'Maximum number of seconds for all of the attempts (0 means unlimited)',
        schema => ['ufloat*'],
        default => 0,
        tags => ['common'],
        description => <<'_',

If set to a positive number, will limit the number of seconds for all of the
attempts. This setting is used to limit the amount of time you are willing to
spend on a task. For example, when using the Exponential strategy of
initial_delay=3 and max_attempts=10, the delays will be 3, 6, 12, 24, ... If
failures are logged according to the suggested delays, and max_actual_duration
is set to 21 seconds, then the third failure() will return -1 instead of 24
because 3+6+12 >= 21, even though max_attempts has not been exceeded.

_
    },
);

our %attr_max_attempts = (
    max_attempts => {
        summary => 'Maximum number consecutive failures before giving up',
        schema => 'uint*',
        default => 0,
        tags => ['common'],
        description => <<'_',

0 means to retry endlessly without ever giving up. 1 means to give up after a
single failure (i.e. no retry attempts). 2 means to retry once after a failure.
Note that after a success, the number of attempts is reset (as expected). So if
max_attempts is 3, and if you fail twice then succeed, then on the next failure
the algorithm will retry again for a maximum of 3 times.

_
    },
);

our %attr_jitter_factor = (
    jitter_factor => {
        summary => 'How much to add randomness',
        schema => ['float*', between=>[0, 0.5]],
        tags => ['common'],
        description => <<'_',

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

The jitter will be applied to delay on failure as well as on success.

_
    },
);

our %attr_delay_on_success = (
    delay_on_success => {
        summary => 'Number of seconds to wait after a success',
        schema => 'ufloat*',
        default => 0,
    },
);

our %attr_max_delay = (
    max_delay => {
        summary => 'Maximum delay time, in seconds',
        schema => 'ufloat*',
         tags => ['common'],
   },
);

our %attr_min_delay = (
    min_delay => {
        summary => 'Maximum delay time, in seconds',
        schema => 'ufloat*',
        default => 0,
        tags => ['common'],
   },
);

our %attr_initial_delay = (
    initial_delay => {
        summary => 'Initial delay for the first attempt after failure, '.
            'in seconds',
        schema => 'ufloat*',
        req => 1,
    },
);

our %attr_delay_multiple_on_failure = (
    delay_multiple_on_failure => {
        summary => 'How much to multiple previous delay, upon failure (e.g. 1.5)',
        schema => 'ufloat*',
        req => 1,
   },
);

our %attr_delay_multiple_on_success = (
    delay_multiple_on_success => {
        summary => 'How much to multiple previous delay, upon success (e.g. 0.5)',
        schema => 'ufloat*',
        req => 1,
   },
);

our %attr_delay_increment_on_failure = (
    delay_increment_on_failure => {
        summary => 'How much to add to previous delay, in seconds, upon failure (e.g. 5)',
        schema => 'float*',
        req => 1,
   },
);

our %attr_delay_increment_on_success = (
    delay_increment_on_success => {
        summary => 'How much to add to previous delay, in seconds, upon success (e.g. -5)',
        schema => 'float*',
        req => 1,
   },
);

$SPEC{new} = {
    v => 1.1,
    is_class_meth => 1,
    is_func => 0,
    args => {
        %attr_max_attempts,
        %attr_jitter_factor,
    },
    result_naked => 1,
    result => {
        schema => 'obj*',
    },
};
sub new {
    my ($class, %args) = @_;

    my $attrspec = ${"$class\::SPEC"}{new}{args};

    # check known attributes
    for my $arg (keys %args) {
        $arg =~ /\A(_start_timestamp)\z/ and next;
        $attrspec->{$arg} or die "$class: Unknown attribute '$arg'";
    }
    # check required attributes and set default
    for my $attr (keys %$attrspec) {
        if ($attrspec->{$attr}{req}) {
            exists($args{$attr})
                or die "$class: Missing required attribute '$attr'";
        }
        if (exists $attrspec->{$attr}{default}) {
            $args{$attr} //= $attrspec->{$attr}{default};
        }
    }
    $args{_attempts} = 0;
    $args{_start_timestamp} //= time();
    bless \%args, $class;
}

sub _consider_actual_delay {
    my ($self, $delay, $timestamp) = @_;

    $self->{_last_delay} //= 0;
    my $actual_delay = $timestamp - $self->{_last_timestamp};
    my $new_delay = $delay + $self->{_last_delay} - $actual_delay;
    $self->{_last_delay} = $new_delay;
    $new_delay;
}

sub _add_jitter {
    my ($self, $delay) = @_;
    return $delay unless $delay && $self->{jitter_factor};
    my $min = $delay * (1-$self->{jitter_factor});
    my $max = $delay * (1+$self->{jitter_factor});
    $min + ($max-$min)*rand();
}

sub _success_or_failure {
    my ($self, $is_success, $timestamp) = @_;

    $self->{_last_timestamp} //= $timestamp;
    $timestamp >= $self->{_last_timestamp} or
        die ref($self).": Decreasing timestamp ".
        "($self->{_last_timestamp} -> $timestamp)";

    my $delay = $is_success ?
        $self->_success($timestamp) : $self->_failure($timestamp);

    $delay = $self->_consider_actual_delay($delay, $timestamp)
        if $self->{consider_actual_delay};

    $delay = $self->_add_jitter($delay)
        if $self->{jitter_factor};

    # keep between max(0, min_delay) and max_delay
    $delay = $self->{max_delay}
        if defined $self->{max_delay} && $delay > $self->{max_delay};
    $delay = 0 if $delay < 0;
    $delay = $self->{min_delay}
        if defined $self->{min_delay} && $delay < $self->{min_delay};

    $self->{_last_timestamp} = $timestamp;
    $self->{_prev_delay}     = $delay;
    $delay;
}

sub success {
    my ($self, $timestamp) = @_;

    $timestamp //= time();

    $self->{_attempts} = 0;

    $self->_success_or_failure(1, $timestamp);
}

sub failure {
    my ($self, $timestamp) = @_;

    $timestamp //= time();

    return -1 if defined $self->{max_actual_duration} &&
        $self->{max_actual_duration} > 0 &&
        $timestamp - $self->{_start_timestamp} >= $self->{max_actual_duration};

    $self->{_attempts}++;
    return -1 if $self->{max_attempts} &&
        $self->{_attempts} >= $self->{max_attempts};

    $self->_success_or_failure(0, $timestamp);
}

1;
# ABSTRACT: Various backoff strategies for retry

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Backoff - Various backoff strategies for retry

=head1 VERSION

This document describes version 0.007 of Algorithm::Backoff (from Perl distribution Algorithm-Backoff), released on 2019-06-18.

=head1 SYNOPSIS

 # 1. pick a strategy and instantiate

 use Algorithm::Backoff::Constant;
 my $ab = Algorithm::Backoff::Constant->new(
     delay             => 2, # required
     #delay_on_success => 0, # optional, default 0
 );

 # 2. log success/failure and get a new number of seconds to delay, timestamp is
 # optional but must be monotonically increasing.

 my $secs = $ab->failure(); # => 2
 my $secs = $ab->success(); # => 0
 my $secs = $ab->failure(); # => 2

=head1 DESCRIPTION

This distribution provides several classes that implement various backoff
strategies for setting delay between retry attempts.

This class (C<Algorithm::Backoff>) is a base class only.

=head1 METHODS


=head2 new

Usage:

 new(%args) -> obj

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<jitter_factor> => I<float>

How much to add randomness.

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

The jitter will be applied to delay on failure as well as on success.

=item * B<max_attempts> => I<uint> (default: 0)

Maximum number consecutive failures before giving up.

0 means to retry endlessly without ever giving up. 1 means to give up after a
single failure (i.e. no retry attempts). 2 means to retry once after a failure.
Note that after a success, the number of attempts is reset (as expected). So if
max_attempts is 3, and if you fail twice then succeed, then on the next failure
the algorithm will retry again for a maximum of 3 times.

=back

Return value:  (obj)


=head2 success

Usage:

 my $secs = $obj->success([ $timestamp ]);

Log a successful attempt. If not specified, C<$timestamp> defaults to current
time. Will return the suggested number of seconds to wait before doing another
attempt.

=head2 failure

Usage:

 my $secs = $obj->failure([ $timestamp ]);

Log a failed attempt. If not specified, C<$timestamp> defaults to current time.
Will return the suggested number of seconds to wait before doing another
attempt, or -1 if it suggests that one gives up (e.g. if C<max_attempts>
parameter has been exceeded).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Algorithm-Backoff>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Algorithm-Backoff>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Backoff>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Action::Retry> - Somehow I didn't find this module before writing
Algorithm::Backoff. Otherwise I would probably not created Algorithm::Backoff.
But Algorithm::Backoff offers an alternative interface, a lighter footprint (no
Moo), and a couple more strategies.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
