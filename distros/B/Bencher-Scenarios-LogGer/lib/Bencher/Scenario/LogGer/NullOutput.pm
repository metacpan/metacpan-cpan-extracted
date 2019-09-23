package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2019-09-18'; # DATE
our $VERSION = '0.015'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Log::ger logging speed with the default/null output',
    modules => {
        'Log::ger' => {version=>'0.023'},
        'Log::ger::Plugin::MultilevelLog' => {},
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
            name => 'Log::ger+LGP:MutilevelLog-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log("trace", q[]) }'],
        },
        {
            name => 'Log::ger+LGP:MutilevelLog-100k_log_6',
            perl_cmdline_template => ['-MLog::ger::Plugin=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log(6, q[]) }'],
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

This document describes version 0.015 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2019-09-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.705

L<Log::Contextual> 0.008001

L<Log::Contextual::SimpleLogger> 0.008001

L<Log::Dispatch> 2.67

L<Log::Dispatch::Null> 2.67

L<Log::Dispatchouli> 2.015

L<Log::Fast> v2.0.1

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.028

L<Log::ger::Plugin::MultilevelLog> 0.028

L<Log::ger::Plugin::OptAway> 0.006

L<Mojo::Log>

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



=item * Log::ger+LGP:MutilevelLog-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=MultilevelLog -MLog::ger -e for(1..100_000) { log("trace", q[]) }



=item * Log::ger+LGP:MutilevelLog-100k_log_6 (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=MultilevelLog -MLog::ger -e for(1..100_000) { log(6, q[]) }



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



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +------------------------------------------+-----------+-------+------------+-----------+---------+
 | participant                              | rate (/s) |  time | vs_slowest |  errors   | samples |
 +------------------------------------------+-----------+-------+------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug           |       0.5 | 2     |        1   |   0.096   |       6 |
 | Log::Contextual+Log4perl-100k_trace      |       2   | 0.6   |        4   |   0.009   |       7 |
 | Log::Contextual+SimpleLogger-100k_trace  |       1.9 | 0.53  |        4.1 |   0.0045  |       6 |
 | Mojo::Log-100k_debug                     |       3.6 | 0.28  |        7.9 |   0.0023  |       6 |
 | Log::Dispatchouli-100k_debug             |       6   | 0.2   |       10   |   0.0024  |       8 |
 | Log::Log4perl::Tiny-100k_trace           |       7   | 0.1   |       20   |   0.0051  |       6 |
 | Log::Any-null_adapter-100k_log_trace     |      14   | 0.07  |       31   |   0.00013 |       6 |
 | Log::Fast-100k_is_debug                  |      14   | 0.069 |       32   |   0.00018 |       6 |
 | Log::Log4perl-easy-100k_trace            |      17   | 0.058 |       38   |   0.0002  |       7 |
 | Log::Any-null_adapter-100k_is_trace      |      20   | 0.05  |       40   |   0.00074 |       7 |
 | Log::Any-no_adapter-100k_is_trace        |      21   | 0.048 |       46   |   0.00028 |       7 |
 | Log::Fast-100k_DEBUG                     |      20   | 0.04  |       50   |   0.00076 |       6 |
 | Log::Any-no_adapter-100k_log_trace       |      38   | 0.026 |       85   |   0.0002  |       6 |
 | Log::ger+LGP:OptAway-100k_log_trace      |      49   | 0.02  |      110   | 5.1e-05   |       6 |
 | Log::ger+LGP:MutilevelLog-100k_log_trace |      50   | 0.02  |      110   | 2.2e-05   |       6 |
 | Log::ger+LGP:MutilevelLog-100k_log_6     |      50   | 0.02  |      110   | 3.2e-05   |       6 |
 | Log::ger-100k_log_is_trace               |      70   | 0.02  |      100   |   0.00055 |       7 |
 | Log::ger-100k_log_trace                  |      67   | 0.015 |      150   |   0.00014 |       6 |
 +------------------------------------------+-----------+-------+------------+-----------+---------+


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

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
