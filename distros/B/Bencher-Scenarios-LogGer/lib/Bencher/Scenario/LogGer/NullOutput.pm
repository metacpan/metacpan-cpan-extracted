package Bencher::Scenario::LogGer::NullOutput;

our $DATE = '2017-08-04'; # DATE
our $VERSION = '0.012'; # VERSION

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
        'Log::Dispatchouli' => {},
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

        {
            name => 'Log::Contextual+Log4perl' ,
            perl_cmdline_template => ['-e', 'use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..1_000_000) { log_trace {} }'],
        },
        {
            name => 'Log::Contextual+SimpleLogger' ,
            perl_cmdline_template => ['-MLog::Contextual::SimpleLogger', '-e', 'use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..1_000_000) { log_trace {} }'],
        },

        {
            name => 'Log::Dispatchouli' ,
            perl_cmdline_template => ['-MLog::Dispatchouli', '-e', '$logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..1_000_000) { $logger->log_debug("") }'],
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

This document describes version 0.012 of Bencher::Scenario::LogGer::NullOutput (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-08-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.049

L<Log::Contextual> 0.007001

L<Log::Contextual::SimpleLogger> 0.007001

L<Log::Dispatchouli> 2.015

L<Log::Fast> v2.0.0

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.023

L<Log::ger::Plugin::MultilevelLog> 0.023

L<Log::ger::Plugin::OptAway> 0.005

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



=item * Log::Contextual+Log4perl (command)

Command line:

 #TEMPLATE: #perl -e use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..1_000_000) { log_trace {} }



=item * Log::Contextual+SimpleLogger (command)

Command line:

 #TEMPLATE: #perl -MLog::Contextual::SimpleLogger -e use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..1_000_000) { log_trace {} }



=item * Log::Dispatchouli (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatchouli -e $logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..1_000_000) { $logger->log_debug("") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m LogGer::NullOutput >>):

 #table1#
 +------------------------------------------+-----------+-------+------------+-----------+---------+
 | participant                              | rate (/s) |  time | vs_slowest |  errors   | samples |
 +------------------------------------------+-----------+-------+------------+-----------+---------+
 | Log::Contextual+Log4perl                 |     0.17  | 5.89  |       1    |   0.0055  |       6 |
 | Log::Contextual+SimpleLogger             |     0.176 | 5.7   |       1.03 |   0.001   |       6 |
 | Log::Log4perl::Tiny-1mil_trace           |     0.84  | 1.2   |       5    |   0.0022  |       6 |
 | Log::Dispatchouli                        |     1.2   | 0.84  |       7    |   0.0037  |       6 |
 | Log::Any-null_adapter-1mil_log_trace     |     1.6   | 0.61  |       9.7  |   0.00084 |       6 |
 | Log::Fast-1mil_is_debug                  |     2.1   | 0.48  |      12    |   0.00058 |       6 |
 | Log::Any-no_adapter-1mil_is_trace        |     2.4   | 0.41  |      14    |   0.0018  |       6 |
 | Log::Any-null_adapter-1mil_is_trace      |     2.5   | 0.41  |      14    |   0.0019  |       6 |
 | Log::Log4perl-easy-1mil_trace            |     3.1   | 0.32  |      18    |   0.00064 |       6 |
 | Log::Fast-1mil_DEBUG                     |     6.3   | 0.16  |      37    |   0.00038 |       6 |
 | Log::Any-no_adapter-1mil_log_trace       |     6.4   | 0.16  |      38    |   0.00031 |       6 |
 | Log::ger+LGP:MutilevelLog-1mil_log_6     |     9.06  | 0.11  |      53.4  | 9.3e-05   |       6 |
 | Log::ger+LGP:MutilevelLog-1mil_log_trace |     9.12  | 0.11  |      53.7  | 8.4e-05   |       6 |
 | Log::ger-1mil_log_is_trace               |     9.3   | 0.11  |      55    |   0.00026 |       9 |
 | Log::ger-1mil_log_trace                  |    10     | 0.098 |      60    |   0.00013 |       6 |
 | Log::ger+LGP:OptAway-1mil_log_trace      |    22     | 0.046 |     130    |   9e-05   |       6 |
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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
