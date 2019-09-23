package Bencher::Scenario::LogGer::LayoutStartup;

our $DATE = '2019-09-18'; # DATE
our $VERSION = '0.015'; # VERSION

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

This document describes version 0.015 of Bencher::Scenario::LogGer::LayoutStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2019-09-18.

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m LogGer::LayoutStartup >>):

 #table1#
 +--------------+-----------+-----------+------------+---------+---------+
 | participant  | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +--------------+-----------+-----------+------------+---------+---------+
 | load-JSON    |        75 |        13 |        1   | 3.1e-05 |      20 |
 | load-YAML    |        75 |        13 |        1   | 1.7e-05 |      20 |
 | load-LTSV    |        76 |        13 |        1   | 3.4e-05 |      20 |
 | load-Pattern |        77 |        13 |        1   | 1.3e-05 |      20 |
 | baseline     |       170 |         6 |        2.2 | 3.6e-05 |      20 |
 +--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::LayoutStartup --module-startup >>):

 #table2#
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Layout::YAML    |      13.3 |                    7.2 |        1   | 1.3e-05 |      20 |
 | Log::ger::Layout::JSON    |      13.3 |                    7.2 |        1   | 5.3e-06 |      20 |
 | Log::ger::Layout::LTSV    |      13   |                    6.9 |        1   | 1.8e-05 |      20 |
 | Log::ger::Layout::Pattern |      13   |                    6.9 |        1   |   2e-05 |      20 |
 | perl -e1 (baseline)       |       6.1 |                    0   |        2.2 | 1.9e-05 |      21 |
 +---------------------------+-----------+------------------------+------------+---------+---------+


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
