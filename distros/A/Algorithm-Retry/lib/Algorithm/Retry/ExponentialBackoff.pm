package Algorithm::Retry::ExponentialBackoff;

our $DATE = '2019-04-08'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use parent qw(Algorithm::Retry);

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_class_meth => 1,
    is_func => 0,
    args => {
        %Algorithm::Retry::attr_max_attempts,
        %Algorithm::Retry::attr_jitter_factor,
        %Algorithm::Retry::attr_delay_on_success,
        %Algorithm::Retry::attr_max_delay,
        initial_delay => {
            summary => 'Initial delay for the first attempt after failure, '.
                'in seconds',
            schema => 'ufloat*',
            req => 1,
        },
        exponent_base => {
            schema => 'ufloat*',
            default => 2,
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
    my $delay = $self->{initial_delay} *
        $self->{exponent_base} ** ($self->{_attempts}-1);
}

1;
# ABSTRACT: Backoff exponentially

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Retry::ExponentialBackoff - Backoff exponentially

=head1 VERSION

This document describes version 0.001 of Algorithm::Retry::ExponentialBackoff (from Perl distribution Algorithm-Retry), released on 2019-04-08.

=head1 SYNOPSIS

 use Algorithm::Retry::ExponentialBackoff;

 # 1. instantiate

 my $ar = Algorithm::Retry::ExponentialBackoff->new(
     #max_attempts     => 0, # optional, default 0 (retry endlessly)
     #jitter_factor    => 0.25, # optional, default 0
     initial_delay     => 5, # required
     #max_delay        => 100, # optional
     #exponent_base    => 2, # optional, default 2 (binary exponentiation)
     #delay_on_success => 0, # optional, default 0
 );

 # 2. log success/failure and get a new number of seconds to delay, timestamp is
 # optional but must be monotonically increasing.

 # for example, using the parameters initial_delay=5, max_delay=100:

 my $secs;
 $secs = $ar->failure();   # =>  5 (= initial_delay)
 $secs = $ar->failure();   # => 10 (5 * 2^1)
 $secs = $ar->failure();   # => 20 (5 * 2^2)
 sleep 7;
 $secs = $ar->failure();   # => 33 (5 * 2^3 - 7)
 $secs = $ar->failure();   # => 80 (5 * 2^4)
 $secs = $ar->failure();   # => 100 ( min(5 * 2^5, 100) )
 $secs = $ar->success();   # => 0 (= delay_on_success)

=head1 DESCRIPTION

This backoff algorithm calculates the next delay as:

 initial_delay * exponent_base ** (attempts-1)

Only the C<initial_delay> is required. C<exponent_base> is 2 by default (binary
expoential). For the first failure attempt (C<attempts> = 1) the delay equals
the initial delay. Then it is doubled, quadrupled, and so on (using the default
exponent base of 2).

It is recommended to add a jitter factor, e.g. 0.25 to add some randomness.

=head1 METHODS


=head2 new

Usage:

 new(%args) -> obj

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<delay_on_success> => I<ufloat> (default: 0)

Number of seconds to wait after a success.

=item * B<exponent_base> => I<ufloat> (default: 2)

=item * B<initial_delay>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<jitter_factor> => I<float>

How much to add randomness.

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

=item * B<max_attempts> => I<uint> (default: 0)

Maximum number consecutive failures before giving up.

0 means to retry endlessly without ever giving up. 1 means to give up after a
single failure (i.e. no retry attempts). 2 means to retry once after a failure.
Note that after a success, the number of attempts is reset (as expected). So if
max_attempts is 3, and if you fail twice then succeed, then on the next failure
the algorithm will retry again for a maximum of 3 times.

=item * B<max_delay> => I<ufloat>

Maximum delay time, in seconds.

=back

Return value:  (obj)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Algorithm-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Algorithm-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Exponential_backoff>

L<Algorithm::Retry>

Other C<Algorithm::Retry::*> classes.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
