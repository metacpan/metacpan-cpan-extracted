package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::ger logging speed with the default/null output',
    modules => {
        'Log::ger' => {version=>'0.011'},
        'Log::ger::Plugin::MultilevelLog' => {},
        'Log::ger::Plugin::OptAway' => {},
        'Log::Any' => {},
        'Log::Fast' => {},
        'Log::Log4perl' => {},
        'Log::Log4perl::Tiny' => {},
    },
    participants => [
        {
            name => 'Log::ger-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..1_000_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger-1mil_log_is_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..1_000_000) { log_is_trace() }'],
        },
        {
            name => 'Log::ger+LGP:OptAway-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=OptAway', '-MLog::ger', '-e', 'for(1..1_000_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger+LGP:MutilevelLog-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=MultilevelLog', '-MLog::ger', '-e', 'for(1..1_000_000) { log("trace", q[]) }'],
        },
        {
            name => 'Log::ger+LGP:MutilevelLog-1mil_log_6',
            perl_cmdline_template => ['-MLog::ger::Plugin=MultilevelLog', '-MLog::ger', '-e', 'for(1..1_000_000) { log(6, q[]) }'],
        },

        {
            name => 'Log::Fast-1mil_DEBUG',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; $LOG->level("INFO"); for(1..1_000_000) { $LOG->DEBUG(q()) }'],
        },
        {
            name => 'Log::Fast-1mil_is_debug',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; for(1..1_000_000) { $LOG->level() eq "DEBUG" }'],
        },

        {
            name => 'Log::Any-no_adapter-1mil_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..1_000_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-no_adapter-1mil_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..1_000_000) { $log->is_trace }'],
        },
        {
            name => 'Log::Any-null_adapter-1mil_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..1_000_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-null_adapter-1mil_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..1_000_000) { $log->is_trace }'],
        },

        {
            name => 'Log::Log4perl-easy-1mil_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl=:easy', '-e', 'Log::Log4perl->easy_init($ERROR); for(1..1_000_000) { TRACE "" }'],
        },

        {
            name => 'Log::Log4perl::Tiny-1mil_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl::Tiny=:easy', '-e', 'for(1..1_000_000) { TRACE "" }'],
        },

    ],
    precision => 6,
};

1;
# ABSTRACT: Benchmark Log::ger logging speed with the default/null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::NullOutput - Benchmark Log::ger logging speed with the default/null output

=head1 VERSION

This document describes version 0.010 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-13.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.042

L<Log::Fast> v2.0.0

L<Log::Log4perl> 1.47

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.016

L<Log::ger::Plugin::MultilevelLog> 0.016

L<Log::ger::Plugin::OptAway> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::ger-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



=item * Log::ger-1mil_log_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..1_000_000) { log_is_trace() }



=item * Log::ger+LGP:OptAway-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=OptAway -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



=item * Log::ger+LGP:MutilevelLog-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=MultilevelLog -MLog::ger -e for(1..1_000_000) { log("trace", q[]) }



=item * Log::ger+LGP:MutilevelLog-1mil_log_6 (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=MultilevelLog -MLog::ger -e for(1..1_000_000) { log(6, q[]) }



=item * Log::Fast-1mil_DEBUG (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; $LOG->level("INFO"); for(1..1_000_000) { $LOG->DEBUG(q()) }



=item * Log::Fast-1mil_is_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; for(1..1_000_000) { $LOG->level() eq "DEBUG" }



=item * Log::Any-no_adapter-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..1_000_000) { $log->trace(q[]) }



=item * Log::Any-no_adapter-1mil_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..1_000_000) { $log->is_trace }



=item * Log::Any-null_adapter-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..1_000_000) { $log->trace(q[]) }



=item * Log::Any-null_adapter-1mil_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..1_000_000) { $log->is_trace }



=item * Log::Log4perl-easy-1mil_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl=:easy -e Log::Log4perl->easy_init($ERROR); for(1..1_000_000) { TRACE "" }



=item * Log::Log4perl::Tiny-1mil_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl::Tiny=:easy -e for(1..1_000_000) { TRACE "" }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                              | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------------------------+-----------+-----------+------------+---------+---------+
 | Log::Log4perl::Tiny-1mil_trace           |     0.792 |      1260 |       1    | 0.00066 |       6 |
 | Log::Any-null_adapter-1mil_log_trace     |     1.3   |       760 |       1.7  | 0.0012  |       6 |
 | Log::Fast-1mil_is_debug                  |     1.9   |       520 |       2.4  | 0.0015  |       6 |
 | Log::Any-no_adapter-1mil_is_trace        |     2     |       500 |       3    | 0.0075  |       6 |
 | Log::Any-null_adapter-1mil_is_trace      |     2.3   |       440 |       2.9  | 0.00099 |       8 |
 | Log::Log4perl-easy-1mil_trace            |     3.1   |       323 |       3.92 | 0.00029 |       6 |
 | Log::Any-no_adapter-1mil_log_trace       |     6.1   |       160 |       7.7  | 0.00057 |       6 |
 | Log::Fast-1mil_DEBUG                     |     6.5   |       150 |       8.2  | 0.00041 |       6 |
 | Log::ger+LGP:MutilevelLog-1mil_log_6     |     8     |       100 |      10    | 0.0013  |       6 |
 | Log::ger+LGP:MutilevelLog-1mil_log_trace |     8.8   |       110 |      11    | 0.001   |       8 |
 | Log::ger-1mil_log_trace                  |    10     |        97 |      13    | 0.00028 |       6 |
 | Log::ger-1mil_log_is_trace               |    11     |        92 |      14    | 0.00028 |       6 |
 | Log::ger+LGP:OptAway-1mil_log_trace      |    21     |        49 |      26    | 0.00032 |       6 |
 +------------------------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
