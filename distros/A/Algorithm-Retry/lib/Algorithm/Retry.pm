package Algorithm::Retry;

our $DATE = '2019-04-10'; # DATE
our $VERSION = '0.002'; # VERSION

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

our %attr_max_attempts = (
    max_attempts => {
        summary => 'Maximum number consecutive failures before giving up',
        schema => 'uint*',
        default => 0,
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
        description => <<'_',

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

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
    bless \%args, $class;
}

sub _success_or_failure {
    my ($self, $is_success, $timestamp) = @_;

    $self->{_last_timestamp} //= $timestamp;
    $timestamp >= $self->{_last_timestamp} or
        die ref($self).": Decreasing timestamp ".
        "($self->{_last_timestamp} -> $timestamp)";
    my $delay = $is_success ?
        $self->_success($timestamp) : $self->_failure($timestamp);
    $delay = $self->{max_delay}
        if defined $self->{max_delay} && $delay > $self->{max_delay};
    $delay;
}

sub _consider_actual_delay {
    my ($self, $delay, $timestamp) = @_;

    $self->{_last_delay} //= 0;
    my $actual_delay = $timestamp - $self->{_last_timestamp};
    my $new_delay = $delay + $self->{_last_delay} - $actual_delay;
    $self->{_last_delay} = $new_delay;
    $new_delay;
}

sub success {
    my ($self, $timestamp) = @_;

    $timestamp //= time();

    $self->{_attempts} = 0;

    my $delay = $self->_success_or_failure(1, $timestamp);
    $delay = $self->_consider_actual_delay($delay, $timestamp)
        if $self->{consider_actual_delay};
    $self->{_last_timestamp} = $timestamp;
    return 0 if $delay < 0;

    $self->_add_jitter($delay);
}

sub failure {
    my ($self, $timestamp) = @_;

    $timestamp //= time();

    $self->{_attempts}++;
    return -1 if $self->{max_attempts} &&
        $self->{_attempts} >= $self->{max_attempts};

    my $delay = $self->_success_or_failure(0, $timestamp);
    $delay = $self->_consider_actual_delay($delay, $timestamp)
        if $self->{consider_actual_delay};
    $self->{_last_timestamp} = $timestamp;
    return 0 if $delay < 0;

    $self->_add_jitter($delay);
}

sub _add_jitter {
    my ($self, $delay) = @_;
    return $delay unless $delay && $self->{jitter_factor};
    my $min = $delay * (1-$self->{jitter_factor});
    my $max = $delay * (1+$self->{jitter_factor});
    $min + ($max-$min)*rand();
}

1;
# ABSTRACT: Various retry/backoff strategies

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Retry - Various retry/backoff strategies

=head1 VERSION

This document describes version 0.002 of Algorithm::Retry (from Perl distribution Algorithm-Retry), released on 2019-04-10.

=head1 SYNOPSIS

 # 1. pick a strategy and instantiate

 use Algorithm::Retry::Constant;
 my $ar = Algorithm::Retry::Constant->new(
     delay             => 2, # required
     #delay_on_success => 0, # optional, default 0
 );

 # 2. log success/failure and get a new number of seconds to delay, timestamp is
 # optional but must be monotonically increasing.

 my $secs = $ar->failure(); # => 2
 my $secs = $ar->success(); # => 0
 my $secs = $ar->failure(); # => 2

=head1 DESCRIPTION

This distribution provides several classes that implement various retry/backoff
strategies.

This class (C<Algorithm::Retry>) is a base class only.

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

Please visit the project's homepage at L<https://metacpan.org/release/Algorithm-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Algorithm-Retry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
