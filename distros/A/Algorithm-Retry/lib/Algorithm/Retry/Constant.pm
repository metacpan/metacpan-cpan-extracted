package Algorithm::Retry::Constant;

our $DATE = '2019-04-10'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use parent qw(Algorithm::Retry);

our %SPEC;

$SPEC{new} = {
    v => 1.1,
    is_class_meth => 1,
    is_func => 0,
    args => {
        %Algorithm::Retry::attr_consider_actual_delay,
        %Algorithm::Retry::attr_max_attempts,
        %Algorithm::Retry::attr_jitter_factor,
        %Algorithm::Retry::attr_delay_on_success,
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
# ABSTRACT: Retry using a constant wait time

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Retry::Constant - Retry using a constant wait time

=head1 VERSION

This document describes version 0.002 of Algorithm::Retry::Constant (from Perl distribution Algorithm-Retry), released on 2019-04-10.

=head1 SYNOPSIS

 use Algorithm::Retry::Constant;

 # 1. instantiate

 my $ar = Algorithm::Retry::Constant->new(
     #consider_actual_delay => 1, # optional, default 0
     #max_attempts     => 0, # optional, default 0 (retry endlessly)
     #jitter_factor    => 0, # optional, set to positive value to add randomness
     delay             => 2, # required
     #delay_on_success => 0, # optional, default 0
 );

 # 2. log success/failure and get a new number of seconds to delay, timestamp is
 # optional argument (default is current time) but must be monotonically
 # increasing.

 my $secs = $ar->failure(1554652553); # => 2
 my $secs = $ar->success();           # => 0
 my $secs = $ar->failure();           # => 2

=head1 DESCRIPTION

This retry strategy is one of the simplest: it waits X second(s) after each
failure, or Y second(s) (default 0) after a success. Some randomness can be
introduced to avoid "thundering herd problem".

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

=item * B<max_attempts> => I<uint> (default: 0)

Maximum number consecutive failures before giving up.

0 means to retry endlessly without ever giving up. 1 means to give up after a
single failure (i.e. no retry attempts). 2 means to retry once after a failure.
Note that after a success, the number of attempts is reset (as expected). So if
max_attempts is 3, and if you fail twice then succeed, then on the next failure
the algorithm will retry again for a maximum of 3 times.

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

L<Algorithm::Retry>

Other C<Algorithm::Retry::*> classes.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
