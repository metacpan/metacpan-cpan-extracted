package App::AlgorithmBackoffUtils;

our $DATE = '2019-06-05'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Algorithm::Backoff::Constant ();
use Algorithm::Backoff::Exponential ();
use Algorithm::Backoff::Fibonacci ();
use Time::HiRes qw(time sleep);

our %SPEC;

our %args_retry_common = (
    command => {
        schema => ['array*', of=>'str*'],
        req => 1,
        pos => 0,
        slurpy => 1,
    },
    retry_on => {
        summary => 'Comma-separated list of exit codes that should trigger retry',
        schema => ['str*', match=>qr/\A\d+(,\d+)*\z/],
        description => <<'_',

By default, all non-zero exit codes will trigger retry.

_
    },
    success_on => {
        summary => 'Comma-separated list of exit codes that mean success',
        schema => ['str*', match=>qr/\A\d+(,\d+)*\z/],
        description => <<'_',

By default, only exit code 0 means success.

_
    },
    skip_delay => {
        summary => 'Do not delay at all',
        schema => 'true*',
        description => <<'_',

Useful for testing, along with --dry-run, when you just want to see how the
retries are done (the number of retries, along with the number of seconds of
delays) by seeing the log messages, without actually delaying.

_
        cmdline_aliases => {D=>{}},
    },
);

sub _retry {
    require IPC::System::Options;

    my ($name, $args) = @_;

    my $mod = "Algorithm::Backoff::$name";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $dry_run    = delete $args->{-dry_run};
    my $command    = delete $args->{command};
    my $retry_on   = delete $args->{retry_on};
    my $success_on = delete $args->{success_on};
    my $skip_delay = delete $args->{skip_delay};

    my $time = time();
    my $ab = $mod->new(%$args);
    my $attempt = 0;
    while (1) {
        $attempt++;
        my ($exit_code, $is_success);
        if ($dry_run) {
            log_info "[DRY-RUN] Executing command %s (attempt %d) ...",
                $command, $attempt;
            $exit_code = -1;
        } else {
            IPC::System::Options::system({log=>1, shell=>0}, @$command);
            $exit_code = $? < 0 ? $? : $? >> 8;
        }
      DETERMINE_SUCCESS: {
            if (defined $retry_on) {
                my $codes = split /,/, $retry_on;
                $is_success = !(grep { $_ == $exit_code } @$codes);
                last;
            }
            if (defined $success_on) {
                my $codes = split /,/, $success_on;
                $is_success = grep { $_ == $exit_code } @$codes;
                last;
            }
            $is_success = $exit_code == 0 ? 1:0;
        }
        if ($is_success) {
            log_trace "Command successful (exit_code=$exit_code)";
            return [200];
        } else {
            my $delay;
            if ($skip_delay) {
                $delay = $ab->failure($time);
            } else {
                $delay = $ab->failure;
            }
            if ($delay == -1) {
                log_error "Command failed (exit_code=$exit_code), giving up";
                return [500, "Command failed (after $attempt attempt(s))"];
            } else {
                log_warn "Command failed (exit_code=$exit_code), delaying %d second(s) before the next attempt ...",
                    $delay;
                sleep $delay unless $skip_delay;
            }
            $time += $delay if $skip_delay;
        }
    }
}

$SPEC{retry_constant} = {
    v => 1.1,
    summary => 'Retry a command with constant delay backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::Constant::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::Constant'},
    ],
};
sub retry_constant {
    _retry("Constant", {@_});
}

$SPEC{retry_exponential} = {
    v => 1.1,
    summary => 'Retry a command with exponential backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::Exponential::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::Exponential'},
    ],
};
sub retry_exponential {
    _retry("Exponential", {@_});
}

$SPEC{retry_fibonacci} = {
    v => 1.1,
    summary => 'Retry a command with fibonacci backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::Fibonacci::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::Fibonacci'},
    ],
};
sub retry_fibonacci {
    _retry("Fibonacci", {@_});
}

1;
# ABSTRACT: Utilities related to Algorithm::Backoff

__END__

=pod

=encoding UTF-8

=head1 NAME

App::AlgorithmBackoffUtils - Utilities related to Algorithm::Backoff

=head1 VERSION

This document describes version 0.001 of App::AlgorithmBackoffUtils (from Perl distribution App-AlgorithmBackoffUtils), released on 2019-06-05.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<retry-constant>

=item * L<retry-exponential>

=item * L<retry-fibonacci>

=back

=head1 FUNCTIONS


=head2 retry_constant

Usage:

 retry_constant(%args) -> [status, msg, payload, meta]

Retry a command with constant delay backoff.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<array[str]>

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

=item * B<retry_on> => I<str>

Comma-separated list of exit codes that should trigger retry.

By default, all non-zero exit codes will trigger retry.

=item * B<skip_delay> => I<true>

Do not delay at all.

Useful for testing, along with --dry-run, when you just want to see how the
retries are done (the number of retries, along with the number of seconds of
delays) by seeing the log messages, without actually delaying.

=item * B<success_on> => I<str>

Comma-separated list of exit codes that mean success.

By default, only exit code 0 means success.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 retry_exponential

Usage:

 retry_exponential(%args) -> [status, msg, payload, meta]

Retry a command with exponential backoff.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<array[str]>

=item * B<consider_actual_delay> => I<bool> (default: 0)

Whether to consider actual delay.

If set to true, will take into account the actual delay (timestamp difference).
For example, when using the Constant strategy of delay=2, you log failure()
again right after the previous failure() (i.e. specify the same timestamp).
failure() will then return ~2+2 = 4 seconds. On the other hand, if you waited 2
seconds before calling failure() again (i.e. specify the timestamp that is 2
seconds larger than the previous timestamp), failure() will return 2 seconds.
And if you waited 4 seconds or more, failure() will return 0.

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

=item * B<retry_on> => I<str>

Comma-separated list of exit codes that should trigger retry.

By default, all non-zero exit codes will trigger retry.

=item * B<skip_delay> => I<true>

Do not delay at all.

Useful for testing, along with --dry-run, when you just want to see how the
retries are done (the number of retries, along with the number of seconds of
delays) by seeing the log messages, without actually delaying.

=item * B<success_on> => I<str>

Comma-separated list of exit codes that mean success.

By default, only exit code 0 means success.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 retry_fibonacci

Usage:

 retry_fibonacci(%args) -> [status, msg, payload, meta]

Retry a command with fibonacci backoff.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<array[str]>

=item * B<consider_actual_delay> => I<bool> (default: 0)

Whether to consider actual delay.

If set to true, will take into account the actual delay (timestamp difference).
For example, when using the Constant strategy of delay=2, you log failure()
again right after the previous failure() (i.e. specify the same timestamp).
failure() will then return ~2+2 = 4 seconds. On the other hand, if you waited 2
seconds before calling failure() again (i.e. specify the timestamp that is 2
seconds larger than the previous timestamp), failure() will return 2 seconds.
And if you waited 4 seconds or more, failure() will return 0.

=item * B<delay_on_success> => I<ufloat> (default: 0)

Number of seconds to wait after a success.

=item * B<initial_delay1>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<initial_delay2>* => I<ufloat>

Initial delay for the second attempt after failure, in seconds.

=item * B<jitter_factor> => I<float>

How much to add randomness.

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

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

=item * B<retry_on> => I<str>

Comma-separated list of exit codes that should trigger retry.

By default, all non-zero exit codes will trigger retry.

=item * B<skip_delay> => I<true>

Do not delay at all.

Useful for testing, along with --dry-run, when you just want to see how the
retries are done (the number of retries, along with the number of seconds of
delays) by seeing the log messages, without actually delaying.

=item * B<success_on> => I<str>

Comma-separated list of exit codes that mean success.

By default, only exit code 0 means success.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-AlgorithmBackoffUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-AlgorithmBackoffUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AlgorithmBackoffUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<Algorithm::Backoff::Constant>.

L<Algorithm::Backoff::Exponential>.

L<Algorithm::Backoff::Fibonacci>.

L<Algorithm::Backoff>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
