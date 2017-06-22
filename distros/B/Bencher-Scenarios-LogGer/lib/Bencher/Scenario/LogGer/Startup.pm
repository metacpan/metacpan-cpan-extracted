package Bencher::Scenario::LogGer::Startup;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    modules => {
        'Log::ger' => {version=>'0.002'},
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        {name=>"use Log::ger ()", module=>'Log::ger', perl_cmdline => ["-mLog::ger", "-e1"]},

        {name=>"use Log::ger" , module=>'Log::ger', perl_cmdline => ["-MLog::ger", "-e1"]},
        {name=>"use Log::ger + use Log::ger::OptAway" , module=>'Log::ger::OptAway', perl_cmdline => ["-MLog::ger::OptAway", "-MLog::ger", "-e1"]},
        {name=>"use Log::ger + use Log::ger::Output::Screen" , module=>'Log::ger::Output::Screen', perl_cmdline => ["-MLog::ger", "-MLog::ger::Output=Screen", "-e1"]},

        {name=>"use Log::Any" , module=>'Log::Any', perl_cmdline => ["-MLog::Any", "-e1"]},
        {name=>"use Log::Any + use Log::Any::Adapter::Screen" , module=>'Log::Any::Adapter::Screen', perl_cmdline => ["-MLog::Any", "-MLog::Any::Adapter=Screen", "-e1"]},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::Startup

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::LogGer::Startup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-06-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Startup

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.049

L<Log::Any::Adapter::Screen> 0.13

L<Log::ger> 0.004

L<Log::ger::OptAway> 0.002

L<Log::ger::Output::Screen> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * use Log::ger () (command)

L<Log::ger>



=item * use Log::ger (command)

L<Log::ger>



=item * use Log::ger + use Log::ger::OptAway (command)

L<Log::ger::OptAway>



=item * use Log::ger + use Log::ger::Output::Screen (command)

L<Log::ger::Output::Screen>



=item * use Log::Any (command)

L<Log::Any>



=item * use Log::Any + use Log::Any::Adapter::Screen (command)

L<Log::Any::Adapter::Screen>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with C<< bencher -m LogGer::Startup --include-path archive/Log-Any-0.15/lib --multimodver Log::Any >>:

 #table1#
 +----------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                                  | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | use Log::ger + use Log::ger::OptAway         |        |        66 |      15   |        1   | 5.9e-05 |      20 |
 | use Log::Any + use Log::Any::Adapter::Screen |        |        77 |      13   |        1.2 | 4.6e-05 |      20 |
 | use Log::Any                                 | 1.049  |        91 |      11   |        1.4 | 7.4e-05 |      20 |
 | use Log::ger + use Log::ger::Output::Screen  |        |       150 |       6.8 |        2.2 | 2.2e-05 |      20 |
 | use Log::Any                                 | 0.15   |       210 |       4.8 |        3.2 | 1.1e-05 |      21 |
 | use Log::ger                                 |        |       340 |       2.9 |        5.2 | 2.7e-05 |      20 |
 | use Log::ger ()                              |        |       350 |       2.8 |        5.4 | 2.5e-05 |      20 |
 | baseline                                     |        |       600 |       2   |        9   | 1.7e-05 |      20 |
 +----------------------------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::Startup --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Log::Any::Adapter::Screen | 1.5                          | 5.1                | 21             |      18   |                   12.3 |        1   |   0.00014 |      20 |
 | Log::Any                  | 1.1                          | 4.5                | 20             |      15   |                    9.3 |        1.2 |   0.00011 |      20 |
 | Log::ger::OptAway         | 0.95                         | 4.4                | 20             |      11   |                    5.3 |        1.7 |   6e-05   |      20 |
 | Log::ger::Output::Screen  | 1.1                          | 4.5                | 20             |      10   |                    4.3 |        1.7 | 3.6e-05   |      22 |
 | Log::ger                  | 0.95                         | 4.4                | 20             |       7.5 |                    1.8 |        2.4 | 4.4e-05   |      21 |
 | perl -e1 (baseline)       | 0.82                         | 4.3                | 20             |       5.7 |                    0   |        3.1 | 3.1e-05   |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


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
