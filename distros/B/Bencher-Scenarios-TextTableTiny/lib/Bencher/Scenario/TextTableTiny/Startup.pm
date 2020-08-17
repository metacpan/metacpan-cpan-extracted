package Bencher::Scenario::TextTableTiny::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-08'; # DATE
our $DIST = 'Bencher-Scenarios-TextTableTiny'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    module_startup => 1,
    modules => {
    },
    participants => [
        {module => 'Text::Table::Tiny'},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TextTableTiny::Startup

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::TextTableTiny::Startup (from Perl distribution Bencher-Scenarios-TextTableTiny), released on 2020-08-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TextTableTiny::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Tiny> 0.05

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Tiny (perl_code)

L<Text::Table::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-62-generic >>.

Benchmark with C<< bencher -m TextTableTiny::Startup --include-path archive/Text-Table-Tiny-0.001/lib --include-path archive/Text-Table-Tiny-0.02/lib --include-path archive/Text-Table-Tiny-0.03/lib --include-path archive/Text-Table-Tiny-0.04/lib --include-path archive/Text-Table-Tiny-0.05/lib --include-path archive/Text-Table-Tiny-0.05_01/lib --include-path archive/Text-Table-Tiny-0.05_02/lib --include-path archive/Text-Table-Tiny-0.05_03/lib --include-path archive/Text-Table-Tiny-1.00/lib --multimodver Text::Table::Tiny >>:

 #table1#
 +---------------------+---------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | modver  | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+---------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Tiny   | 1.00    |      10   |               7.6 |                 0.00% |               339.82% | 3.5e-05 |      20 |
 | Text::Table::Tiny   | 0.05_02 |      10   |               7.6 |                 1.10% |               335.03% | 8.5e-05 |      20 |
 | Text::Table::Tiny   | 0.05_03 |      10   |               7.6 |                 4.53% |               320.76% | 1.8e-05 |      20 |
 | Text::Table::Tiny   | 0.05    |       9.2 |               6.8 |                13.42% |               287.79% | 3.6e-05 |      20 |
 | Text::Table::Tiny   | 0.05_01 |       8.8 |               6.4 |                18.65% |               270.69% | 2.1e-05 |      20 |
 | Text::Table::Tiny   | 0.04    |       6.3 |               3.9 |                65.31% |               166.06% |   2e-05 |      20 |
 | Text::Table::Tiny   | 0.02    |       6.1 |               3.7 |                71.19% |               156.92% | 2.3e-05 |      20 |
 | Text::Table::Tiny   | 0.03    |       6.1 |               3.7 |                71.71% |               156.14% | 1.8e-05 |      20 |
 | Text::Table::Tiny   | 0.001   |       4.9 |               2.5 |               115.87% |               103.74% | 2.2e-05 |      20 |
 | perl -e1 (baseline) |         |       2.4 |               0   |               339.82% |                 0.00% | 9.2e-06 |      20 |
 +---------------------+---------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TextTableTiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TextTableTiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TextTableTiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
