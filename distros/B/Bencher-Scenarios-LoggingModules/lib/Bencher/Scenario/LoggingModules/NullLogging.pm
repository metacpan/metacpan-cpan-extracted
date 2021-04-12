package Bencher::Scenario::LoggingModules::NullLogging;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

#use Bencher::ScenarioUtil::LoggingModules::Participant;

our $scenario = {
    summary => 'Benchmark logging statement that does not output anywhere '.
        '(to measure logging overhead)',
    modules => {
        'Log::Any' => {},
        'Log::Contextual' => {},
        'Log::Dispatchouli' => {},
        'Log::Dispatch::Null' => {},
        'Log::Fast' => {},
        'Log::ger' => {},
        'Log::ger::Plugin::OptAway' => {},
        'Log::Log4perl' => {},
        'Log::Log4perl::Tiny' => {},
        'Log::Mini' => {},
        'Mojo::Log' => {},
        'XLog' => {},
    },
    participants => [

        {
            name => 'Log::Any-no_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-null_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
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
            name => 'Log::Dispatch::Null-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatch', '-e', 'my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }'],
        },

        {
            name => 'Log::Dispatchouli-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatchouli', '-e', '$logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }'],
        },

        {
            name => 'Log::Fast-100k_DEBUG',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }'],
        },

        {
            name => 'Log::ger-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger+LGP:OptAway-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=OptAway', '-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..1_000_000) { log_trace(q[]) }'],
            include_by_default => 0,
        },
        {
            name => 'Log::ger+LGP:OptAway-1mil_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=OptAway', '-MLog::ger', '-e', 'for(1..1_000_000) { log_trace(q[]) }'],
            include_by_default => 0,
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
            name => 'Log::Mini-100k_trace',
            perl_cmdline_template => ['-MLog::Mini', '-e', '$log = Log::Mini->new("stderr"); for(1..100_000) { $log->trace(q[]) }'],
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
# ABSTRACT: Benchmark logging statement that does not output anywhere (to measure logging overhead)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LoggingModules::NullLogging - Benchmark logging statement that does not output anywhere (to measure logging overhead)

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::LoggingModules::NullLogging (from Perl distribution Bencher-Scenarios-LoggingModules), released on 2021-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LoggingModules::NullLogging

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.708

L<Log::Contextual> 0.008001

L<Log::Dispatch::Null> 2.68

L<Log::Dispatchouli> 2.019

L<Log::Fast> v2.0.1

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::Mini> 0.2.1

L<Log::ger> 0.038

L<Log::ger::Plugin::OptAway> 0.009

L<Mojo::Log>

L<XLog> 1.1.0

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::Any-no_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Any-null_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Contextual+Log4perl-100k_trace (command)

Command line:

 #TEMPLATE: #perl -e use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..100_000) { log_trace {} }



=item * Log::Contextual+SimpleLogger-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Contextual::SimpleLogger -e use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..100_000) { log_trace {} }



=item * Log::Dispatch::Null-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatch -e my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }



=item * Log::Dispatchouli-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatchouli -e $logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }



=item * Log::Fast-100k_DEBUG (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }



=item * Log::ger-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::ger+LGP:OptAway-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=OptAway -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::Log4perl-easy-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl=:easy -e Log::Log4perl->easy_init($ERROR); for(1..100_000) { TRACE "" }



=item * Log::Log4perl::Tiny-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl::Tiny=:easy -e for(1..100_000) { TRACE "" }



=item * Log::Mini-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Mini -e $log = Log::Mini->new("stderr"); for(1..100_000) { $log->trace(q[]) }



=item * Mojo::Log-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MMojo::Log -e $log = Mojo::Log->new(level=>"warn"); for(1..100_000) { $log->debug("") }



=item * XLog-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MXLog -e for(1..100_000) { XLog::debug("") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LoggingModules::NullLogging >>):

 #table1#
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                             | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug          |      1.9  |     510   |                 0.00% |              3813.48% |   0.0011  |       6 |
 | Log::Contextual+Log4perl-100k_trace     |      2.1  |     470   |                 9.28% |              3481.25% |   0.00073 |       8 |
 | Log::Contextual+SimpleLogger-100k_trace |      2.3  |     440   |                15.97% |              3274.65% |   0.0011  |       6 |
 | Log::Dispatchouli-100k_debug            |      6.36 |     157   |               226.94% |              1097.00% |   0.00013 |       6 |
 | Mojo::Log-100k_debug                    |      6.8  |     150   |               247.48% |              1026.25% |   0.00027 |       6 |
 | Log::Log4perl::Tiny-100k_trace          |      9.9  |     100   |               406.10% |               673.26% |   0.0008  |       6 |
 | Log::Mini-100k_trace                    |     16    |      62   |               722.11% |               376.03% |   0.00017 |       7 |
 | Log::Any-null_adapter-100k_log_trace    |     17    |      61   |               748.41% |               361.27% |   0.00013 |       6 |
 | Log::Log4perl-easy-100k_trace           |     19.1  |      52.4 |               880.30% |               299.21% | 1.2e-05   |       6 |
 | Log::Fast-100k_DEBUG                    |     27    |      37   |              1288.07% |               181.94% |   0.00013 |       6 |
 | XLog-100k_debug                         |     38    |      27   |              1832.76% |               102.48% | 4.7e-05   |       6 |
 | Log::Any-no_adapter-100k_log_trace      |     38    |      26   |              1872.17% |                98.44% |   0.00016 |       9 |
 | Log::ger+LGP:OptAway-100k_log_trace     |     44    |      23   |              2165.21% |                72.76% |   0.00019 |       6 |
 | Log::ger-100k_log_trace                 |     76    |      13   |              3813.48% |                 0.00% | 3.6e-05   |       6 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

You might notice that L<Log::ger>+L<Log::ger::Plugin::OptAway> (LGP:OptAway) is
slower than plain Log::ger at 100k trace. This is because the plugin loading and
setup overhead eclipses the gain provided by the OptAway plugin. If you try the
these not-included-by-default participants they will show the benefit of
OptAway:

 Log::ger-1mil_log_trace
 Log::ger+LGP:OptAway-1mil_log_trace

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LoggingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LoggingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenarios-LoggingModules/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
