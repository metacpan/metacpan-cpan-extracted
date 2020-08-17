package Bencher::Scenario::TextTableTiny::Render;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-08'; # DATE
our $DIST = 'Bencher-Scenarios-TextTableTiny'; # DIST
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of Bencher::Scenario::TextTableTiny::Render (from Perl distribution Bencher-Scenarios-TextTableTiny), released on 2020-08-08.

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

Benchmark with C<< bencher -m TextTableTiny::Render --include-path archive/Text-Table-Tiny-0.001/lib --include-path archive/Text-Table-Tiny-0.02/lib --include-path archive/Text-Table-Tiny-0.03/lib --include-path archive/Text-Table-Tiny-0.04/lib --include-path archive/Text-Table-Tiny-0.05/lib --include-path archive/Text-Table-Tiny-0.05_01/lib --include-path archive/Text-Table-Tiny-0.05_02/lib --include-path archive/Text-Table-Tiny-0.05_03/lib --include-path archive/Text-Table-Tiny-1.00/lib --multimodver Text::Table::Tiny >>:

 #table1#
 +----------------+---------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | dataset        | modver  | rate (/s) | time (ms)  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------+---------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | large (30x300) | 1.00    |      64   | 16         |                 0.00% |            241134.21% | 6.7e-05 |      21 |
 | large (30x300) | 0.05_03 |      65   | 15         |                 1.69% |            237113.64% | 3.5e-05 |      20 |
 | large (30x300) | 0.05_02 |      65   | 15         |                 1.98% |            236447.55% | 3.8e-05 |      20 |
 | large (30x300) | 0.05_01 |      93   | 11         |                45.89% |            165248.87% | 4.7e-05 |      20 |
 | long (3x300)   | 0.05_02 |     190   |  5.2       |               203.83% |             79297.23% | 8.9e-06 |      22 |
 | large (30x300) | 0.04    |     260   |  3.8       |               313.23% |             58277.57% | 3.6e-05 |      20 |
 | large (30x300) | 0.02    |     270   |  3.7       |               327.95% |             56269.30% | 1.5e-05 |      20 |
 | large (30x300) | 0.03    |     270   |  3.6       |               332.45% |             55683.60% | 1.6e-05 |      21 |
 | large (30x300) | 0.05    |     280   |  3.6       |               335.45% |             55298.21% |   6e-06 |      20 |
 | large (30x300) | 0.001   |     300   |  3.3       |               373.23% |             50876.43% | 1.4e-05 |      20 |
 | long (3x300)   | 1.00    |     560   |  1.8       |               786.34% |             27116.99% | 2.7e-06 |      20 |
 | long (3x300)   | 0.05_03 |     570   |  1.8       |               792.93% |             26916.05% |   2e-06 |      20 |
 | long (3x300)   | 0.05_01 |     700   |  1         |              1000.65% |             21817.49% | 2.6e-05 |      20 |
 | long (3x300)   | 0.05    |    2020   |  0.496     |              3070.32% |              7509.13% | 4.3e-07 |      20 |
 | long (3x300)   | 0.03    |    2000   |  0.5       |              3075.86% |              7495.88% | 6.8e-07 |      21 |
 | long (3x300)   | 0.02    |    2000   |  0.49      |              3085.61% |              7472.62% | 6.9e-07 |      20 |
 | long (3x300)   | 0.04    |    2030   |  0.493     |              3090.93% |              7460.00% | 4.8e-07 |      20 |
 | long (3x300)   | 0.001   |    2230   |  0.448     |              3414.39% |              6764.19% | 4.1e-07 |      22 |
 | wide (30x5)    | 0.05_03 |    3000   |  0.34      |              4552.06% |              5085.54% | 6.4e-07 |      20 |
 | wide (30x5)    | 1.00    |    2970   |  0.337     |              4567.82% |              5068.03% | 2.1e-07 |      20 |
 | wide (30x5)    | 0.05_02 |    2990   |  0.335     |              4600.85% |              5031.71% |   2e-07 |      22 |
 | wide (30x5)    | 0.05_01 |    4200   |  0.24      |              6482.04% |              3565.03% | 2.6e-07 |      21 |
 | wide (30x5)    | 0.05    |   10000   |  0.097     |             16193.65% |              1380.54% |   1e-07 |      21 |
 | wide (30x5)    | 0.02    |   10000   |  0.096     |             16235.61% |              1376.74% |   1e-07 |      22 |
 | wide (30x5)    | 0.04    |   10400   |  0.0957    |             16337.95% |              1367.54% | 2.7e-08 |      20 |
 | wide (30x5)    | 0.03    |   10000   |  0.095     |             16410.19% |              1361.12% |   1e-07 |      22 |
 | wide (30x5)    | 0.001   |   11000   |  0.088     |             17713.64% |              1254.21% | 1.1e-07 |      20 |
 | small (3x5)    | 1.00    |   20800   |  0.048     |             32643.17% |               636.75% | 4.7e-08 |      26 |
 | small (3x5)    | 0.05_02 |   21119.6 |  0.0473494 |             33123.93% |               626.09% |   0     |      21 |
 | small (3x5)    | 0.05_03 |   21200   |  0.0471    |             33293.11% |               622.41% | 1.3e-08 |      20 |
 | small (3x5)    | 0.05_01 |   27000   |  0.037     |             42440.50% |               467.07% | 5.2e-08 |      21 |
 | tiny (1x1)     | 0.05_03 |   50000   |  0.02      |             75358.33% |               219.69% |   1e-06 |      20 |
 | small (3x5)    | 0.05    |   56454.5 |  0.0177134 |             88710.48% |               171.63% |   0     |      21 |
 | small (3x5)    | 0.03    |   57611.1 |  0.0173578 |             90530.00% |               166.17% | 1.7e-11 |      20 |
 | small (3x5)    | 0.04    |   58000   |  0.017     |             91026.73% |               164.72% | 2.7e-08 |      20 |
 | small (3x5)    | 0.02    |   58000   |  0.017     |             91238.47% |               164.11% | 3.3e-08 |      20 |
 | small (3x5)    | 0.001   |   63121   |  0.015843  |             99198.03% |               142.94% | 2.3e-11 |      23 |
 | tiny (1x1)     | 1.00    |   67000   |  0.015     |            105120.19% |               129.27% | 2.7e-08 |      20 |
 | tiny (1x1)     | 0.05_02 |   69000   |  0.015     |            107856.61% |               123.45% | 2.7e-08 |      20 |
 | tiny (1x1)     | 0.05_01 |   76000   |  0.013     |            120138.74% |               100.63% | 2.7e-08 |      20 |
 | tiny (1x1)     | 0.05    |  134000   |  0.00747   |            210468.34% |                14.56% |   3e-09 |      24 |
 | tiny (1x1)     | 0.02    |  140000   |  0.0073    |            214028.30% |                12.66% | 2.3e-08 |      20 |
 | tiny (1x1)     | 0.03    |  140000   |  0.0072    |            219017.65% |                10.09% |   1e-08 |      20 |
 | tiny (1x1)     | 0.04    |  140000   |  0.0071    |            220061.62% |                 9.57% | 1.3e-08 |      20 |
 | tiny (1x1)     | 0.001   |  153000   |  0.00652   |            241134.21% |                 0.00% | 3.3e-09 |      20 |
 +----------------+---------+-----------+------------+-----------------------+-----------------------+---------+---------+


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
