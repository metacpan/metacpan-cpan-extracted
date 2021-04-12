package Bencher::Scenario::LogGer::LayoutStartup;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.018'; # VERSION

use 5.010001;
use strict;
use warnings;

our %layout_modules = (
    Pattern => {format=>'[%d] %m'},
    LTSV => {},
    JSON => {},
    YAML => {},
);

our $scenario = {
    modules => {
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        map {
            (
                +{
                    name => "load-$_",
                    module => "Log::ger::Layout::$_",
                    perl_cmdline => ["-mLog::ger::Layout::$_", "-e1"],
                },
            )
        } sort keys %layout_modules,
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::LayoutStartup

=head1 VERSION

This document describes version 0.018 of Bencher::Scenario::LogGer::LayoutStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2021-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::LayoutStartup

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::LayoutStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Layout::JSON> 0.002

L<Log::ger::Layout::LTSV> 0.006

L<Log::ger::Layout::Pattern> 0.007

L<Log::ger::Layout::YAML> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * load-JSON (command)

L<Log::ger::Layout::JSON>



=item * load-LTSV (command)

L<Log::ger::Layout::LTSV>



=item * load-Pattern (command)

L<Log::ger::Layout::Pattern>



=item * load-YAML (command)

L<Log::ger::Layout::YAML>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LogGer::LayoutStartup >>):

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | load-YAML    |      70   |      10   |                 0.00% |               104.71% |   0.00018 |      20 |
 | load-JSON    |      78.8 |      12.7 |                14.29% |                79.10% | 8.9e-06   |      20 |
 | load-LTSV    |      81   |      12   |                17.07% |                74.86% | 1.3e-05   |      20 |
 | load-Pattern |      81   |      12.4 |                17.44% |                74.31% | 1.1e-05   |      20 |
 | baseline     |     140   |       7.1 |               104.71% |                 0.00% | 4.5e-05   |      20 |
 +--------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::LayoutStartup --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Layout::YAML    |        14 |                 6 |                 0.00% |                81.18% | 1.9e-05 |      20 |
 | Log::ger::Layout::JSON    |        13 |                 5 |                 1.95% |                77.72% | 8.6e-05 |      22 |
 | Log::ger::Layout::LTSV    |        13 |                 5 |                 5.80% |                71.25% | 5.3e-05 |      20 |
 | Log::ger::Layout::Pattern |        13 |                 5 |                 7.48% |                68.58% | 6.6e-05 |      20 |
 | perl -e1 (baseline)       |         8 |                 0 |                81.18% |                 0.00% | 7.8e-05 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


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
