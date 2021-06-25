package Bencher::Scenario::StringFunctions::Trim;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-23'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark string trimming (removing whitespace at the start and end of string)",
    participants => [
        #{fcall_template=>'String::Trim::trim(<str>)'}, # currently disabled, see https://github.com/doherty/String-Trim/issues/7
        {fcall_template=>'String::Trim::More::trim(<str>)'},
        {fcall_template=>'String::Trim::NonRegex::trim(<str>)'},
        {fcall_template=>'String::Trim::Regex::trim(<str>)'},
        {fcall_template=>'String::Util::trim(<str>)'},
        {fcall_template=>'Text::Minify::XS::minify(<str>)'},
    ],
    datasets => [
        {name=>'empty'        , args=>{str=>''}},
        {name=>'len10ws1'     , args=>{str=>' '.('x' x   10).' '}},
        {name=>'len100ws1'    , args=>{str=>' '.('x' x  100).' '}},
        {name=>'len100ws10'   , args=>{str=>(' ' x   10).('x' x  100).(' ' x 10)}},
        {name=>'len100ws100'  , args=>{str=>(' ' x  100).('x' x  100).(' ' x 100)}},
        {name=>'len1000ws1'   , args=>{str=>' '.('x' x 1000).' '}},
        {name=>'len1000ws10'  , args=>{str=>(' ' x   10).('x' x 1000).(' ' x 10)}},
        {name=>'len1000ws100' , args=>{str=>(' ' x  100).('x' x 1000).(' ' x 100)}},
        {name=>'len1000ws1000', args=>{str=>(' ' x 1000).('x' x 1000).(' ' x 1000)}},
    ],
};

1;
# ABSTRACT: Benchmark string trimming (removing whitespace at the start and end of string)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringFunctions::Trim - Benchmark string trimming (removing whitespace at the start and end of string)

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::StringFunctions::Trim (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-06-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringFunctions::Trim

To run module startup overhead benchmark:

 % bencher --module-startup -m StringFunctions::Trim

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::Trim::More> 0.03

L<String::Trim::NonRegex> 0.001

L<String::Trim::Regex> 20210604

L<String::Util> 1.32

L<Text::Minify::XS> v0.4.2

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::Trim::More::trim (perl_code)

Function call template:

 String::Trim::More::trim(<str>)



=item * String::Trim::NonRegex::trim (perl_code)

Function call template:

 String::Trim::NonRegex::trim(<str>)



=item * String::Trim::Regex::trim (perl_code)

Function call template:

 String::Trim::Regex::trim(<str>)



=item * String::Util::trim (perl_code)

Function call template:

 String::Util::trim(<str>)



=item * Text::Minify::XS::minify (perl_code)

Function call template:

 Text::Minify::XS::minify(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * len10ws1

=item * len100ws1

=item * len100ws10

=item * len100ws100

=item * len1000ws1

=item * len1000ws10

=item * len1000ws100

=item * len1000ws1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::Trim >>):

 #table1#
 {dataset=>"empty"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Util::trim           |   1494000 |     669.3 |                 0.00% |               447.30% |   1e-11 |      21 |
 | String::Trim::NonRegex::trim |   1570000 |     636   |                 5.20% |               420.25% | 1.8e-10 |      28 |
 | String::Trim::More::trim     |   6090000 |     164   |               307.47% |                34.32% |   1e-10 |      20 |
 | String::Trim::Regex::trim    |   7180000 |     139   |               380.77% |                13.84% | 6.9e-11 |      20 |
 | Text::Minify::XS::minify     |   8177000 |     122.3 |               447.30% |                 0.00% |   1e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table2#
 {dataset=>"len1000ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   18437.5 |   54.2374 |                 0.00% |              5517.15% | 1.2e-11 |      28 |
 | String::Util::trim           |   22900   |   43.6    |                24.39% |              4415.65% | 1.2e-08 |      26 |
 | String::Trim::More::trim     |  390540   |    2.5605 |              2018.21% |               165.18% | 9.5e-12 |      20 |
 | Text::Minify::XS::minify     |  557270   |    1.7945 |              2922.48% |                85.85% | 1.1e-11 |      20 |
 | String::Trim::NonRegex::trim | 1036000   |    0.9656 |              5517.15% |                 0.00% | 9.8e-12 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table3#
 {dataset=>"len1000ws10"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   18428.2 |   54.2646 |                 0.00% |              2872.02% | 9.8e-12 |      29 |
 | String::Util::trim           |   22900   |   43.6    |                24.40% |              2289.01% | 1.1e-08 |      31 |
 | String::Trim::NonRegex::trim |  306750   |    3.26   |              1564.58% |                78.54% | 1.1e-11 |      21 |
 | String::Trim::More::trim     |  388090   |    2.5767 |              2005.96% |                41.12% | 9.1e-12 |      20 |
 | Text::Minify::XS::minify     |  547690   |    1.8259 |              2872.02% |                 0.00% | 1.2e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"len1000ws100"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   18366.5 |   54.4469 |                 0.00% |              2418.31% | 1.1e-11 |      20 |
 | String::Util::trim           |   22843.4 |   43.7763 |                24.38% |              1924.76% | 9.4e-12 |      29 |
 | String::Trim::NonRegex::trim |   40200   |   24.9    |               118.68% |              1051.59% | 6.2e-09 |      23 |
 | String::Trim::More::trim     |  368000   |    2.72   |              1905.05% |                25.60% | 8.3e-10 |      20 |
 | Text::Minify::XS::minify     |  463000   |    2.16   |              2418.31% |                 0.00% | 6.8e-10 |      30 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"len1000ws1000"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::NonRegex::trim |      4140 |  242      |                 0.00% |              6138.52% | 4.7e-08 |      26 |
 | String::Trim::Regex::trim    |     18000 |   55      |               336.14% |              1330.41% |   1e-07 |      21 |
 | String::Util::trim           |     22133 |   45.1814 |               435.05% |              1065.97% | 1.1e-11 |      20 |
 | Text::Minify::XS::minify     |    207920 |    4.8095 |              4926.30% |                24.12% | 9.8e-12 |      22 |
 | String::Trim::More::trim     |    258000 |    3.87   |              6138.52% |                 0.00% | 1.7e-09 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table6#
 {dataset=>"len100ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |    166350 |    6.0113 |                 0.00% |              1854.25% | 4.6e-11 |      20 |
 | String::Util::trim           |    195810 |    5.107  |                17.71% |              1560.27% | 5.2e-12 |      24 |
 | String::Trim::More::trim     |   1052000 |    0.9507 |               532.32% |               209.06% | 1.1e-11 |      20 |
 | String::Trim::NonRegex::trim |   1100000 |    0.95   |               533.45% |               208.51% | 1.2e-09 |      20 |
 | Text::Minify::XS::minify     |   3251000 |    0.3076 |              1854.25% |                 0.00% | 1.1e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table7#
 {dataset=>"len100ws10"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |    166340 |   6.0119  |                 0.00% |              1658.63% | 1.1e-11 |      20 |
 | String::Util::trim           |    195831 |   5.10643 |                17.73% |              1393.76% |   0     |      20 |
 | String::Trim::NonRegex::trim |    309660 |   3.2293  |                86.16% |               844.67% |   1e-11 |      21 |
 | String::Trim::More::trim     |   1044000 |   0.9581  |               527.48% |               180.27% |   1e-11 |      20 |
 | Text::Minify::XS::minify     |   2930000 |   0.342   |              1658.63% |                 0.00% | 9.8e-11 |      23 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table8#
 {dataset=>"len100ws100"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::NonRegex::trim |     40200 |   24.9    |                 0.00% |              3898.58% | 6.2e-09 |      23 |
 | String::Trim::Regex::trim    |    163780 |    6.1057 |               307.52% |               881.20% | 1.1e-11 |      20 |
 | String::Util::trim           |    187000 |    5.34   |               365.92% |               758.21% | 4.9e-09 |      21 |
 | String::Trim::More::trim     |    860000 |    1.2    |              2032.68% |                87.49% | 1.2e-09 |      20 |
 | Text::Minify::XS::minify     |   1607000 |    0.6223 |              3898.58% |                 0.00% |   1e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table9#
 {dataset=>"len10ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Util::trim           |    849000 |    1180   |                 0.00% |               686.70% | 4.2e-10 |      20 |
 | String::Trim::Regex::trim    |    866730 |    1153.8 |                 2.10% |               670.53% | 1.1e-11 |      20 |
 | String::Trim::NonRegex::trim |   1050000 |     949   |                24.19% |               533.47% | 3.6e-10 |      27 |
 | String::Trim::More::trim     |   1380000 |     727   |                62.09% |               385.35% | 2.1e-10 |      20 |
 | Text::Minify::XS::minify     |   6678000 |     149.7 |               686.70% |                 0.00% |   1e-11 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringFunctions::Trim --module-startup >>):

 #table10#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::Util           |     14    |              7.7  |                 0.00% |               126.68% |   3e-05 |      20 |
 | String::Trim::Regex    |     12    |              5.7  |                18.48% |                91.32% | 1.8e-05 |      20 |
 | Text::Minify::XS       |      9.14 |              2.84 |                56.53% |                44.82% | 8.5e-06 |      20 |
 | String::Trim::More     |      9    |              2.7  |                58.35% |                43.16% | 1.5e-05 |      20 |
 | String::Trim::NonRegex |      9    |              2.7  |                59.71% |                41.94% | 1.5e-05 |      20 |
 | perl -e1 (baseline)    |      6.3  |              0    |               126.68% |                 0.00% | 2.7e-05 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
