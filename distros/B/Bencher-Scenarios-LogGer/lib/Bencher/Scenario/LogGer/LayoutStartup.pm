package Bencher::Scenario::LogGer::LayoutStartup;

our $DATE = '2020-01-13'; # DATE
our $VERSION = '0.016'; # VERSION

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

This document describes version 0.016 of Bencher::Scenario::LogGer::LayoutStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2020-01-13.

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

L<Log::ger::Layout::JSON> 0.001

L<Log::ger::Layout::LTSV> 0.003

L<Log::ger::Layout::Pattern> 0.004

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

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LogGer::LayoutStartup >>):

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | load-JSON    |      80.9 |     12.4  |                 0.00% |                92.49% | 4.5e-06 |      20 |
 | load-YAML    |      80.9 |     12.4  |                 0.01% |                92.47% | 4.7e-06 |      20 |
 | load-LTSV    |      83.1 |     12    |                 2.66% |                87.50% | 5.2e-06 |      20 |
 | load-Pattern |      83.4 |     12    |                 2.99% |                86.90% | 4.5e-06 |      20 |
 | baseline     |     156   |      6.42 |                92.49% |                 0.00% | 5.3e-06 |      20 |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::LayoutStartup --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Layout::JSON    |     12.4  |              5.98 |                 0.00% |                93.01% | 5.3e-06 |      20 |
 | Log::ger::Layout::YAML    |     12.4  |              5.98 |                 0.11% |                92.81% | 7.2e-06 |      21 |
 | Log::ger::Layout::LTSV    |     12.1  |              5.68 |                 2.28% |                88.71% | 8.5e-06 |      20 |
 | Log::ger::Layout::Pattern |     12    |              5.58 |                 3.22% |                87.00% | 5.5e-06 |      24 |
 | perl -e1 (baseline)       |      6.42 |              0    |                93.01% |                 0.00% | 3.1e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


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

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
