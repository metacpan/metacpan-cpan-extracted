package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::ger logging speed with the default/null output',
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
            name => 'Log::ger+Log::ger::OptAway-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger::OptAway', '-MLog::ger', '-e', 'for(1..1_000_000) { log_trace(q[]) }'],
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

This document describes version 0.002 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-06-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::ger-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



=item * Log::ger-1mil_log_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..1_000_000) { log_is_trace() }



=item * Log::ger+Log::ger::OptAway-1mil_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::OptAway -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



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



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +-------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                               | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------------------+-----------+-----------+------------+---------+---------+
 | Log::Any-null_adapter-1mil_log_trace      |       1.6 |       610 |        1   | 0.0035  |       7 |
 | Log::Any-null_adapter-1mil_is_trace       |       2.5 |       400 |        1.5 | 0.00071 |       6 |
 | Log::Any-no_adapter-1mil_is_trace         |       2.5 |       400 |        1.5 | 0.00041 |       6 |
 | Log::Any-no_adapter-1mil_log_trace        |       6.4 |       160 |        3.9 | 0.00094 |       7 |
 | Log::ger-1mil_log_is_trace                |       8.5 |       120 |        5.2 | 0.00013 |       6 |
 | Log::ger-1mil_log_trace                   |       9.9 |       100 |        6   | 0.00073 |       6 |
 | Log::ger+Log::ger::OptAway-1mil_log_trace |      25   |        40 |       15   | 0.00012 |       6 |
 +-------------------------------------------+-----------+-----------+------------+---------+---------+


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
