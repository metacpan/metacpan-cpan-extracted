package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.018'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::ger logging speed with the default/null output',
    modules => {
        'Log::ger' => {version=>'0.023'},
        'Log::ger::Format::MultilevelLog' => {},
        'Log::ger::Plugin::OptAway' => {},
        'Log::Any' => {},
        'Log::Fast' => {},
        'Log::Log4perl' => {},
        'Log::Log4perl::Tiny' => {},
        'Log::Contextual' => {},
        'Log::Contextual::SimpleLogger' => {},
        'Log::Dispatch' => {},
        'Log::Dispatch::Null' => {},
        'Log::Dispatchouli' => {},
        'Mojo::Log' => {},
        'XLog' => {},
    },
    participants => [
        {
            name => 'Log::ger-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger-100k_log_is_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..100_000) { log_is_trace() }'],
        },
        {
            name => 'Log::ger+LGP:OptAway-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=OptAway', '-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger+LGF:MutilevelLog-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Format=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log("trace", q[]) }'],
        },
        {
            name => 'Log::ger+LGP:MutilevelLog-100k_log_6',
            perl_cmdline_template => ['-MLog::ger::Format=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log(6, q[]) }'],
        },

        {
            name => 'Log::Fast-100k_DEBUG',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }'],
        },
        {
            name => 'Log::Fast-100k_is_debug',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; for(1..100_000) { $LOG->level() eq "DEBUG" }'],
        },

        {
            name => 'Log::Any-no_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-no_adapter-100k_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }'],
        },
        {
            name => 'Log::Any-null_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-null_adapter-100k_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }'],
        },

        {
            name => 'Log::Dispatch::Null-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatch', '-e', 'my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }'],
        },

        {
            name => 'Log::Log4perl-easy-100k_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl=:easy', '-e', 'Log::Log4perl->easy_init($ERROR); for(1..100_000) { TRACE "" }'],
        },

        {
            name => 'Log::Log4perl::Tiny-100k_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl::Tiny=:easy', '-e', 'for(1..100_000) { TRACE "" }'],
        },

        {
            name => 'Log::Contextual+Log4perl-100k_trace' ,
            perl_cmdline_template => ['-e', 'use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..100_000) { log_trace {} }'],
        },
        {
            name => 'Log::Contextual+SimpleLogger-100k_trace' ,
            perl_cmdline_template => ['-MLog::Contextual::SimpleLogger', '-e', 'use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..100_000) { log_trace {} }'],
        },

        {
            name => 'Log::Dispatchouli-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatchouli', '-e', '$logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }'],
        },

        {
            name => 'Mojo::Log-100k_debug' ,
            perl_cmdline_template => ['-MMojo::Log', '-e', '$log = Mojo::Log->new(level=>"warn"); for(1..100_000) { $log->debug("") }'],
        },

        {
            name => 'XLog-100k_debug' ,
            perl_cmdline_template => ['-MXLog', '-e', 'for(1..100_000) { XLog::debug("") }'],
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

This document describes version 0.018 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2021-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.708

L<Log::Contextual> 0.008001

L<Log::Contextual::SimpleLogger> 0.008001

L<Log::Dispatch> 2.68

L<Log::Dispatch::Null> 2.68

L<Log::Dispatchouli> 2.019

L<Log::Fast> v2.0.1

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.038

L<Log::ger::Format::MultilevelLog> 0.038

L<Log::ger::Plugin::OptAway> 0.009

L<Mojo::Log>

L<XLog> 1.1.0

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::ger-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::ger-100k_log_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..100_000) { log_is_trace() }



=item * Log::ger+LGP:OptAway-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=OptAway -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::ger+LGF:MutilevelLog-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Format=MultilevelLog -MLog::ger -e for(1..100_000) { log("trace", q[]) }



=item * Log::ger+LGP:MutilevelLog-100k_log_6 (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Format=MultilevelLog -MLog::ger -e for(1..100_000) { log(6, q[]) }



=item * Log::Fast-100k_DEBUG (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }



=item * Log::Fast-100k_is_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; for(1..100_000) { $LOG->level() eq "DEBUG" }



=item * Log::Any-no_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Any-no_adapter-100k_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }



=item * Log::Any-null_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Any-null_adapter-100k_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }



=item * Log::Dispatch::Null-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatch -e my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }



=item * Log::Log4perl-easy-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl=:easy -e Log::Log4perl->easy_init($ERROR); for(1..100_000) { TRACE "" }



=item * Log::Log4perl::Tiny-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl::Tiny=:easy -e for(1..100_000) { TRACE "" }



=item * Log::Contextual+Log4perl-100k_trace (command)

Command line:

 #TEMPLATE: #perl -e use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..100_000) { log_trace {} }



=item * Log::Contextual+SimpleLogger-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Contextual::SimpleLogger -e use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..100_000) { log_trace {} }



=item * Log::Dispatchouli-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatchouli -e $logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }



=item * Mojo::Log-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MMojo::Log -e $log = Mojo::Log->new(level=>"warn"); for(1..100_000) { $log->debug("") }



=item * XLog-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MXLog -e for(1..100_000) { XLog::debug("") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                              | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug           |       2   |     600   |                 0.00% |              4599.10% |   0.018   |       7 |
 | Log::Contextual+Log4perl-100k_trace      |       2.2 |     460   |                30.73% |              3494.48% |   0.0025  |       7 |
 | Log::Contextual+SimpleLogger-100k_trace  |       2.2 |     450   |                34.01% |              3406.53% |   0.00059 |       6 |
 | Log::Dispatchouli-100k_debug             |       6.2 |     160   |               276.69% |              1147.47% |   0.00058 |       6 |
 | Mojo::Log-100k_debug                     |       6.9 |     150   |               318.32% |              1023.34% |   0.00046 |       6 |
 | Log::Log4perl::Tiny-100k_trace           |       9.8 |     100   |               495.29% |               689.38% |   0.00026 |       6 |
 | Log::Fast-100k_is_debug                  |      16   |      61   |               891.83% |               373.78% | 9.3e-05   |       7 |
 | Log::Any-null_adapter-100k_log_trace     |      17   |      60   |               905.87% |               367.17% | 6.7e-05   |       6 |
 | Log::Log4perl-easy-100k_trace            |      19   |      54   |              1033.66% |               314.51% |   0.00018 |       8 |
 | Log::Any-null_adapter-100k_is_trace      |      20   |      40   |              1338.80% |               226.60% |   0.00046 |       6 |
 | Log::Any-no_adapter-100k_is_trace        |      24.7 |      40.5 |              1399.74% |               213.33% | 2.2e-05   |       6 |
 | Log::Fast-100k_DEBUG                     |      26   |      38   |              1508.96% |               192.06% |   0.00016 |       6 |
 | XLog-100k_debug                          |      37   |      27   |              2119.96% |               111.67% |   0.00014 |       6 |
 | Log::Any-no_adapter-100k_log_trace       |      41   |      24   |              2381.63% |                89.36% | 4.9e-05   |       6 |
 | Log::ger+LGP:OptAway-100k_log_trace      |      46   |      22   |              2704.34% |                67.57% | 3.3e-05   |       6 |
 | Log::ger+LGF:MutilevelLog-100k_log_trace |      49   |      21   |              2858.75% |                58.82% | 5.4e-05   |       6 |
 | Log::ger+LGP:MutilevelLog-100k_log_6     |      50   |      20   |              2910.54% |                56.09% |   9e-05   |       7 |
 | Log::ger-100k_log_trace                  |      74   |      14   |              4383.10% |                 4.82% | 8.4e-05   |       6 |
 | Log::ger-100k_log_is_trace               |      77   |      13   |              4599.10% |                 0.00% | 2.6e-05   |       6 |
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
