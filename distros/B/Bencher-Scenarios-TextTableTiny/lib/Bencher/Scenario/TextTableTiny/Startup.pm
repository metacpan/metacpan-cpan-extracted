package Bencher::Scenario::TextTableTiny::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'Bencher-Scenarios-TextTableTiny'; # DIST
our $VERSION = '0.001'; # VERSION

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

This document describes version 0.001 of Bencher::Scenario::TextTableTiny::Startup (from Perl distribution Bencher-Scenarios-TextTableTiny), released on 2020-08-04.

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

Benchmark with C<< bencher -m TextTableTiny::Startup --include-path archive/Text-Table-Tiny-0.001/lib --include-path archive/Text-Table-Tiny-0.02/lib --include-path archive/Text-Table-Tiny-0.03/lib --include-path archive/Text-Table-Tiny-0.04/lib --include-path archive/Text-Table-Tiny-0.05/lib --include-path archive/Text-Table-Tiny-0.05_01/lib --multimodver Text::Table::Tiny >>:

 #table1#
 +---------------------+---------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | modver  | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+---------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Text::Table::Tiny   | 0.05    |       9   |               6.7 |                 0.00% |               295.42% | 1.4e-05 |      21 |
 | Text::Table::Tiny   | 0.05_01 |       8.7 |               6.4 |                 3.83% |               280.85% | 3.2e-05 |      20 |
 | Text::Table::Tiny   | 0.04    |       6.2 |               3.9 |                46.52% |               169.88% | 8.7e-06 |      20 |
 | Text::Table::Tiny   | 0.02    |       6   |               3.7 |                49.83% |               163.91% | 3.1e-05 |      20 |
 | Text::Table::Tiny   | 0.03    |       6   |               3.7 |                51.47% |               161.06% | 1.3e-05 |      20 |
 | Text::Table::Tiny   | 0.001   |       4.7 |               2.4 |                92.45% |               105.47% | 9.4e-06 |      20 |
 | perl -e1 (baseline) |         |       2.3 |               0   |               295.42% |                 0.00% | 5.6e-06 |      20 |
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
