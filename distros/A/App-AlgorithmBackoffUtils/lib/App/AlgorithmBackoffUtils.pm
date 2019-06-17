package App::AlgorithmBackoffUtils;

our $DATE = '2019-06-08'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Algorithm::Backoff::Constant ();
use Algorithm::Backoff::Exponential ();
use Algorithm::Backoff::Fibonacci ();
use Algorithm::Backoff::LILD ();
use Algorithm::Backoff::LIMD ();
use Algorithm::Backoff::MILD ();
use Algorithm::Backoff::MIMD ();
use Time::HiRes qw(time sleep);

my @algos = qw(Constant Exponential Fibonacci LILD LIMD MILD MIMD);
our %SPEC;

our %arg_algorithm = (
    algorithm => {
        summary => 'Backoff algorithm',
        schema => ['str*', in=>\@algos],
        req => 1,
        cmdline_aliases => {a=>{}},
    },
);

our %args_algo_attrs;
for my $algo (@algos) {
    my $args = ${"Algorithm::Backoff::$algo\::SPEC"}{new}{args};
    for my $arg (keys %$args) {
        my $argspec = $args_algo_attrs{$arg} // { %{$args->{$arg}} };
        $argspec->{req} = 0;
        delete $argspec->{pos};
        if ($argspec->{tags} &&
                (grep { $_ eq 'common' || $_ eq 'category:common-to-all-algorithms' } @{ $argspec->{tags} })) {
            $argspec->{tags}[0] = 'category:common-to-all-algorithms';
        } else {
            $argspec->{tags} //= [];
            push @{ $argspec->{tags} }, lc "category:$algo-algorithm";
        }
        $args_algo_attrs{$arg} //= $argspec;
    }
}

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

$SPEC{retry} = {
    v => 1.1,
    summary => 'Retry a command with custom backoff algorithm',
    args => {
        %arg_algorithm,
        %args_retry_common,
        %args_algo_attrs,
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::Constant'},
    ],
};
sub retry {
    my %args = @_;

    my $algo = delete $args{algorithm};
    _retry($algo, \%args);
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

$SPEC{retry_lild} = {
    v => 1.1,
    summary => 'Retry a command with LILD (linear increase, linear decrease) backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::LILD::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::LILD'},
    ],
};
sub retry_lild {
    _retry("LILD", {@_});
}

$SPEC{retry_limd} = {
    v => 1.1,
    summary => 'Retry a command with LIMD (linear increase, multiplicative decrease) backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::LIMD::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::LIMD'},
    ],
};
sub retry_limd {
    _retry("LIMD", {@_});
}

$SPEC{retry_mild} = {
    v => 1.1,
    summary => 'Retry a command with MILD (multiplicative increase, linear decrease) backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::MILD::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::MILD'},
    ],
};
sub retry_mild {
    _retry("MILD", {@_});
}

$SPEC{retry_mimd} = {
    v => 1.1,
    summary => 'Retry a command with MIMD (multiplicative increase, multiplicative decrease) backoff',
    args => {
        %args_retry_common,
        %{ $Algorithm::Backoff::MIMD::SPEC{new}{args} },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::MIMD'},
    ],
};
sub retry_mimd {
    _retry("MIMD", {@_});
}

$SPEC{show_backoff_delays} = {
    v => 1.1,
    summary => 'Show backoff delays',
    args => {
        %arg_algorithm,
        %args_algo_attrs,
        logs => {
            summary => 'List of failures or successes',
            schema => ['array*', of=>'str*', 'x.perl.coerce_rules'=>['str_comma_sep']],
            'x.name.is_plural' => 1,
            'x.name.singular' => 'log',
            req => 1,
            pos => 0,
            slurpy => 1,
            description => <<'_',

A list of 0's (to signify failure) or 1's (to signify success). Each
failure/success can be followed by `:TIMESTAMP` (unix epoch) or `:+SECS` (number
of seconds after the previous log), or the current timestamp will be assumed.
Examples:

    0 0 0 0 0 0 0 0 0 0 1 1 1 1 1

(10 failures followed by 5 successes).

    0 0:+2 0:+4 0:+6 1

(4 failures, 2 seconds apart, followed by immediate success.)

_
        },
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url => 'pm:Algorithm::Backoff::Fibonacci'},
    ],
};
sub show_backoff_delays {
    my %args = @_;

    my $algo = $args{algorithm} or return [400, "Please specify algorithm"];
    my $algo_args = ${"Algorithm::Backoff::$algo\::SPEC"}{new}{args};

    my %algo_attrs;
    for my $arg (keys %args_algo_attrs) {
        my $argspec = $args_algo_attrs{$arg};
        next unless grep {
            $_ eq 'category:common-to-all-algorithms' ||
            $_ eq lc("category:$algo-algorithm")
        } @{ $argspec->{tags} };
        if (exists $args{$arg}) {
            $algo_attrs{$arg} = $args{$arg};
        }
    }
    #use DD; dd \%args_algo_attrs;
    #use DD; dd \%algo_attrs;
    my $ab = "Algorithm::Backoff::$algo"->new(%algo_attrs);

    my @delays;
    my $time = time();
    my $i = 0;
    for my $log (@{ $args{logs} }) {
        $i++;
        $log =~ /\A([01])(?::(\+)?(\d+))?\z/ or
            return [400, "Invalid log#$i syntax '$log', must be 0 or 1 followed by :TIMESTAMP or :+SECS"];
        if ($2) {
            $time += $3;
        } elsif (defined $3) {
            $time = $3;
        }
        my $delay;
        if ($1) {
            $delay = $ab->success($time);
        } else {
            $delay = $ab->failure($time);
        }
        push @delays, $delay;
    }

    [200, "OK", \@delays];
}

1;
# ABSTRACT: Utilities related to Algorithm::Backoff

__END__

=pod

=encoding UTF-8

=head1 NAME

App::AlgorithmBackoffUtils - Utilities related to Algorithm::Backoff

=head1 VERSION

This document describes version 0.003 of App::AlgorithmBackoffUtils (from Perl distribution App-AlgorithmBackoffUtils), released on 2019-06-08.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<retry>

=item * L<retry-constant>

=item * L<retry-exponential>

=item * L<retry-fibonacci>

=item * L<retry-lild>

=item * L<retry-limd>

=item * L<retry-mild>

=item * L<retry-mimd>

=item * L<show-backoff-delays>

=back

=head1 FUNCTIONS


=head2 retry

Usage:

 retry(%args) -> [status, msg, payload, meta]

Retry a command with custom backoff algorithm.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm>* => I<str>

Backoff algorithm.

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

=item * B<delay> => I<ufloat>

Number of seconds to wait after a failure.

=item * B<delay_increment_on_failure> => I<float>

How much to add to previous delay, in seconds, upon failure (e.g. 5).

=item * B<delay_increment_on_success> => I<float>

How much to add to previous delay, in seconds, upon success (e.g. -5).

=item * B<delay_multiple_on_failure> => I<ufloat>

How much to multiple previous delay, upon failure (e.g. 1.5).

=item * B<delay_multiple_on_success> => I<ufloat>

How much to multiple previous delay, upon success (e.g. 0.5).

=item * B<delay_on_success> => I<ufloat> (default: 0)

Number of seconds to wait after a success.

=item * B<exponent_base> => I<ufloat> (default: 2)

=item * B<initial_delay> => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<initial_delay1> => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<initial_delay2> => I<ufloat>

Initial delay for the second attempt after failure, in seconds.

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



=head2 retry_lild

Usage:

 retry_lild(%args) -> [status, msg, payload, meta]

Retry a command with LILD (linear increase, linear decrease) backoff.

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

=item * B<delay_increment_on_failure>* => I<float>

How much to add to previous delay, in seconds, upon failure (e.g. 5).

=item * B<delay_increment_on_success>* => I<float>

How much to add to previous delay, in seconds, upon success (e.g. -5).

=item * B<initial_delay>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

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



=head2 retry_limd

Usage:

 retry_limd(%args) -> [status, msg, payload, meta]

Retry a command with LIMD (linear increase, multiplicative decrease) backoff.

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

=item * B<delay_increment_on_failure>* => I<float>

How much to add to previous delay, in seconds, upon failure (e.g. 5).

=item * B<delay_multiple_on_success>* => I<ufloat>

How much to multiple previous delay, upon success (e.g. 0.5).

=item * B<initial_delay>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

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



=head2 retry_mild

Usage:

 retry_mild(%args) -> [status, msg, payload, meta]

Retry a command with MILD (multiplicative increase, linear decrease) backoff.

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

=item * B<delay_increment_on_success>* => I<float>

How much to add to previous delay, in seconds, upon success (e.g. -5).

=item * B<delay_multiple_on_failure>* => I<ufloat>

How much to multiple previous delay, upon failure (e.g. 1.5).

=item * B<initial_delay>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

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



=head2 retry_mimd

Usage:

 retry_mimd(%args) -> [status, msg, payload, meta]

Retry a command with MIMD (multiplicative increase, multiplicative decrease) backoff.

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

=item * B<delay_multiple_on_failure>* => I<ufloat>

How much to multiple previous delay, upon failure (e.g. 1.5).

=item * B<delay_multiple_on_success>* => I<ufloat>

How much to multiple previous delay, upon success (e.g. 0.5).

=item * B<initial_delay>* => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

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



=head2 show_backoff_delays

Usage:

 show_backoff_delays(%args) -> [status, msg, payload, meta]

Show backoff delays.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm>* => I<str>

Backoff algorithm.

=item * B<consider_actual_delay> => I<bool> (default: 0)

Whether to consider actual delay.

If set to true, will take into account the actual delay (timestamp difference).
For example, when using the Constant strategy of delay=2, you log failure()
again right after the previous failure() (i.e. specify the same timestamp).
failure() will then return ~2+2 = 4 seconds. On the other hand, if you waited 2
seconds before calling failure() again (i.e. specify the timestamp that is 2
seconds larger than the previous timestamp), failure() will return 2 seconds.
And if you waited 4 seconds or more, failure() will return 0.

=item * B<delay> => I<ufloat>

Number of seconds to wait after a failure.

=item * B<delay_increment_on_failure> => I<float>

How much to add to previous delay, in seconds, upon failure (e.g. 5).

=item * B<delay_increment_on_success> => I<float>

How much to add to previous delay, in seconds, upon success (e.g. -5).

=item * B<delay_multiple_on_failure> => I<ufloat>

How much to multiple previous delay, upon failure (e.g. 1.5).

=item * B<delay_multiple_on_success> => I<ufloat>

How much to multiple previous delay, upon success (e.g. 0.5).

=item * B<delay_on_success> => I<ufloat> (default: 0)

Number of seconds to wait after a success.

=item * B<exponent_base> => I<ufloat> (default: 2)

=item * B<initial_delay> => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<initial_delay1> => I<ufloat>

Initial delay for the first attempt after failure, in seconds.

=item * B<initial_delay2> => I<ufloat>

Initial delay for the second attempt after failure, in seconds.

=item * B<jitter_factor> => I<float>

How much to add randomness.

If you set this to a value larger than 0, the actual delay will be between a
random number between original_delay * (1-jitter_factor) and original_delay *
(1+jitter_factor). Jitters are usually added to avoid so-called "thundering
herd" problem.

The jitter will be applied to delay on failure as well as on success.

=item * B<logs>* => I<array[str]>

List of failures or successes.

A list of 0's (to signify failure) or 1's (to signify success). Each
failure/success can be followed by C<:TIMESTAMP> (unix epoch) or C<:+SECS> (number
of seconds after the previous log), or the current timestamp will be assumed.
Examples:

 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1

(10 failures followed by 5 successes).

 0 0:+2 0:+4 0:+6 1

(4 failures, 2 seconds apart, followed by immediate success.)

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


L<Algorithm::Backoff::Exponential>.

L<Algorithm::Backoff::LIMD>.

L<Algorithm::Backoff::Constant>.

L<Algorithm::Backoff::LILD>.

L<Algorithm::Backoff::Fibonacci>.

L<Algorithm::Backoff::MILD>.

L<Algorithm::Backoff::MIMD>.

L<Algorithm::Backoff>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
