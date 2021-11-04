package Bencher::Scenario::Array::Set::intersect;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark intersect operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_intersect(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'intersection',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'intersection',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);', # $res->as_string
        },
    ],
    datasets => [
        { name => '1_1'  , args => { set1=>[1], set2=>[1] } },

        { name => '10_1' , args => { set1=>[1..10], set2=>[1] } },
        { name => '10_5' , args => { set1=>[1..10], set2=>[1..5] } },
        { name => '10_10', args => { set1=>[1..10], set2=>[1..10] } },

        { name => '100_1'  , args => { set1=>[1..100], set2=>[1] } },
        { name => '100_10' , args => { set1=>[1..100], set2=>[1..10] } },
        { name => '100_100', args => { set1=>[1..100], set2=>[1..100] } },

        { name => '1000_1'   , args => { set1=>[1..1000], set2=>[1] } },
        { name => '1000_10'  , args => { set1=>[1..1000], set2=>[1..10] } },
        { name => '1000_100' , args => { set1=>[1..1000], set2=>[1..100] } },
        { name => '1000_1000', args => { set1=>[1..1000], set2=>[1..1000] } },
    ],
};

1;
# ABSTRACT: Benchmark intersect operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Set::intersect - Benchmark intersect operation

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Array::Set::intersect (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Set::intersect

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Set::intersect

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Set> 0.063

L<Set::Object> 1.41

L<Set::Scalar> 1.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Set::set_intersect (perl_code)

Function call template:

 Array::Set::set_intersect(<set1>, <set2>)



=item * Set::Object::intersection (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);



=item * Set::Scalar::intersection (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);



=back

=head1 BENCHMARK DATASETS

=over

=item * 1_1

=item * 10_1

=item * 10_5

=item * 10_10

=item * 100_1

=item * 100_10

=item * 100_100

=item * 1000_1

=item * 1000_10

=item * 1000_100

=item * 1000_1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with C<< bencher -m Array::Set::intersect --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |    260    |  3.85     |                 0.00% |              1498.11% | 3.6e-06 |      22 |
 | Set::Scalar::intersection | 0.02   |    280    |  3.5      |                 8.87% |              1367.92% | 5.5e-06 |      20 |
 | Set::Scalar::intersection | 0.063  |    290    |  3.4      |                12.59% |              1319.45% | 5.2e-06 |      20 |
 | Set::Scalar::intersection | 0.05   |    293    |  3.41     |                12.75% |              1317.44% | 2.7e-06 |      20 |
 | Set::Object::intersection | 0.02   |    860    |  1.2      |               230.51% |               383.53% | 1.5e-06 |      22 |
 | Set::Object::intersection | 0.05   |    860    |  1.2      |               231.50% |               382.09% |   4e-06 |      20 |
 | Set::Object::intersection | 0.063  |    869    |  1.15     |               234.49% |               377.77% | 6.4e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |   4050.15 |  0.246904 |              1459.07% |                 2.50% | 3.4e-11 |      20 |
 | Array::Set::set_intersect | 0.063  |   4200    |  0.24     |              1498.11% |                 0.00% | 8.5e-07 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                  Rate  Array::Set::set_intersect  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Array::Set::set_intersect      260/s                         --                        -9%                       -11%                       -11%                       -68%                       -68%                       -70%                       -93%                       -93% 
  Set::Scalar::intersection      280/s                        10%                         --                        -2%                        -2%                       -65%                       -65%                       -67%                       -92%                       -93% 
  Set::Scalar::intersection      293/s                        12%                         2%                         --                         0%                       -64%                       -64%                       -66%                       -92%                       -92% 
  Set::Scalar::intersection      290/s                        13%                         2%                         0%                         --                       -64%                       -64%                       -66%                       -92%                       -92% 
  Set::Object::intersection      860/s                       220%                       191%                       184%                       183%                         --                         0%                        -4%                       -79%                       -80% 
  Set::Object::intersection      860/s                       220%                       191%                       184%                       183%                         0%                         --                        -4%                       -79%                       -80% 
  Set::Object::intersection      869/s                       234%                       204%                       196%                       195%                         4%                         4%                         --                       -78%                       -79% 
  Array::Set::set_intersect  4050.15/s                      1459%                      1317%                      1281%                      1277%                       386%                       386%                       365%                         --                        -2% 
  Array::Set::set_intersect     4200/s                      1504%                      1358%                      1320%                      1316%                       400%                       400%                       379%                         2%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.063 participant=Set::Scalar::intersection

 #table2#
 {dataset=>"1000_10"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       258 |     3.88  |                 0.00% |              1470.26% | 2.2e-06 |      20 |
 | Set::Scalar::intersection | 0.02   |       280 |     3.6   |                 8.31% |              1349.80% | 4.4e-06 |      20 |
 | Set::Scalar::intersection | 0.05   |       287 |     3.48  |                11.29% |              1311.00% | 2.5e-06 |      20 |
 | Set::Scalar::intersection | 0.063  |       290 |     3.5   |                11.38% |              1309.84% | 4.2e-06 |      20 |
 | Set::Object::intersection | 0.02   |       830 |     1.2   |               223.37% |               385.60% | 2.7e-06 |      20 |
 | Set::Object::intersection | 0.05   |       844 |     1.19  |               227.11% |               380.05% | 9.1e-07 |      20 |
 | Set::Object::intersection | 0.063  |       850 |     1.2   |               229.38% |               376.73% | 1.8e-06 |      20 |
 | Array::Set::set_intersect | 0.05   |      2100 |     0.47  |               732.64% |                88.59% | 1.1e-06 |      20 |
 | Array::Set::set_intersect | 0.063  |      4050 |     0.247 |              1470.26% |                 0.00% | 2.1e-07 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Array::Set::set_intersect  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Array::Set::set_intersect   258/s                         --                        -7%                        -9%                       -10%                       -69%                       -69%                       -69%                       -87%                       -93% 
  Set::Scalar::intersection   280/s                         7%                         --                        -2%                        -3%                       -66%                       -66%                       -66%                       -86%                       -93% 
  Set::Scalar::intersection   290/s                        10%                         2%                         --                         0%                       -65%                       -65%                       -66%                       -86%                       -92% 
  Set::Scalar::intersection   287/s                        11%                         3%                         0%                         --                       -65%                       -65%                       -65%                       -86%                       -92% 
  Set::Object::intersection   830/s                       223%                       200%                       191%                       190%                         --                         0%                         0%                       -60%                       -79% 
  Set::Object::intersection   850/s                       223%                       200%                       191%                       190%                         0%                         --                         0%                       -60%                       -79% 
  Set::Object::intersection   844/s                       226%                       202%                       194%                       192%                         0%                         0%                         --                       -60%                       -79% 
  Array::Set::set_intersect  2100/s                       725%                       665%                       644%                       640%                       155%                       155%                       153%                         --                       -47% 
  Array::Set::set_intersect  4050/s                      1470%                      1357%                      1317%                      1308%                       385%                       385%                       381%                        90%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.05 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.05 participant=Set::Scalar::intersection

 #table3#
 {dataset=>"1000_100"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       230 |      4.3  |                 0.00% |              1349.86% | 4.9e-06 |      20 |
 | Set::Scalar::intersection | 0.02   |       250 |      4    |                 8.57% |              1235.38% | 9.9e-06 |      20 |
 | Set::Scalar::intersection | 0.05   |       261 |      3.83 |                12.46% |              1189.18% | 2.2e-06 |      20 |
 | Set::Scalar::intersection | 0.063  |       262 |      3.82 |                12.72% |              1186.23% |   3e-06 |      20 |
 | Set::Object::intersection | 0.02   |       800 |      1.2  |               246.47% |               318.47% | 1.8e-06 |      20 |
 | Set::Object::intersection | 0.063  |       813 |      1.23 |               250.50% |               313.66% | 6.9e-07 |      20 |
 | Set::Object::intersection | 0.05   |       820 |      1.2  |               254.18% |               309.36% |   2e-06 |      20 |
 | Array::Set::set_intersect | 0.05   |      3200 |      0.32 |              1267.13% |                 6.05% | 1.2e-06 |      20 |
 | Array::Set::set_intersect | 0.063  |      3400 |      0.3  |              1349.86% |                 0.00% | 6.9e-07 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Array::Set::set_intersect  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Array::Set::set_intersect   230/s                         --                        -6%                       -10%                       -11%                       -71%                       -72%                       -72%                       -92%                       -93% 
  Set::Scalar::intersection   250/s                         7%                         --                        -4%                        -4%                       -69%                       -70%                       -70%                       -92%                       -92% 
  Set::Scalar::intersection   261/s                        12%                         4%                         --                         0%                       -67%                       -68%                       -68%                       -91%                       -92% 
  Set::Scalar::intersection   262/s                        12%                         4%                         0%                         --                       -67%                       -68%                       -68%                       -91%                       -92% 
  Set::Object::intersection   813/s                       249%                       225%                       211%                       210%                         --                        -2%                        -2%                       -73%                       -75% 
  Set::Object::intersection   800/s                       258%                       233%                       219%                       218%                         2%                         --                         0%                       -73%                       -75% 
  Set::Object::intersection   820/s                       258%                       233%                       219%                       218%                         2%                         0%                         --                       -73%                       -75% 
  Array::Set::set_intersect  3200/s                      1243%                      1150%                      1096%                      1093%                       284%                       275%                       275%                         --                        -6% 
  Array::Set::set_intersect  3400/s                      1333%                      1233%                      1176%                      1173%                       310%                       300%                       300%                         6%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.05 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.063 participant=Set::Scalar::intersection

 #table4#
 {dataset=>"1000_1000"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       120 |     8.36  |                 0.00% |               870.62% | 7.8e-06 |      20 |
 | Set::Scalar::intersection | 0.02   |       179 |     5.59  |                49.49% |               549.26% |   5e-06 |      20 |
 | Set::Scalar::intersection | 0.05   |       181 |     5.51  |                51.62% |               540.15% | 4.5e-06 |      20 |
 | Set::Scalar::intersection | 0.063  |       183 |     5.45  |                53.28% |               533.21% | 4.7e-06 |      20 |
 | Set::Object::intersection | 0.063  |       660 |     1.5   |               448.66% |                76.91% | 2.5e-06 |      20 |
 | Set::Object::intersection | 0.05   |       657 |     1.52  |               448.87% |                76.84% | 1.5e-06 |      21 |
 | Set::Object::intersection | 0.02   |       660 |     1.5   |               449.01% |                76.79% | 1.8e-06 |      20 |
 | Array::Set::set_intersect | 0.05   |      1160 |     0.861 |               870.21% |                 0.04% | 6.9e-07 |      20 |
 | Array::Set::set_intersect | 0.063  |      1160 |     0.861 |               870.62% |                 0.00% | 4.3e-07 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Array::Set::set_intersect  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Array::Set::set_intersect   120/s                         --                       -33%                       -34%                       -34%                       -81%                       -82%                       -82%                       -89%                       -89% 
  Set::Scalar::intersection   179/s                        49%                         --                        -1%                        -2%                       -72%                       -73%                       -73%                       -84%                       -84% 
  Set::Scalar::intersection   181/s                        51%                         1%                         --                        -1%                       -72%                       -72%                       -72%                       -84%                       -84% 
  Set::Scalar::intersection   183/s                        53%                         2%                         1%                         --                       -72%                       -72%                       -72%                       -84%                       -84% 
  Set::Object::intersection   657/s                       450%                       267%                       262%                       258%                         --                        -1%                        -1%                       -43%                       -43% 
  Set::Object::intersection   660/s                       457%                       272%                       267%                       263%                         1%                         --                         0%                       -42%                       -42% 
  Set::Object::intersection   660/s                       457%                       272%                       267%                       263%                         1%                         0%                         --                       -42%                       -42% 
  Array::Set::set_intersect  1160/s                       870%                       549%                       539%                       532%                        76%                        74%                        74%                         --                         0% 
  Array::Set::set_intersect  1160/s                       870%                       549%                       539%                       532%                        76%                        74%                        74%                         0%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.02 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.063 participant=Set::Scalar::intersection

 #table5#
 {dataset=>"100_1"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.063  |       880 |    1100   |                 0.00% |              4595.62% | 3.1e-06 |      20 |
 | Set::Scalar::intersection | 0.05   |      1600 |     640   |                77.93% |              2539.08% | 1.8e-06 |      20 |
 | Set::Scalar::intersection | 0.02   |      1600 |     630   |                79.79% |              2511.75% | 1.6e-06 |      20 |
 | Array::Set::set_intersect | 0.02   |      2500 |     390   |               187.25% |              1534.71% | 1.5e-06 |      20 |
 | Set::Object::intersection | 0.02   |      8200 |     120   |               827.99% |               406.00% | 1.9e-07 |      24 |
 | Set::Object::intersection | 0.063  |      8300 |     120   |               840.07% |               399.50% | 2.6e-07 |      21 |
 | Set::Object::intersection | 0.05   |      8400 |     120   |               850.03% |               394.26% | 2.7e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |     40600 |      24.6 |              4491.10% |                 2.28% | 6.7e-09 |      20 |
 | Array::Set::set_intersect | 0.063  |     41500 |      24.1 |              4595.62% |                 0.00% | 6.7e-09 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection    880/s                         --                       -41%                       -42%                       -64%                       -89%                       -89%                       -89%                       -97%                       -97% 
  Set::Scalar::intersection   1600/s                        71%                         --                        -1%                       -39%                       -81%                       -81%                       -81%                       -96%                       -96% 
  Set::Scalar::intersection   1600/s                        74%                         1%                         --                       -38%                       -80%                       -80%                       -80%                       -96%                       -96% 
  Array::Set::set_intersect   2500/s                       182%                        64%                        61%                         --                       -69%                       -69%                       -69%                       -93%                       -93% 
  Set::Object::intersection   8200/s                       816%                       433%                       425%                       225%                         --                         0%                         0%                       -79%                       -79% 
  Set::Object::intersection   8300/s                       816%                       433%                       425%                       225%                         0%                         --                         0%                       -79%                       -79% 
  Set::Object::intersection   8400/s                       816%                       433%                       425%                       225%                         0%                         0%                         --                       -79%                       -79% 
  Array::Set::set_intersect  40600/s                      4371%                      2501%                      2460%                      1485%                       387%                       387%                       387%                         --                        -2% 
  Array::Set::set_intersect  41500/s                      4464%                      2555%                      2514%                      1518%                       397%                       397%                       397%                         2%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.05 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.02 participant=Set::Scalar::intersection

 #table6#
 {dataset=>"100_10"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.063  |      1000 |     900   |                 0.00% |              2864.49% | 1.6e-05 |      20 |
 | Set::Scalar::intersection | 0.05   |      1520 |     656   |                36.08% |              2078.51% | 2.7e-07 |      20 |
 | Set::Scalar::intersection | 0.02   |      1530 |     652   |                36.80% |              2066.97% | 6.4e-07 |      20 |
 | Array::Set::set_intersect | 0.02   |      2300 |     440   |               103.17% |              1359.15% | 2.2e-06 |      20 |
 | Set::Object::intersection | 0.05   |      7800 |     130   |               597.00% |               325.32% | 6.4e-07 |      20 |
 | Set::Object::intersection | 0.02   |      7890 |     127   |               603.97% |               321.11% | 5.3e-08 |      20 |
 | Set::Object::intersection | 0.063  |      8100 |     120   |               621.74% |               310.74% | 2.1e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |     32600 |      30.7 |              2808.08% |                 1.94% | 1.2e-08 |      26 |
 | Array::Set::set_intersect | 0.063  |     33200 |      30.1 |              2864.49% |                 0.00% | 1.3e-08 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection   1000/s                         --                       -27%                       -27%                       -51%                       -85%                       -85%                       -86%                       -96%                       -96% 
  Set::Scalar::intersection   1520/s                        37%                         --                         0%                       -32%                       -80%                       -80%                       -81%                       -95%                       -95% 
  Set::Scalar::intersection   1530/s                        38%                         0%                         --                       -32%                       -80%                       -80%                       -81%                       -95%                       -95% 
  Array::Set::set_intersect   2300/s                       104%                        49%                        48%                         --                       -70%                       -71%                       -72%                       -93%                       -93% 
  Set::Object::intersection   7800/s                       592%                       404%                       401%                       238%                         --                        -2%                        -7%                       -76%                       -76% 
  Set::Object::intersection   7890/s                       608%                       416%                       413%                       246%                         2%                         --                        -5%                       -75%                       -76% 
  Set::Object::intersection   8100/s                       650%                       446%                       443%                       266%                         8%                         5%                         --                       -74%                       -74% 
  Array::Set::set_intersect  32600/s                      2831%                      2036%                      2023%                      1333%                       323%                       313%                       290%                         --                        -1% 
  Array::Set::set_intersect  33200/s                      2890%                      2079%                      2066%                      1361%                       331%                       321%                       298%                         1%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.02 participant=Set::Scalar::intersection

 #table7#
 {dataset=>"100_100"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.02   |      1100 |       911 |                 0.00% |              1017.09% | 8.8e-07 |      21 |
 | Set::Scalar::intersection | 0.063  |      1100 |       910 |                 0.01% |              1016.94% |   1e-06 |      22 |
 | Set::Scalar::intersection | 0.05   |      1100 |       906 |                 0.52% |              1011.26% | 4.3e-07 |      20 |
 | Array::Set::set_intersect | 0.02   |      1200 |       860 |                 6.53% |               948.66% | 3.6e-06 |      20 |
 | Set::Object::intersection | 0.05   |      6400 |       160 |               479.59% |                92.74% | 2.7e-07 |      20 |
 | Set::Object::intersection | 0.02   |      6400 |       160 |               481.28% |                92.18% | 2.7e-07 |      20 |
 | Set::Object::intersection | 0.063  |      6700 |       150 |               510.33% |                83.03% | 5.8e-07 |      24 |
 | Array::Set::set_intersect | 0.05   |     12000 |        82 |              1006.94% |                 0.92% | 1.1e-07 |      20 |
 | Array::Set::set_intersect | 0.063  |     12000 |        82 |              1017.09% |                 0.00% | 1.1e-07 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection   1100/s                         --                         0%                         0%                        -5%                       -82%                       -82%                       -83%                       -90%                       -90% 
  Set::Scalar::intersection   1100/s                         0%                         --                         0%                        -5%                       -82%                       -82%                       -83%                       -90%                       -90% 
  Set::Scalar::intersection   1100/s                         0%                         0%                         --                        -5%                       -82%                       -82%                       -83%                       -90%                       -90% 
  Array::Set::set_intersect   1200/s                         5%                         5%                         5%                         --                       -81%                       -81%                       -82%                       -90%                       -90% 
  Set::Object::intersection   6400/s                       469%                       468%                       466%                       437%                         --                         0%                        -6%                       -48%                       -48% 
  Set::Object::intersection   6400/s                       469%                       468%                       466%                       437%                         0%                         --                        -6%                       -48%                       -48% 
  Set::Object::intersection   6700/s                       507%                       506%                       504%                       473%                         6%                         6%                         --                       -45%                       -45% 
  Array::Set::set_intersect  12000/s                      1010%                      1009%                      1004%                       948%                        95%                        95%                        82%                         --                         0% 
  Array::Set::set_intersect  12000/s                      1010%                      1009%                      1004%                       948%                        95%                        95%                        82%                         0%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.05 participant=Set::Scalar::intersection

 #table8#
 {dataset=>"10_1"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.05   |      7500 |   130     |                 0.00% |              2606.77% | 6.2e-07 |      21 |
 | Set::Scalar::intersection | 0.02   |      7700 |   130     |                 2.45% |              2542.15% |   2e-07 |      22 |
 | Set::Scalar::intersection | 0.063  |      7700 |   130     |                 2.48% |              2541.18% | 2.1e-07 |      20 |
 | Array::Set::set_intersect | 0.02   |     20300 |    49.3   |               170.19% |               901.79% | 3.9e-08 |      21 |
 | Set::Object::intersection | 0.02   |     62900 |    15.9   |               738.74% |               222.72% | 6.7e-09 |      20 |
 | Set::Object::intersection | 0.05   |     63700 |    15.7   |               749.37% |               218.68% | 6.7e-09 |      20 |
 | Set::Object::intersection | 0.063  |     63800 |    15.7   |               749.79% |               218.52% | 6.7e-09 |      20 |
 | Array::Set::set_intersect | 0.05   |    191000 |     5.22  |              2451.53% |                 6.08% | 1.5e-09 |      26 |
 | Array::Set::set_intersect | 0.063  |    203100 |     4.923 |              2606.77% |                 0.00% | 1.7e-10 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                 Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection    7500/s                         --                         0%                         0%                       -62%                       -87%                       -87%                       -87%                       -95%                       -96% 
  Set::Scalar::intersection    7700/s                         0%                         --                         0%                       -62%                       -87%                       -87%                       -87%                       -95%                       -96% 
  Set::Scalar::intersection    7700/s                         0%                         0%                         --                       -62%                       -87%                       -87%                       -87%                       -95%                       -96% 
  Array::Set::set_intersect   20300/s                       163%                       163%                       163%                         --                       -67%                       -68%                       -68%                       -89%                       -90% 
  Set::Object::intersection   62900/s                       717%                       717%                       717%                       210%                         --                        -1%                        -1%                       -67%                       -69% 
  Set::Object::intersection   63700/s                       728%                       728%                       728%                       214%                         1%                         --                         0%                       -66%                       -68% 
  Set::Object::intersection   63800/s                       728%                       728%                       728%                       214%                         1%                         0%                         --                       -66%                       -68% 
  Array::Set::set_intersect  191000/s                      2390%                      2390%                      2390%                       844%                       204%                       200%                       200%                         --                        -5% 
  Array::Set::set_intersect  203100/s                      2540%                      2540%                      2540%                       901%                       222%                       218%                       218%                         6%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.063 participant=Set::Scalar::intersection

 #table9#
 {dataset=>"10_10"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.02   |      6300 |     160   |                 0.00% |              1383.60% | 2.7e-07 |      20 |
 | Set::Scalar::intersection | 0.063  |      6400 |     160   |                 1.09% |              1367.63% | 1.6e-07 |      20 |
 | Set::Scalar::intersection | 0.05   |      6600 |     150   |                 4.66% |              1317.61% | 6.5e-07 |      23 |
 | Array::Set::set_intersect | 0.02   |     11000 |      88   |                80.26% |               723.01% | 1.1e-07 |      20 |
 | Set::Object::intersection | 0.05   |     53000 |      19   |               747.59% |                75.04% |   6e-08 |      20 |
 | Set::Object::intersection | 0.02   |     60000 |      20   |               784.02% |                67.82% | 2.6e-07 |      23 |
 | Set::Object::intersection | 0.063  |     56000 |      18   |               797.21% |                65.36% | 1.6e-07 |      21 |
 | Array::Set::set_intersect | 0.05   |     91400 |      10.9 |              1353.78% |                 2.05% |   1e-08 |      20 |
 | Array::Set::set_intersect | 0.063  |     93200 |      10.7 |              1383.60% |                 0.00% | 3.3e-09 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection   6300/s                         --                         0%                        -6%                       -44%                       -87%                       -88%                       -88%                       -93%                       -93% 
  Set::Scalar::intersection   6400/s                         0%                         --                        -6%                       -44%                       -87%                       -88%                       -88%                       -93%                       -93% 
  Set::Scalar::intersection   6600/s                         6%                         6%                         --                       -41%                       -86%                       -87%                       -88%                       -92%                       -92% 
  Array::Set::set_intersect  11000/s                        81%                        81%                        70%                         --                       -77%                       -78%                       -79%                       -87%                       -87% 
  Set::Object::intersection  60000/s                       700%                       700%                       650%                       340%                         --                        -5%                        -9%                       -45%                       -46% 
  Set::Object::intersection  53000/s                       742%                       742%                       689%                       363%                         5%                         --                        -5%                       -42%                       -43% 
  Set::Object::intersection  56000/s                       788%                       788%                       733%                       388%                        11%                         5%                         --                       -39%                       -40% 
  Array::Set::set_intersect  91400/s                      1367%                      1367%                      1276%                       707%                        83%                        74%                        65%                         --                        -1% 
  Array::Set::set_intersect  93200/s                      1395%                      1395%                      1301%                       722%                        86%                        77%                        68%                         1%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.05 participant=Set::Scalar::intersection

 #table10#
 {dataset=>"10_5"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.02   |      7000 |    100    |                 0.00% |              1682.90% | 1.7e-06 |      21 |
 | Set::Scalar::intersection | 0.063  |      7100 |    140    |                 0.57% |              1672.81% |   6e-07 |      23 |
 | Set::Scalar::intersection | 0.05   |      7100 |    140    |                 1.25% |              1660.91% | 4.2e-07 |      21 |
 | Array::Set::set_intersect | 0.02   |     15200 |     65.9  |               115.83% |               726.06% | 2.7e-08 |      20 |
 | Set::Object::intersection | 0.05   |     59000 |     17    |               741.53% |               111.86% | 5.3e-08 |      20 |
 | Set::Object::intersection | 0.02   |     61000 |     17    |               761.00% |               107.07% | 2.7e-08 |      20 |
 | Set::Object::intersection | 0.063  |     61000 |     16.4  |               768.14% |               105.37% | 6.7e-09 |      20 |
 | Array::Set::set_intersect | 0.063  |    120000 |      8.1  |              1658.68% |                 1.38% | 1.3e-08 |      20 |
 | Array::Set::set_intersect | 0.05   |    125000 |      7.98 |              1682.90% |                 0.00% | 3.3e-09 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                 Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection    7100/s                         --                         0%                       -28%                       -52%                       -87%                       -87%                       -88%                       -94%                       -94% 
  Set::Scalar::intersection    7100/s                         0%                         --                       -28%                       -52%                       -87%                       -87%                       -88%                       -94%                       -94% 
  Set::Scalar::intersection    7000/s                        39%                        39%                         --                       -34%                       -83%                       -83%                       -83%                       -91%                       -92% 
  Array::Set::set_intersect   15200/s                       112%                       112%                        51%                         --                       -74%                       -74%                       -75%                       -87%                       -87% 
  Set::Object::intersection   59000/s                       723%                       723%                       488%                       287%                         --                         0%                        -3%                       -52%                       -53% 
  Set::Object::intersection   61000/s                       723%                       723%                       488%                       287%                         0%                         --                        -3%                       -52%                       -53% 
  Set::Object::intersection   61000/s                       753%                       753%                       509%                       301%                         3%                         3%                         --                       -50%                       -51% 
  Array::Set::set_intersect  120000/s                      1628%                      1628%                      1134%                       713%                       109%                       109%                       102%                         --                        -1% 
  Array::Set::set_intersect  125000/s                      1654%                      1654%                      1153%                       725%                       113%                       113%                       105%                         1%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.05 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.063 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.02 participant=Set::Scalar::intersection

 #table11#
 {dataset=>"1_1"}
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::intersection | 0.063  |   12000   |   82      |                 0.00% |              2639.67% | 1.3e-07 |      22 |
 | Set::Scalar::intersection | 0.05   |   12000   |   82      |                 0.55% |              2624.82% | 2.1e-07 |      20 |
 | Set::Scalar::intersection | 0.02   |   12000   |   82      |                 0.91% |              2614.91% | 1.1e-07 |      20 |
 | Array::Set::set_intersect | 0.02   |   68832.7 |   14.528  |               466.84% |               383.33% | 1.2e-11 |      20 |
 | Set::Object::intersection | 0.02   |  157820   |    6.3364 |              1199.63% |               110.80% | 4.5e-11 |      20 |
 | Set::Object::intersection | 0.063  |  160000   |    6.2    |              1228.38% |               106.24% | 6.7e-09 |      20 |
 | Set::Object::intersection | 0.05   |  160000   |    6.1    |              1253.04% |               102.48% | 1.5e-08 |      20 |
 | Array::Set::set_intersect | 0.05   |  280000   |    3.5    |              2235.66% |                17.30% | 6.7e-09 |      20 |
 | Array::Set::set_intersect | 0.063  |  330000   |    3      |              2639.67% |                 0.00% | 3.3e-09 |      20 |
 +---------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                  Rate  Set::Scalar::intersection  Set::Scalar::intersection  Set::Scalar::intersection  Array::Set::set_intersect  Set::Object::intersection  Set::Object::intersection  Set::Object::intersection  Array::Set::set_intersect  Array::Set::set_intersect 
  Set::Scalar::intersection    12000/s                         --                         0%                         0%                       -82%                       -92%                       -92%                       -92%                       -95%                       -96% 
  Set::Scalar::intersection    12000/s                         0%                         --                         0%                       -82%                       -92%                       -92%                       -92%                       -95%                       -96% 
  Set::Scalar::intersection    12000/s                         0%                         0%                         --                       -82%                       -92%                       -92%                       -92%                       -95%                       -96% 
  Array::Set::set_intersect  68832.7/s                       464%                       464%                       464%                         --                       -56%                       -57%                       -58%                       -75%                       -79% 
  Set::Object::intersection   157820/s                      1194%                      1194%                      1194%                       129%                         --                        -2%                        -3%                       -44%                       -52% 
  Set::Object::intersection   160000/s                      1222%                      1222%                      1222%                       134%                         2%                         --                        -1%                       -43%                       -51% 
  Set::Object::intersection   160000/s                      1244%                      1244%                      1244%                       138%                         3%                         1%                         --                       -42%                       -50% 
  Array::Set::set_intersect   280000/s                      2242%                      2242%                      2242%                       315%                        81%                        77%                        74%                         --                       -14% 
  Array::Set::set_intersect   330000/s                      2633%                      2633%                      2633%                       384%                       111%                       106%                       103%                        16%                         -- 
 
 Legends:
   Array::Set::set_intersect: modver=0.063 participant=Array::Set::set_intersect
   Set::Object::intersection: modver=0.05 participant=Set::Object::intersection
   Set::Scalar::intersection: modver=0.02 participant=Set::Scalar::intersection


Benchmark module startup overhead (C<< bencher -m Array::Set::intersect --module-startup >>):

 #table12#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Set::Object         |      25   |              15.4 |                 0.00% |               165.45% | 3.2e-05 |      20 |
 | Set::Scalar         |      22   |              12.4 |                13.18% |               134.54% | 3.4e-05 |      20 |
 | Array::Set          |      14   |               4.4 |                80.43% |                47.12% | 1.7e-05 |      20 |
 | perl -e1 (baseline) |       9.6 |               0   |               165.45% |                 0.00% |   5e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:O   S:S   A:S  perl -e1 (baseline) 
  S:O                   40.0/s    --  -12%  -43%                 -61% 
  S:S                   45.5/s   13%    --  -36%                 -56% 
  A:S                   71.4/s   78%   57%    --                 -31% 
  perl -e1 (baseline)  104.2/s  160%  129%   45%                   -- 
 
 Legends:
   A:S: mod_overhead_time=4.4 participant=Array::Set
   S:O: mod_overhead_time=15.4 participant=Set::Object
   S:S: mod_overhead_time=12.4 participant=Set::Scalar
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Array-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Array-Set>.

=head1 SEE ALSO

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

This software is copyright (c) 2021, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Array-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
