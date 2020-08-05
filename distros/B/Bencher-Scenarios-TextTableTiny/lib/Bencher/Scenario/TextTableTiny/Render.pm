package Bencher::Scenario::TextTableTiny::Render;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'Bencher-Scenarios-TextTableTiny'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub _make_table {
    my ($cols, $rows) = @_;
    my $res = [];
    push @$res, [];
    for (0..$cols-1) { $res->[0][$_] = "col" . ($_+1) }
    for my $row (1..$rows) {
        push @$res, [ map { "row$row.$_" } 1..$cols ];
    }
    $res;
}

our $scenario = {
    summary => "Benchmark Text::Table::Tiny's rendering speed",
    participants => [
        {
            module => 'Text::Table::Tiny',
            code_template => 'Text::Table::Tiny::table(rows=><table>, header_row=>1)',
        },
    ],
    datasets => [
        {name=>'tiny (1x1)'    , args => {table=>_make_table( 1, 1)},},
        {name=>'small (3x5)'   , args => {table=>_make_table( 3, 5)},},
        {name=>'wide (30x5)'   , args => {table=>_make_table(30, 5)},},
        {name=>'long (3x300)'  , args => {table=>_make_table( 3, 300)},},
        {name=>'large (30x300)', args => {table=>_make_table(30, 300)},},
    ],
};

1;
# ABSTRACT: Benchmark Text::Table::Tiny's rendering speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TextTableTiny::Render - Benchmark Text::Table::Tiny's rendering speed

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::TextTableTiny::Render (from Perl distribution Bencher-Scenarios-TextTableTiny), released on 2020-08-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TextTableTiny::Render

To run module startup overhead benchmark:

 % bencher --module-startup -m TextTableTiny::Render

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Text::Table::Tiny> 0.05

=head1 BENCHMARK PARTICIPANTS

=over

=item * Text::Table::Tiny (perl_code)

Code template:

 Text::Table::Tiny::table(rows=><table>, header_row=>1)



=back

=head1 BENCHMARK DATASETS

=over

=item * tiny (1x1)

=item * small (3x5)

=item * wide (30x5)

=item * long (3x300)

=item * large (30x300)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-62-generic >>.

Benchmark with C<< bencher -m TextTableTiny::Render --include-path archive/Text-Table-Tiny-0.001/lib --include-path archive/Text-Table-Tiny-0.02/lib --include-path archive/Text-Table-Tiny-0.03/lib --include-path archive/Text-Table-Tiny-0.04/lib --include-path archive/Text-Table-Tiny-0.05/lib --include-path archive/Text-Table-Tiny-0.05_01/lib --multimodver Text::Table::Tiny >>:

 #table1#
 +----------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset        | modver  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | large (30x300) | 0.05_01 |      95   | 11        |                 0.00% |            159509.63% | 2.7e-05 |      20 |
 | large (30x300) | 0.02    |     200   |  5        |               113.24% |             74749.38% | 7.7e-05 |      20 |
 | large (30x300) | 0.04    |     300   |  4        |               169.48% |             59128.44% | 4.2e-05 |      20 |
 | large (30x300) | 0.03    |     300   |  4        |               174.00% |             58150.78% | 5.3e-05 |      20 |
 | large (30x300) | 0.05    |     270   |  3.6      |               190.13% |             54912.36% | 9.2e-06 |      20 |
 | large (30x300) | 0.001   |     300   |  3.3      |               215.65% |             50466.01% | 1.5e-05 |      20 |
 | long (3x300)   | 0.05_01 |     500   |  2        |               428.04% |             30126.61% | 7.6e-05 |      26 |
 | long (3x300)   | 0.04    |    1100   |  0.88     |              1104.88% |             13146.92% | 4.7e-06 |      20 |
 | long (3x300)   | 0.03    |    2000   |  0.51     |              1987.59% |              7545.64% | 1.5e-06 |      20 |
 | long (3x300)   | 0.05    |    2000   |  0.5      |              2011.76% |              7458.15% | 2.7e-07 |      20 |
 | long (3x300)   | 0.02    |    2000   |  0.5      |              2012.15% |              7456.74% | 4.3e-07 |      20 |
 | long (3x300)   | 0.001   |    2220   |  0.451    |              2241.76% |              6715.80% | 4.2e-07 |      21 |
 | wide (30x5)    | 0.05_01 |    4100   |  0.24     |              4228.72% |              3587.22% | 1.1e-06 |      20 |
 | wide (30x5)    | 0.04    |    6100   |  0.16     |              6375.72% |              2364.74% | 1.1e-06 |      20 |
 | wide (30x5)    | 0.05    |   10000   |  0.097    |             10832.89% |              1359.90% | 1.1e-07 |      20 |
 | wide (30x5)    | 0.03    |   10400   |  0.0964   |             10840.41% |              1358.90% | 2.4e-08 |      24 |
 | wide (30x5)    | 0.02    |   10000   |  0.096    |             10888.74% |              1352.48% | 1.1e-07 |      20 |
 | wide (30x5)    | 0.001   |   11000   |  0.089    |             11705.62% |              1251.98% | 1.9e-07 |      26 |
 | small (3x5)    | 0.05_01 |   26832.7 |  0.037268 |             28212.95% |               463.73% | 5.1e-12 |      20 |
 | small (3x5)    | 0.04    |   34000   |  0.029    |             36238.44% |               339.23% | 1.6e-07 |      20 |
 | small (3x5)    | 0.05    |   56000   |  0.018    |             59258.94% |               168.89% | 3.3e-08 |      20 |
 | small (3x5)    | 0.03    |   56900   |  0.0176   |             59989.58% |               165.62% | 6.7e-09 |      20 |
 | small (3x5)    | 0.02    |   57700   |  0.0173   |             60763.31% |               162.24% | 6.5e-09 |      21 |
 | small (3x5)    | 0.001   |   62500   |  0.016    |             65795.84% |               142.22% | 6.2e-09 |      23 |
 | tiny (1x1)     | 0.05_01 |   76300   |  0.0131   |             80402.53% |                98.27% | 6.7e-09 |      20 |
 | tiny (1x1)     | 0.04    |   80000   |  0.013    |             84153.59% |                89.44% | 2.7e-08 |      20 |
 | tiny (1x1)     | 0.05    |  130400   |  0.007667 |            137532.47% |                15.97% |   3e-10 |      22 |
 | tiny (1x1)     | 0.03    |  140000   |  0.0073   |            143593.05% |                11.08% | 1.3e-08 |      20 |
 | tiny (1x1)     | 0.02    |  140000   |  0.0072   |            146001.91% |                 9.25% |   1e-08 |      20 |
 | tiny (1x1)     | 0.001   |  151000   |  0.00661  |            159509.63% |                 0.00% | 3.3e-09 |      20 |
 +----------------+---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


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
