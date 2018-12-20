package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2018-12-20'; # DATE
our $VERSION = '0.014'; # VERSION

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

This document describes version 0.014 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2018-12-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.707

L<Log::Contextual> 0.007001

L<Log::Contextual::SimpleLogger> 0.007001

L<Log::Dispatch> 2.65

L<Log::Dispatch::Null> 2.65

L<Log::Dispatchouli> 2.015

L<Log::Fast> v2.0.0

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.025

L<Log::ger::Plugin::MultilevelLog> 0.025

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

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +------------------------------------------+-----------+--------+------------+-----------+---------+
 | participant                              | rate (/s) |   time | vs_slowest |  errors   | samples |
 +------------------------------------------+-----------+--------+------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug           |      0.59 | 1.7    |        1   |   0.0039  |       6 |
 | Log::Contextual+Log4perl-100k_trace      |      1.5  | 0.66   |        2.6 |   0.0046  |       6 |
 | Log::Contextual+SimpleLogger-100k_trace  |      1.5  | 0.65   |        2.6 |   0.0032  |       6 |
 | Mojo::Log-100k_debug                     |      3.1  | 0.32   |        5.3 |   0.0014  |       6 |
 | Log::Dispatchouli-100k_debug             |      5    | 0.2    |        8   |   0.0023  |       6 |
 | Log::Log4perl::Tiny-100k_trace           |      7.3  | 0.14   |       13   |   0.00044 |       6 |
 | Log::Fast-100k_is_debug                  |     10    | 0.08   |       20   |   0.00087 |       6 |
 | Log::Any-null_adapter-100k_log_trace     |     13    | 0.079  |       22   |   0.00025 |       7 |
 | Log::Log4perl-easy-100k_trace            |     14    | 0.069  |       25   |   0.00012 |       6 |
 | Log::Any-no_adapter-100k_is_trace        |     20    | 0.06   |       30   |   0.00097 |       6 |
 | Log::Any-null_adapter-100k_is_trace      |     20    | 0.06   |       30   |   0.0007  |       9 |
 | Log::Fast-100k_DEBUG                     |     20    | 0.05   |       40   |   0.00071 |       6 |
 | Log::Any-no_adapter-100k_log_trace       |     30    | 0.03   |       60   |   0.00037 |       6 |
 | Log::ger+LGP:OptAway-100k_log_trace      |     44.8  | 0.0223 |       76.5 |   4e-06   |       6 |
 | Log::ger+LGP:MutilevelLog-100k_log_6     |     45    | 0.022  |       77   | 9.8e-05   |       7 |
 | Log::ger+LGP:MutilevelLog-100k_log_trace |     46    | 0.022  |       79   |   0.00016 |       6 |
 | Log::ger-100k_log_is_trace               |     59    | 0.017  |      100   | 7.9e-05   |       6 |
 | Log::ger-100k_log_trace                  |     59    | 0.017  |      100   | 1.7e-05   |       6 |
 +------------------------------------------+-----------+--------+------------+-----------+---------+


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

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
