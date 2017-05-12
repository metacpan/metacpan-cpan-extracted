package Benchmark::Command;

our $DATE = '2015-06-14'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;

use Benchmark::Dumb qw(cmpthese);
use Capture::Tiny qw(capture_merged);
use File::Which;

sub run {
    my ($count, $cmds, $opts) = @_;

    $count //= $ENV{BENCHMARK_COMMAND_COUNT} // 0;

    $opts //= {};
    $opts->{quiet} //= $ENV{BENCHMARK_COMMAND_QUIET} // $ENV{QUIET} // 0;
    $opts->{ignore_exit_code} //= $ENV{BENCHMARK_COMMAND_IGNORE_EXIT_CODE} // 0;
    $opts->{skip_not_found} //= $ENV{BENCHMARK_COMMAND_SKIP_NOT_FOUND} // 0;

    ref($cmds) eq 'HASH' or die "cmds must be a hashref";

    my $subs = {};
    my $longest = 0;
  COMMAND:
    for my $cmd_name (keys %$cmds) {
        $longest = length($cmd_name) if length($cmd_name) > $longest;
        my $cmd_spec = $cmds->{$cmd_name};
        if (ref($cmd_spec) eq 'CODE') {
            # accept coderef as-is
            $subs->{$cmd_name} = $cmd_spec;
            next COMMAND;
        }
        ref($cmd_spec) eq 'ARRAY'
            or die "cmds->{$cmd_name} must be an arrayref";

        my @cmd = @$cmd_spec;
        my $per_cmd_opts;
        if (ref($cmd[0]) eq 'HASH') {
            $per_cmd_opts = shift @cmd;
        } else {
            $per_cmd_opts = {};
        }
        $per_cmd_opts->{env} //= {};
        @cmd or die "cmds->{$cmd_name} must not be empty";

        unless (which $cmd[0]) {
            if ($per_cmd_opts->{skip_not_found} // $opts->{skip_not_found}) {
                warn "cmds->{$cmd_name}: program '$cmd[0]' not found, ".
                    "skipped\n";
                next COMMAND;
            } else {
                die "cmds->{$cmd_name}: program '$cmd[0]' not found";
            }
        }

        # XXX we haven't counted for overhead of setting/resetting env vars. but
        # because it should be about 3 orders of magnitude (microsecs instead of
        # millisecs) we're ignoring it for now.

        $subs->{$cmd_name} = sub {
            my %save_env;
            for my $var (keys %{ $per_cmd_opts->{env} }) {
                $save_env{$var} = $ENV{$var};
                $ENV{$var} = $per_cmd_opts->{env}{$var};
            }

            system {$cmd[0]} @cmd;

            die "Non-zero exit code ($?) for $cmd_name"
                if !($per_cmd_opts->{ignore_exit_code} //
                     $opts->{ignore_exit_code}) && $?;

            for my $var (keys %save_env) {
                $ENV{$var} = $save_env{$var};
            }
        };
    }

    my $output = capture_merged {
        cmpthese($count, $subs);
    };

    # strip program's output
    $output =~ /(.*(?:^|\S))( +Rate\s+.+)/ms
        or die "Can't detect cmpthese() output, full output: $output";

    my $cmpoutput = $2;
    if ($opts->{quiet}) {
        $output = $cmpoutput;
    }

    print $output;

    my $times = {};
    for (keys %$subs) {
        $cmpoutput =~ m/^\Q$_\E\s+(\d+(?:\.\d+)?)/m
            or die "Can't find rate for '$_'";
        $times->{$_} = 1/$1;
    }
    #use DD; dd $times;

    print "\nAverage times:\n";
    for (sort {$times->{$a} <=> $times->{$b}} keys %$times) {
        printf "  %-${longest}s: %10.4fms\n",
            $_, 1000*$times->{$_};
    }
};

1;
# ABSTRACT: Benchmark commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Command - Benchmark commands

=head1 VERSION

This document describes version 0.08 of Benchmark::Command (from Perl distribution Benchmark-Command), released on 2015-06-14.

=head1 SYNOPSIS

 use Benchmark::Command;

 Benchmark::Command::run(100, {
     perl        => [{env=>{PERL_UNICODE=>''}}, qw/perl -e1/],
     "bash+true" => [qw/bash --norc -c true/],
     ruby        => [qw/ruby -e1/],
     python      => [qw/python -c1/],
     nodejs      => [qw/nodejs -e 1/],
 });

Sample output:

                      Rate      nodejs      python        ruby bash+true   perl
 nodejs    40.761+-0.063/s          --      -55.3%      -57.1%    -84.8% -91.7%
 python        91.1+-1.3/s 123.6+-3.3%          --       -4.0%    -66.0% -81.5%
 ruby         94.92+-0.7/s 132.9+-1.8%   4.2+-1.7%          --    -64.6% -80.8%
 bash+true   267.94+-0.7/s   557.3+-2%   194+-4.4% 182.3+-2.2%        -- -45.7%
 perl         493.8+-5.1/s   1112+-13% 441.9+-9.7% 420.3+-6.6%  84.3+-2%     --

 Average times:
   perl     :     2.0251ms
   bash+true:     3.7322ms
   ruby     :    10.5352ms
   python   :    10.9769ms
   nodejs   :    24.5333ms

=head1 DESCRIPTION

This module provides C<run()>, a convenience routine to benchmark commands. This
module is similar to L<Benchmark::Apps> except: 1) commands will be executed
without shell (using the C<< system {$_[0]} @_ >> syntax); 2) the existence of
each program will be checked first; 3) L<Benchmark::Dumb> is used as the
backend.

This module is suitable for benchmarking commands that completes in a short
time, like the above example.

=head1 FUNCTIONS

=head2 run($count, \%cmds[, \%opts])

Do some checks and convert C<%cmds> (which is a hash of names and command
arrayrefs (e.g. C<< {perl=>["perl", "-e1"], nodejs=>["nodejs", "-e", 1]} >>)
into C<%subs> (which is a hash of names and coderefs (e.g.: C<< {perl=>sub
{system {"perl"} "perl", "-e1"}, nodejs=>sub {system {"nodejs"} "nodejs", "-e",
1}} >>).

If a value in C<%cmds> is already a coderef, it will be used as-is.

If a value in C<%cmds> is an arrayref, the first element of the arrayref (before
the program name) can optionally contain a hashref of option. See per-command
option below..

The checks done are: each command must be an arrayref (to be executed without
invoking shell) and the program (first element of each arrayref) must exist.

Then run L<Benchmark::Dumb>'s C<< cmpthese($count, \%subs) >>. Usually,
C<$count> can be set to 0 but for the above example where the commands end in a
short time (in the order milliseconds), I set to to around 100.

Then also show the average run times for each command.

Known options:

=over

=item * quiet => bool (default: from env QUIET or 0)

If set to true, will hide program's output.

=item * ignore_exit_code => bool (default: from env BENCHMARK_COMMAND_IGNORE_EXIT_CODE or 0)

If set to true, will not die if exit code is non-zero.

=item * skip_not_found => bool (default: 0)

If set to true, will skip benchmarking commands where the program is not found.
The default bahavior is to die.

=back

Known per-command options:

=over

=item * env => hash

Locally set environment variables for the command.

=item * ignore_exit_code => bool

This overrides global C<ignore_exit_code> option.

=item * skip_not_found => bool

This overrides global C<skip_not_found> option.

=back

=head1 ENVIRONMENT

=head2 BENCHMARK_COMMAND_COUNT => num

Set default for C<run()>'s C<$count> argument.

=head2 BENCHMARK_COMMAND_IGNORE_EXIT_CODE => bool

Set default for C<run()>'s C<ignore_exit_code> option.

=head2 BENCHMARK_COMMAND_QUIET => bool

Set default for C<run()>'s C<quiet> option (takes precedence of C<QUIET>).

=head2 BENCHMARK_COMMAND_SKIP_NOT_FOUND => bool

Set default for C<run()>'s C<skip_not_found> option.

=head2 QUIET => bool

Set default for C<run()>'s C<quiet> option (if C<BENCHMARK_COMMAND_QUIET> is not
defined).

=head2 SEE ALSO

L<Benchmark::Apps>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Benchmark-Command>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Benchmark-Command>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Benchmark-Command>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
