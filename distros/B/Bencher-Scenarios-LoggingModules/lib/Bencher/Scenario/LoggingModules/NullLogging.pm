package Bencher::Scenario::LoggingModules::NullLogging;

our $DATE = '2019-02-22'; # DATE
our $VERSION = '0.003'; # VERSION

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

This document describes version 0.003 of Bencher::Scenario::LoggingModules::NullLogging (from Perl distribution Bencher-Scenarios-LoggingModules), released on 2019-02-22.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LoggingModules::NullLogging

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.707

L<Log::Contextual> 0.007001

L<Log::Dispatch::Null> 2.65

L<Log::Dispatchouli> 2.015

L<Log::Fast> v2.0.0

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::Mini> 0.0.1

L<Log::ger> 0.025

L<Log::ger::Plugin::OptAway> 0.006

L<Mojo::Log>

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



=item * Log::ger-1mil_log_trace (command) (not included by default)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



=item * Log::ger+LGP:OptAway-1mil_log_trace (command) (not included by default)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=OptAway -MLog::ger -e for(1..1_000_000) { log_trace(q[]) }



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



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m LoggingModules::NullLogging >>):

 #table1#
 +-----------------------------------------+-----------+-------+------------+-----------+---------+
 | participant                             | rate (/s) |  time | vs_slowest |  errors   | samples |
 +-----------------------------------------+-----------+-------+------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug          |      0.59 | 1.7   |        1   |   0.013   |       7 |
 | Log::Contextual+Log4perl-100k_trace     |      1.5  | 0.66  |        2.6 |   0.0031  |       7 |
 | Log::Contextual+SimpleLogger-100k_trace |      1.6  | 0.64  |        2.6 |   0.0027  |       6 |
 | Mojo::Log-100k_debug                    |      3.1  | 0.32  |        5.3 |   0.00088 |       6 |
 | Log::Dispatchouli-100k_debug            |      4.7  | 0.21  |        7.9 |   0.00092 |       6 |
 | Log::Log4perl::Tiny-100k_trace          |      7.4  | 0.14  |       12   |   0.00064 |       6 |
 | Log::Mini-100k_trace                    |     11    | 0.088 |       19   |   0.00045 |       7 |
 | Log::Any-null_adapter-100k_log_trace    |     13    | 0.078 |       22   |   0.00018 |       8 |
 | Log::Log4perl-easy-100k_trace           |     15    | 0.067 |       25   |   0.00043 |       6 |
 | Log::Fast-100k_DEBUG                    |     22    | 0.045 |       38   | 9.4e-05   |       8 |
 | Log::Any-no_adapter-100k_log_trace      |     34    | 0.029 |       57   | 4.7e-05   |       6 |
 | Log::ger+LGP:OptAway-100k_log_trace     |     40    | 0.02  |       70   |   0.00046 |       6 |
 | Log::ger-100k_log_trace                 |     61    | 0.017 |      100   | 5.2e-05   |       6 |
 +-----------------------------------------+-----------+-------+------------+-----------+---------+


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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LoggingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
