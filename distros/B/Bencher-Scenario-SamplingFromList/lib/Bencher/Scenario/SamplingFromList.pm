# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Bencher::Scenario::SamplingFromList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-18'; # DATE
our $DIST = 'Bencher-Scenario-SamplingFromList'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark random sampling from a list',
    participants => [
        {
            fcall_template => 'List::MoreUtils::samples(<num_samples>, @{<data>})',
            result_is_list => 1,
        },
        {
            module => 'List::Util',
            function => 'shuffle',
            code_template => 'my @shuffled = List::Util::shuffle(@{<data>}); @shuffled[0..<num_samples>-1]',
            result_is_list => 1,
        },
        {
            fcall_template => 'List::Util::sample(<num_samples>, @{<data>})',
            result_is_list => 1,
        },
        {
            fcall_template => 'Array::Pick::Scan::random_item(<data>, <num_samples>)',
            result_is_list => 1,
        },
    ],

    datasets => [
        {
            name=>'int100-1',
            args=>{data=>[1..100], num_samples=>1},
        },
        {
            name=>'int100-10',
            args=>{data=>[1..100], num_samples=>10},
        },
        {
            name=>'int100-100',
            args=>{data=>[1..100], num_samples=>100},
        },

        {
            name=>'int1000-1',
            args=>{data=>[1..1000], num_samples=>1},
        },
        {
            name=>'int1000-10',
            args=>{data=>[1..1000], num_samples=>10},
        },
        {
            name=>'int1000-100',
            args=>{data=>[1..1000], num_samples=>100},
        },
        {
            name=>'int1000-1000',
            args=>{data=>[1..1000], num_samples=>1000},
        },
    ],
};

1;
# ABSTRACT: Benchmark random sampling from a list

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SamplingFromList - Benchmark random sampling from a list

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::SamplingFromList (from Perl distribution Bencher-Scenario-SamplingFromList), released on 2021-09-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SamplingFromList

To run module startup overhead benchmark:

 % bencher --module-startup -m SamplingFromList

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::MoreUtils> 0.430

L<List::Util> 1.59

L<Array::Pick::Scan> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::MoreUtils::samples (perl_code)

Function call template:

 List::MoreUtils::samples(<num_samples>, @{<data>})



=item * List::Util::shuffle (perl_code)

Code template:

 my @shuffled = List::Util::shuffle(@{<data>}); @shuffled[0..<num_samples>-1]



=item * List::Util::sample (perl_code)

Function call template:

 List::Util::sample(<num_samples>, @{<data>})



=item * Array::Pick::Scan::random_item (perl_code)

Function call template:

 Array::Pick::Scan::random_item(<data>, <num_samples>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int100-1

=item * int100-10

=item * int100-100

=item * int1000-1

=item * int1000-10

=item * int1000-100

=item * int1000-1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m SamplingFromList >>):

 #table1#
 {dataset=>"int100-1"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | List::Util::shuffle            |    204137 |   4.89867 |                 0.00% |               152.55% |   0     |      26 |
 | Array::Pick::Scan::random_item |    460000 |   2.2     |               125.89% |                11.80% | 3.3e-09 |      20 |
 | List::Util::sample             |    480938 |   2.07927 |               135.60% |                 7.19% |   0     |      22 |
 | List::MoreUtils::samples       |    516000 |   1.94    |               152.55% |                 0.00% | 8.3e-10 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  List::Util::shuffle  Array::Pick::Scan::random_item  List::Util::sample  List::MoreUtils::samples 
  List::Util::shuffle             204137/s                   --                            -55%                -57%                      -60% 
  Array::Pick::Scan::random_item  460000/s                 122%                              --                 -5%                      -11% 
  List::Util::sample              480938/s                 135%                              5%                  --                       -6% 
  List::MoreUtils::samples        516000/s                 152%                             13%                  7%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table2#
 {dataset=>"int100-10"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Pick::Scan::random_item |     34000 |  29       |                 0.00% |              1338.63% | 9.3e-08 |      20 |
 | List::Util::shuffle            |    201940 |   4.95196 |               488.90% |               144.29% |   0     |      20 |
 | List::Util::sample             |    462000 |   2.16    |              1247.73% |                 6.74% | 8.3e-10 |      20 |
 | List::MoreUtils::samples       |    493000 |   2.03    |              1338.63% |                 0.00% | 8.3e-10 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  Array::Pick::Scan::random_item  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples 
  Array::Pick::Scan::random_item   34000/s                              --                 -82%                -92%                      -93% 
  List::Util::shuffle             201940/s                            485%                   --                -56%                      -59% 
  List::Util::sample              462000/s                           1242%                 129%                  --                       -6% 
  List::MoreUtils::samples        493000/s                           1328%                 143%                  6%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table3#
 {dataset=>"int100-100"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Pick::Scan::random_item |     40200 |  24.8     |                 0.00% |               806.40% | 6.7e-09 |      20 |
 | List::Util::shuffle            |    182000 |   5.49    |               352.52% |               100.30% | 1.7e-09 |      20 |
 | List::Util::sample             |    321293 |   3.11242 |               698.40% |                13.53% |   0     |      20 |
 | List::MoreUtils::samples       |    365000 |   2.74    |               806.40% |                 0.00% | 8.3e-10 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  Array::Pick::Scan::random_item  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples 
  Array::Pick::Scan::random_item   40200/s                              --                 -77%                -87%                      -88% 
  List::Util::shuffle             182000/s                            351%                   --                -43%                      -50% 
  List::Util::sample              321293/s                            696%                  76%                  --                      -11% 
  List::MoreUtils::samples        365000/s                            805%                 100%                 13%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table4#
 {dataset=>"int1000-1"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | List::Util::shuffle            |     22000 |      45   |                 0.00% |               163.91% | 5.3e-08 |      20 |
 | List::Util::sample             |     54600 |      18.3 |               146.43% |                 7.09% | 6.7e-09 |      20 |
 | List::MoreUtils::samples       |     55000 |      18   |               149.70% |                 5.69% | 2.7e-08 |      20 |
 | Array::Pick::Scan::random_item |     58500 |      17.1 |               163.91% |                 0.00% | 6.7e-09 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                     Rate  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples  Array::Pick::Scan::random_item 
  List::Util::shuffle             22000/s                   --                -59%                      -60%                            -62% 
  List::Util::sample              54600/s                 145%                  --                       -1%                             -6% 
  List::MoreUtils::samples        55000/s                 150%                  1%                        --                             -4% 
  Array::Pick::Scan::random_item  58500/s                 163%                  7%                        5%                              -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table5#
 {dataset=>"int1000-10"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Pick::Scan::random_item |      4050 |     247   |                 0.00% |              1255.45% | 2.1e-07 |      21 |
 | List::Util::shuffle            |     22000 |      45   |               446.46% |               148.04% | 5.3e-08 |      20 |
 | List::Util::sample             |     54400 |      18.4 |              1244.32% |                 0.83% | 5.7e-09 |      27 |
 | List::MoreUtils::samples       |     55000 |      18   |              1255.45% |                 0.00% | 2.7e-08 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                     Rate  Array::Pick::Scan::random_item  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples 
  Array::Pick::Scan::random_item   4050/s                              --                 -81%                -92%                      -92% 
  List::Util::shuffle             22000/s                            448%                   --                -59%                      -60% 
  List::Util::sample              54400/s                           1242%                 144%                  --                       -2% 
  List::MoreUtils::samples        55000/s                           1272%                 150%                  2%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table6#
 {dataset=>"int1000-100"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Pick::Scan::random_item |    3540   |  282      |                 0.00% |              1378.53% | 2.7e-07 |      20 |
 | List::Util::shuffle            |   21800   |   45.9    |               515.80% |               140.10% |   4e-08 |      20 |
 | List::Util::sample             |   51645.8 |   19.3626 |              1358.70% |                 1.36% |   0     |      24 |
 | List::MoreUtils::samples       |   52300   |   19.1    |              1378.53% |                 0.00% | 5.8e-09 |      26 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                       Rate  Array::Pick::Scan::random_item  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples 
  Array::Pick::Scan::random_item     3540/s                              --                 -83%                -93%                      -93% 
  List::Util::shuffle               21800/s                            514%                   --                -57%                      -58% 
  List::Util::sample              51645.8/s                           1356%                 137%                  --                       -1% 
  List::MoreUtils::samples          52300/s                           1376%                 140%                  1%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle

 #table7#
 {dataset=>"int1000-1000"}
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                    | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Pick::Scan::random_item |      2580 |       388 |                 0.00% |              1329.11% | 2.7e-07 |      20 |
 | List::Util::shuffle            |     20000 |        51 |               665.16% |                86.77% | 6.5e-08 |      21 |
 | List::Util::sample             |     34000 |        29 |              1215.81% |                 8.61% | 5.3e-08 |      20 |
 | List::MoreUtils::samples       |     37000 |        27 |              1329.11% |                 0.00% | 5.3e-08 |      20 |
 +--------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                     Rate  Array::Pick::Scan::random_item  List::Util::shuffle  List::Util::sample  List::MoreUtils::samples 
  Array::Pick::Scan::random_item   2580/s                              --                 -86%                -92%                      -93% 
  List::Util::shuffle             20000/s                            660%                   --                -43%                      -47% 
  List::Util::sample              34000/s                           1237%                  75%                  --                       -6% 
  List::MoreUtils::samples        37000/s                           1337%                  88%                  7%                        -- 
 
 Legends:
   Array::Pick::Scan::random_item: participant=Array::Pick::Scan::random_item
   List::MoreUtils::samples: participant=List::MoreUtils::samples
   List::Util::sample: participant=List::Util::sample
   List::Util::shuffle: participant=List::Util::shuffle


Benchmark module startup overhead (C<< bencher -m SamplingFromList --module-startup >>):

 #table8#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | List::MoreUtils     |     15.7  |             10.1  |                 0.00% |               182.39% | 1.5e-05 |      20 |
 | List::Util          |      8.83 |              3.23 |                78.34% |                58.34% | 7.6e-06 |      20 |
 | Array::Pick::Scan   |      8.3  |              2.7  |                89.11% |                49.33% | 8.7e-06 |      20 |
 | perl -e1 (baseline) |      5.6  |              0    |               182.39% |                 0.00% | 1.2e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   L:M   L:U  AP:S  perl -e1 (baseline) 
  L:M                   63.7/s    --  -43%  -47%                 -64% 
  L:U                  113.3/s   77%    --   -6%                 -36% 
  AP:S                 120.5/s   89%    6%    --                 -32% 
  perl -e1 (baseline)  178.6/s  180%   57%   48%                   -- 
 
 Legends:
   AP:S: mod_overhead_time=2.7 participant=Array::Pick::Scan
   L:M: mod_overhead_time=10.1 participant=List::MoreUtils
   L:U: mod_overhead_time=3.23 participant=List::Util
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SamplingFromList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SamplingFromList>.

=head1 SEE ALSO

L<Bencher::Scenario::RandomLineModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SamplingFromList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
