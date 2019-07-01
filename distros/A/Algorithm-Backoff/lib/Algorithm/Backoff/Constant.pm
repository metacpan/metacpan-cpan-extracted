package Algorithm::Backoff::Constant;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.009'; # VERSION

use strict;
use warnings;

use parent qw(Algorithm::Backoff);

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_class_meth => 1,
    is_func => 0,
    args => {
        %Algorithm::Backoff::attr_consider_actual_delay,
        %Algorithm::Backoff::attr_max_actual_duration,
        %Algorithm::Backoff::attr_max_attempts,
        %Algorithm::Backoff::attr_jitter_factor,
        %Algorithm::Backoff::attr_delay_on_success,
        %Algorithm::Backoff::attr_min_delay,
        %Algorithm::Backoff::attr_max_delay,
        delay => {
            summary => 'Number of seconds to wait after a failure',
            schema => 'ufloat*',
            req => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => 'obj*',
    },
};

sub _success {
    my ($self, $timestamp) = @_;
    $self->{delay_on_success};
}

sub _failure {
    my ($self, $timestamp) = @_;
    $self->{delay};
}

1;
# ABSTRACT: Backoff using a constant delay

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Backoff::Constant - Backoff using a constant delay

=head1 VERSION

This document describes version 0.009 of Algorithm::Backoff::Constant (from Perl distribution Algorithm-Backoff), released on 2019-06-20.

=head1 SYNOPSIS

 use Algorithm::Backoff::Constant;

 # 1. instantiate

 my $ab = Algorithm::Backoff::Constant->new(
     #consider_actual_delay => 1, # optional, default 0
     #max_actual_duration   => 0, # optional, default 0 (retry endlessly)
     #max_attempts          => 0, # optional, default 0 (retry endlessly)
     #jitter_factor         => 0, # optional, set to positive value to add randomness
     delay                  => 2, # required
     #delay_on_success      => 0, # optional, default 0
 );

 # 2. log success/failure and get a new number of seconds to delay, timestamp is
 # optional argument (default is current time) but must be monotonically
 # increasing.

 my $secs = $ab->failure(1554652553); # => 2
 my $secs = $ab->success();           # => 0
 my $secs = $ab->failure();           # => 2

Illustration using CLI L<show-backoff-delays> (5 failures followed by 3
successes):

 % show-backoff-delays -a Constant --delay 2 \
     0 0 0 0 0   1 1 1
 2
 2
 2
 2
 2
 0
 0
 0

=head1 DESCRIPTION

This backoff strategy is one of the simplest: it waits X second(s) after each
failure, or Y second(s) (default 0) after a success. There are limits on the
number of attempts (`max_attempts`) and total duration (`max_actual_duration`).
Some randomness can be introduced to avoid "thundering herd problem".

=head1 METHODS


=head2 new

Usage:

 new(%args) -> obj

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<consider_actual_delay> => I<bool> (default: 0)

Whether to consider actual delay.

If set to true, will take into account the actual delay (timestamp difference).
For example, when using the Constant strategy of delay=2, you log failure()
again right after the previous failure() (i.e. specify the same timestamp).
failure() will then return ~2+2 = 4 seconds. On the other hand, if you waited 2
seconds before calling failure() again (i.e. specify the timestamp that is 2
seconds larger than the previous timestamp), failure() will return 2 seconds.
And if you waited 4 seconds or more, failure() will return 0.

=item * B<delay>* => I<ufloat>

Number of seconds to wait after a failure.

=item * B<delay_on_success> => I<ufloat> (default: 0)

Number of seconds to wait after a success.

=item * B<jitter_factor> => I<float>

How much to add randomness.

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

The jitter will be applied to delay on failure as well as on success.

=item * B<max_actual_duration> => I<ufloat> (default: 0)

Maximum number of seconds for all of the attempts (0 means unlimited).

If set to a positive number, will limit the number of seconds for all of the
attempts. This setting is used to limit the amount of time you are willing to
spend on a task. For example, when using the Exponential strategy of
initial_delay=3 and max_attempts=10, the delays will be 3, 6, 12, 24, ... If
failures are logged according to the suggested delays, and max_actual_duration
is set to 21 seconds, then the third failure() will return -1 instead of 24
because 3+6+12 >= 21, even though max_attempts has not been exceeded.

=item * B<max_attempts> => I<uint> (default: 0)

Maximum number consecutive failures before giving up.

0 means to retry endlessly without ever giving up. 1 means to give up after a
single failure (i.e. no retry attempts). 2 means to retry once after a failure.
Note that after a success, the number of attempts is reset (as expected). So if
max_attempts is 3, and if you fail twice then succeed, then on the next failure
the algorithm will retry again for a maximum of 3 times.

=item * B<max_delay> => I<ufloat>

Maximum delay time, in seconds.

=item * B<min_delay> => I<ufloat> (default: 0)

Maximum delay time, in seconds.

=back

Return value:  (obj)

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

L<Algorithm::Backoff>

Other C<Algorithm::Backoff::*> classes.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
