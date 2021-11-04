package Bencher::Scenario::Array::Set::diff;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark diff operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_diff(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'difference',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'difference',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);', # $res->as_string
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
# ABSTRACT: Benchmark diff operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Set::diff - Benchmark diff operation

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Array::Set::diff (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Set::diff

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Set::diff

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

=item * Array::Set::set_diff (perl_code)

Function call template:

 Array::Set::set_diff(<set1>, <set2>)



=item * Set::Object::difference (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);



=item * Set::Scalar::difference (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);



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

Benchmark with C<< bencher -m Array::Set::diff --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |       275 |     3.64  |                 0.00% |               739.63% |   2e-06 |      20 |
 | Set::Scalar::difference | 0.05   |       290 |     3.5   |                 3.71% |               709.61% | 1.4e-05 |      20 |
 | Set::Scalar::difference | 0.02   |       288 |     3.47  |                 4.68% |               702.09% | 2.7e-06 |      20 |
 | Set::Scalar::difference | 0.063  |       297 |     3.36  |                 8.06% |               677.00% | 1.5e-06 |      20 |
 | Set::Object::difference | 0.02   |       990 |     1     |               259.11% |               133.81% | 3.4e-06 |      20 |
 | Set::Object::difference | 0.05   |      1000 |     0.97  |               273.85% |               124.59% | 1.3e-06 |      20 |
 | Set::Object::difference | 0.063  |      1000 |     0.96  |               280.31% |               120.78% | 1.3e-06 |      20 |
 | Array::Set::set_diff    | 0.063  |      2220 |     0.451 |               705.27% |                 4.27% | 2.7e-07 |      20 |
 | Array::Set::set_diff    | 0.05   |      2300 |     0.43  |               739.63% |                 0.00% | 8.8e-07 |      24 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff      275/s                    --                      -3%                      -4%                      -7%                     -72%                     -73%                     -73%                  -87%                  -88% 
  Set::Scalar::difference   290/s                    4%                       --                       0%                      -4%                     -71%                     -72%                     -72%                  -87%                  -87% 
  Set::Scalar::difference   288/s                    4%                       0%                       --                      -3%                     -71%                     -72%                     -72%                  -87%                  -87% 
  Set::Scalar::difference   297/s                    8%                       4%                       3%                       --                     -70%                     -71%                     -71%                  -86%                  -87% 
  Set::Object::difference   990/s                  264%                     250%                     247%                     236%                       --                      -3%                      -4%                  -54%                  -57% 
  Set::Object::difference  1000/s                  275%                     260%                     257%                     246%                       3%                       --                      -1%                  -53%                  -55% 
  Set::Object::difference  1000/s                  279%                     264%                     261%                     250%                       4%                       1%                       --                  -53%                  -55% 
  Array::Set::set_diff     2220/s                  707%                     676%                     669%                     645%                     121%                     115%                     112%                    --                   -4% 
  Array::Set::set_diff     2300/s                  746%                     713%                     706%                     681%                     132%                     125%                     123%                    4%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table2#
 {dataset=>"1000_10"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |       198 |     5.05  |                 0.00% |              1057.08% | 4.2e-06 |      20 |
 | Set::Scalar::difference | 0.05   |       280 |     3.5   |                43.03% |               708.95% |   7e-06 |      21 |
 | Set::Scalar::difference | 0.02   |       280 |     3.5   |                43.53% |               706.14% | 3.7e-06 |      21 |
 | Set::Scalar::difference | 0.063  |       290 |     3.44  |                46.58% |               689.38% | 1.6e-06 |      20 |
 | Set::Object::difference | 0.02   |       990 |     1     |               399.93% |               131.45% | 2.7e-06 |      23 |
 | Set::Object::difference | 0.05   |      1000 |     1     |               402.44% |               130.29% | 1.6e-06 |      20 |
 | Set::Object::difference | 0.063  |      1020 |     0.981 |               414.34% |               124.96% | 6.4e-07 |      20 |
 | Array::Set::set_diff    | 0.063  |      2200 |     0.46  |              1003.32% |                 4.87% | 1.3e-06 |      22 |
 | Array::Set::set_diff    | 0.05   |      2300 |     0.44  |              1057.08% |                 0.00% | 1.9e-06 |      21 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff      198/s                    --                     -30%                     -30%                     -31%                     -80%                     -80%                     -80%                  -90%                  -91% 
  Set::Scalar::difference   280/s                   44%                       --                       0%                      -1%                     -71%                     -71%                     -71%                  -86%                  -87% 
  Set::Scalar::difference   280/s                   44%                       0%                       --                      -1%                     -71%                     -71%                     -71%                  -86%                  -87% 
  Set::Scalar::difference   290/s                   46%                       1%                       1%                       --                     -70%                     -70%                     -71%                  -86%                  -87% 
  Set::Object::difference   990/s                  405%                     250%                     250%                     244%                       --                       0%                      -1%                  -54%                  -56% 
  Set::Object::difference  1000/s                  405%                     250%                     250%                     244%                       0%                       --                      -1%                  -54%                  -56% 
  Set::Object::difference  1020/s                  414%                     256%                     256%                     250%                       1%                       1%                       --                  -53%                  -55% 
  Array::Set::set_diff     2200/s                  997%                     660%                     660%                     647%                     117%                     117%                     113%                    --                   -4% 
  Array::Set::set_diff     2300/s                 1047%                     695%                     695%                     681%                     127%                     127%                     122%                    4%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table3#
 {dataset=>"1000_100"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |      54.7 |    18.3   |                 0.00% |              3924.02% |   1e-05 |      20 |
 | Set::Scalar::difference | 0.02   |     250   |     4     |               361.37% |               772.19% | 5.2e-06 |      20 |
 | Set::Scalar::difference | 0.05   |     256   |     3.9   |               368.48% |               758.95% | 1.9e-06 |      21 |
 | Set::Scalar::difference | 0.063  |     259   |     3.86  |               373.36% |               750.09% | 1.8e-06 |      20 |
 | Set::Object::difference | 0.02   |     950   |     1     |              1642.72% |               130.90% | 1.8e-06 |      20 |
 | Set::Object::difference | 0.05   |     960   |     1     |              1653.93% |               129.43% | 1.7e-06 |      21 |
 | Set::Object::difference | 0.063  |     980   |     1     |              1698.63% |               123.73% | 1.3e-06 |      22 |
 | Array::Set::set_diff    | 0.063  |    2070   |     0.483 |              3683.86% |                 6.35% | 2.7e-07 |      20 |
 | Array::Set::set_diff    | 0.05   |    2200   |     0.454 |              3924.02% |                 0.00% | 2.1e-07 |      20 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff     54.7/s                    --                     -78%                     -78%                     -78%                     -94%                     -94%                     -94%                  -97%                  -97% 
  Set::Scalar::difference   250/s                  357%                       --                      -2%                      -3%                     -75%                     -75%                     -75%                  -87%                  -88% 
  Set::Scalar::difference   256/s                  369%                       2%                       --                      -1%                     -74%                     -74%                     -74%                  -87%                  -88% 
  Set::Scalar::difference   259/s                  374%                       3%                       1%                       --                     -74%                     -74%                     -74%                  -87%                  -88% 
  Set::Object::difference   950/s                 1730%                     300%                     290%                     286%                       --                       0%                       0%                  -51%                  -54% 
  Set::Object::difference   960/s                 1730%                     300%                     290%                     286%                       0%                       --                       0%                  -51%                  -54% 
  Set::Object::difference   980/s                 1730%                     300%                     290%                     286%                       0%                       0%                       --                  -51%                  -54% 
  Array::Set::set_diff     2070/s                 3688%                     728%                     707%                     699%                     107%                     107%                     107%                    --                   -6% 
  Array::Set::set_diff     2200/s                 3930%                     781%                     759%                     750%                     120%                     120%                     120%                    6%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table4#
 {dataset=>"1000_1000"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |        13 |    78     |                 0.00% |             12610.06% | 9.8e-05 |      22 |
 | Set::Scalar::difference | 0.05   |       182 |     5.49  |              1328.97% |               789.45% | 2.2e-06 |      20 |
 | Set::Scalar::difference | 0.02   |       183 |     5.48  |              1332.01% |               787.57% | 2.7e-06 |      20 |
 | Set::Scalar::difference | 0.063  |       185 |     5.41  |              1351.35% |               775.74% | 1.8e-06 |      20 |
 | Set::Object::difference | 0.05   |       832 |     1.2   |              6423.89% |                94.82% | 8.5e-07 |      20 |
 | Set::Object::difference | 0.02   |       830 |     1.2   |              6440.43% |                94.33% | 1.3e-06 |      20 |
 | Set::Object::difference | 0.063  |       850 |     1.2   |              6568.21% |                90.61% | 1.3e-06 |      20 |
 | Array::Set::set_diff    | 0.05   |      1600 |     0.64  |             12168.04% |                 3.60% | 1.3e-06 |      20 |
 | Array::Set::set_diff    | 0.063  |      1620 |     0.617 |             12610.06% |                 0.00% | 2.5e-07 |      23 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff       13/s                    --                     -92%                     -92%                     -93%                     -98%                     -98%                     -98%                  -99%                  -99% 
  Set::Scalar::difference   182/s                 1320%                       --                       0%                      -1%                     -78%                     -78%                     -78%                  -88%                  -88% 
  Set::Scalar::difference   183/s                 1323%                       0%                       --                      -1%                     -78%                     -78%                     -78%                  -88%                  -88% 
  Set::Scalar::difference   185/s                 1341%                       1%                       1%                       --                     -77%                     -77%                     -77%                  -88%                  -88% 
  Set::Object::difference   832/s                 6400%                     357%                     356%                     350%                       --                       0%                       0%                  -46%                  -48% 
  Set::Object::difference   830/s                 6400%                     357%                     356%                     350%                       0%                       --                       0%                  -46%                  -48% 
  Set::Object::difference   850/s                 6400%                     357%                     356%                     350%                       0%                       0%                       --                  -46%                  -48% 
  Array::Set::set_diff     1600/s                12087%                     757%                     756%                     745%                      87%                      87%                      87%                    --                   -3% 
  Array::Set::set_diff     1620/s                12541%                     789%                     788%                     776%                      94%                      94%                      94%                    3%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.063 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table5#
 {dataset=>"100_1"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::difference | 0.02   |      2300 |   440     |                 0.00% |               959.55% | 6.6e-07 |      22 |
 | Set::Scalar::difference | 0.063  |      2300 |   430     |                 1.51% |               943.77% | 1.5e-06 |      21 |
 | Set::Scalar::difference | 0.05   |      2400 |   420     |                 3.09% |               927.74% | 8.5e-07 |      20 |
 | Array::Set::set_diff    | 0.02   |      2700 |   370     |                16.67% |               808.15% | 4.7e-07 |      21 |
 | Set::Object::difference | 0.02   |      9500 |   100     |               316.69% |               154.27% | 6.7e-07 |      20 |
 | Set::Object::difference | 0.05   |     10000 |   100     |               336.38% |               142.80% | 1.3e-07 |      20 |
 | Set::Object::difference | 0.063  |     10000 |   100     |               339.18% |               141.26% | 1.1e-07 |      20 |
 | Array::Set::set_diff    | 0.063  |     24100 |    41.5   |               954.33% |                 0.50% | 1.3e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |     24240 |    41.254 |               959.55% |                 0.00% | 4.7e-11 |      23 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Array::Set::set_diff  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Set::Scalar::difference   2300/s                       --                      -2%                      -4%                  -15%                     -77%                     -77%                     -77%                  -90%                  -90% 
  Set::Scalar::difference   2300/s                       2%                       --                      -2%                  -13%                     -76%                     -76%                     -76%                  -90%                  -90% 
  Set::Scalar::difference   2400/s                       4%                       2%                       --                  -11%                     -76%                     -76%                     -76%                  -90%                  -90% 
  Array::Set::set_diff      2700/s                      18%                      16%                      13%                    --                     -72%                     -72%                     -72%                  -88%                  -88% 
  Set::Object::difference   9500/s                     340%                     330%                     320%                  270%                       --                       0%                       0%                  -58%                  -58% 
  Set::Object::difference  10000/s                     340%                     330%                     320%                  270%                       0%                       --                       0%                  -58%                  -58% 
  Set::Object::difference  10000/s                     340%                     330%                     320%                  270%                       0%                       0%                       --                  -58%                  -58% 
  Array::Set::set_diff     24100/s                     960%                     936%                     912%                  791%                     140%                     140%                     140%                    --                    0% 
  Array::Set::set_diff     24240/s                     966%                     942%                     918%                  796%                     142%                     142%                     142%                    0%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.05 participant=Set::Scalar::difference

 #table6#
 {dataset=>"100_10"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |      2020 |     496   |                 0.00% |              1040.28% | 4.2e-07 |      21 |
 | Set::Scalar::difference | 0.02   |      2100 |     470   |                 4.72% |               988.86% | 1.4e-06 |      20 |
 | Set::Scalar::difference | 0.063  |      2100 |     470   |                 5.68% |               978.98% | 1.3e-06 |      21 |
 | Set::Scalar::difference | 0.05   |      2200 |     460   |                 7.54% |               960.33% | 4.8e-07 |      20 |
 | Set::Object::difference | 0.02   |      8900 |     110   |               339.82% |               159.26% | 4.3e-07 |      20 |
 | Set::Object::difference | 0.05   |      9800 |     100   |               383.61% |               135.79% | 1.1e-07 |      27 |
 | Set::Object::difference | 0.063  |      9830 |     102   |               387.16% |               134.07% | 9.9e-08 |      23 |
 | Array::Set::set_diff    | 0.063  |     22000 |      45   |              1007.83% |                 2.93% | 1.1e-07 |      20 |
 | Array::Set::set_diff    | 0.05   |     23000 |      43.5 |              1040.28% |                 0.00% | 1.3e-08 |      21 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff      2020/s                    --                      -5%                      -5%                      -7%                     -77%                     -79%                     -79%                  -90%                  -91% 
  Set::Scalar::difference   2100/s                    5%                       --                       0%                      -2%                     -76%                     -78%                     -78%                  -90%                  -90% 
  Set::Scalar::difference   2100/s                    5%                       0%                       --                      -2%                     -76%                     -78%                     -78%                  -90%                  -90% 
  Set::Scalar::difference   2200/s                    7%                       2%                       2%                       --                     -76%                     -77%                     -78%                  -90%                  -90% 
  Set::Object::difference   8900/s                  350%                     327%                     327%                     318%                       --                      -7%                      -9%                  -59%                  -60% 
  Set::Object::difference   9830/s                  386%                     360%                     360%                     350%                       7%                       --                      -1%                  -55%                  -57% 
  Set::Object::difference   9800/s                  396%                     370%                     370%                     359%                      10%                       2%                       --                  -55%                  -56% 
  Array::Set::set_diff     22000/s                 1002%                     944%                     944%                     922%                     144%                     126%                     122%                    --                   -3% 
  Array::Set::set_diff     23000/s                 1040%                     980%                     980%                     957%                     152%                     134%                     129%                    3%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.05 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.05 participant=Set::Scalar::difference

 #table7#
 {dataset=>"100_100"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |     915   | 1090      |                 0.00% |              1685.86% | 1.1e-06 |      20 |
 | Set::Scalar::difference | 0.02   |    1200   |  833      |                31.15% |              1261.74% | 6.4e-07 |      20 |
 | Set::Scalar::difference | 0.063  |    1210   |  826      |                32.32% |              1249.68% | 2.7e-07 |      20 |
 | Set::Scalar::difference | 0.05   |    1200   |  820      |                33.88% |              1233.90% |   2e-06 |      20 |
 | Set::Object::difference | 0.02   |    8300   |  120      |               803.43% |                97.68% | 2.1e-07 |      21 |
 | Set::Object::difference | 0.063  |    8400   |  120      |               814.91% |                95.20% | 2.4e-07 |      25 |
 | Set::Object::difference | 0.05   |    8600   |  120      |               834.80% |                91.04% | 2.1e-07 |      20 |
 | Array::Set::set_diff    | 0.063  |   16186.7 |   61.7789 |              1668.55% |                 0.98% | 4.6e-11 |      28 |
 | Array::Set::set_diff    | 0.05   |   16300   |   61.2    |              1685.86% |                 0.00% | 2.2e-08 |      29 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  Array::Set::set_diff  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Array::Set::set_diff         915/s                    --                     -23%                     -24%                     -24%                     -88%                     -88%                     -88%                  -94%                  -94% 
  Set::Scalar::difference     1200/s                   30%                       --                       0%                      -1%                     -85%                     -85%                     -85%                  -92%                  -92% 
  Set::Scalar::difference     1210/s                   31%                       0%                       --                       0%                     -85%                     -85%                     -85%                  -92%                  -92% 
  Set::Scalar::difference     1200/s                   32%                       1%                       0%                       --                     -85%                     -85%                     -85%                  -92%                  -92% 
  Set::Object::difference     8300/s                  808%                     594%                     588%                     583%                       --                       0%                       0%                  -48%                  -49% 
  Set::Object::difference     8400/s                  808%                     594%                     588%                     583%                       0%                       --                       0%                  -48%                  -49% 
  Set::Object::difference     8600/s                  808%                     594%                     588%                     583%                       0%                       0%                       --                  -48%                  -49% 
  Array::Set::set_diff     16186.7/s                 1664%                    1248%                    1237%                    1227%                      94%                      94%                      94%                    --                    0% 
  Array::Set::set_diff       16300/s                 1681%                    1261%                    1249%                    1239%                      96%                      96%                      96%                    0%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.05 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.05 participant=Set::Scalar::difference

 #table8#
 {dataset=>"10_1"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::difference | 0.02   |      8700 | 120       |                 0.00% |              1558.38% | 4.3e-07 |      20 |
 | Set::Scalar::difference | 0.05   |      8700 | 110       |                 0.63% |              1548.07% |   2e-07 |      23 |
 | Set::Scalar::difference | 0.063  |      8800 | 110       |                 1.76% |              1529.73% | 1.4e-07 |      26 |
 | Array::Set::set_diff    | 0.02   |     23800 |  42.1     |               174.07% |               505.09% |   4e-08 |      20 |
 | Set::Object::difference | 0.02   |     77000 |  13       |               783.52% |                87.70% | 1.3e-08 |      20 |
 | Set::Object::difference | 0.05   |     78000 |  13       |               801.89% |                83.88% | 1.3e-08 |      20 |
 | Set::Object::difference | 0.063  |     78284 |  12.774   |               802.94% |                83.66% | 4.6e-11 |      26 |
 | Array::Set::set_diff    | 0.063  |    143095 |   6.98836 |              1550.48% |                 0.48% |   0     |      20 |
 | Array::Set::set_diff    | 0.05   |    144000 |   6.96    |              1558.38% |                 0.00% | 3.3e-09 |      20 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Array::Set::set_diff  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Set::Scalar::difference    8700/s                       --                      -8%                      -8%                  -64%                     -89%                     -89%                     -89%                  -94%                  -94% 
  Set::Scalar::difference    8700/s                       9%                       --                       0%                  -61%                     -88%                     -88%                     -88%                  -93%                  -93% 
  Set::Scalar::difference    8800/s                       9%                       0%                       --                  -61%                     -88%                     -88%                     -88%                  -93%                  -93% 
  Array::Set::set_diff      23800/s                     185%                     161%                     161%                    --                     -69%                     -69%                     -69%                  -83%                  -83% 
  Set::Object::difference   77000/s                     823%                     746%                     746%                  223%                       --                       0%                      -1%                  -46%                  -46% 
  Set::Object::difference   78000/s                     823%                     746%                     746%                  223%                       0%                       --                      -1%                  -46%                  -46% 
  Set::Object::difference   78284/s                     839%                     761%                     761%                  229%                       1%                       1%                       --                  -45%                  -45% 
  Array::Set::set_diff     143095/s                    1617%                    1474%                    1474%                  502%                      86%                      86%                      82%                    --                    0% 
  Array::Set::set_diff     144000/s                    1624%                    1480%                    1480%                  504%                      86%                      86%                      83%                    0%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table9#
 {dataset=>"10_10"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::difference | 0.02   |      6900 |     140   |                 0.00% |              1544.31% | 6.9e-07 |      20 |
 | Set::Scalar::difference | 0.063  |      6900 |     140   |                 0.40% |              1537.71% | 1.2e-06 |      23 |
 | Set::Scalar::difference | 0.05   |      6900 |     140   |                 0.46% |              1536.72% | 1.3e-06 |      20 |
 | Array::Set::set_diff    | 0.02   |     17000 |      58   |               150.04% |               557.62% | 1.3e-07 |      20 |
 | Set::Object::difference | 0.02   |     50000 |      20   |               688.43% |               108.56% | 4.3e-07 |      22 |
 | Set::Object::difference | 0.05   |     69000 |      15   |               895.50% |                65.17% |   2e-08 |      20 |
 | Set::Object::difference | 0.063  |     69000 |      14.5 |               897.67% |                64.81% | 6.7e-09 |      20 |
 | Array::Set::set_diff    | 0.05   |    110000 |       8.9 |              1521.19% |                 1.43% | 2.7e-08 |      20 |
 | Array::Set::set_diff    | 0.063  |    110000 |       8.8 |              1544.31% |                 0.00% | 1.3e-08 |      20 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Array::Set::set_diff  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Set::Scalar::difference    6900/s                       --                       0%                       0%                  -58%                     -85%                     -89%                     -89%                  -93%                  -93% 
  Set::Scalar::difference    6900/s                       0%                       --                       0%                  -58%                     -85%                     -89%                     -89%                  -93%                  -93% 
  Set::Scalar::difference    6900/s                       0%                       0%                       --                  -58%                     -85%                     -89%                     -89%                  -93%                  -93% 
  Array::Set::set_diff      17000/s                     141%                     141%                     141%                    --                     -65%                     -74%                     -75%                  -84%                  -84% 
  Set::Object::difference   50000/s                     600%                     600%                     600%                  190%                       --                     -25%                     -27%                  -55%                  -55% 
  Set::Object::difference   69000/s                     833%                     833%                     833%                  286%                      33%                       --                      -3%                  -40%                  -41% 
  Set::Object::difference   69000/s                     865%                     865%                     865%                  300%                      37%                       3%                       --                  -38%                  -39% 
  Array::Set::set_diff     110000/s                    1473%                    1473%                    1473%                  551%                     124%                      68%                      62%                    --                   -1% 
  Array::Set::set_diff     110000/s                    1490%                    1490%                    1490%                  559%                     127%                      70%                      64%                    1%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.063 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.05 participant=Set::Scalar::difference

 #table10#
 {dataset=>"10_5"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::difference | 0.05   |      7900 |  130      |                 0.00% |              1541.39% | 2.4e-07 |      25 |
 | Set::Scalar::difference | 0.02   |      7900 |  130      |                 0.24% |              1537.54% |   2e-07 |      23 |
 | Set::Scalar::difference | 0.063  |      8000 |  120      |                 0.90% |              1526.75% | 2.1e-07 |      21 |
 | Array::Set::set_diff    | 0.02   |     19700 |   50.8    |               148.44% |               560.69% |   4e-08 |      20 |
 | Set::Object::difference | 0.02   |     71000 |   14      |               789.93% |                84.44% | 2.7e-08 |      20 |
 | Set::Object::difference | 0.05   |     74300 |   13.5    |               836.49% |                75.27% | 1.3e-08 |      20 |
 | Set::Object::difference | 0.063  |     76000 |   13      |               855.11% |                71.85% | 1.3e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |    130140 |    7.6838 |              1541.32% |                 0.00% | 4.6e-11 |      20 |
 | Array::Set::set_diff    | 0.063  |    130150 |    7.6835 |              1541.39% |                 0.00% | 4.6e-11 |      20 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Array::Set::set_diff  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Set::Scalar::difference    7900/s                       --                       0%                      -7%                  -60%                     -89%                     -89%                     -90%                  -94%                  -94% 
  Set::Scalar::difference    7900/s                       0%                       --                      -7%                  -60%                     -89%                     -89%                     -90%                  -94%                  -94% 
  Set::Scalar::difference    8000/s                       8%                       8%                       --                  -57%                     -88%                     -88%                     -89%                  -93%                  -93% 
  Array::Set::set_diff      19700/s                     155%                     155%                     136%                    --                     -72%                     -73%                     -74%                  -84%                  -84% 
  Set::Object::difference   71000/s                     828%                     828%                     757%                  262%                       --                      -3%                      -7%                  -45%                  -45% 
  Set::Object::difference   74300/s                     862%                     862%                     788%                  276%                       3%                       --                      -3%                  -43%                  -43% 
  Set::Object::difference   76000/s                     900%                     900%                     823%                  290%                       7%                       3%                       --                  -40%                  -40% 
  Array::Set::set_diff     130140/s                    1591%                    1591%                    1461%                  561%                      82%                      75%                      69%                    --                    0% 
  Array::Set::set_diff     130150/s                    1591%                    1591%                    1461%                  561%                      82%                      75%                      69%                    0%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.063 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.063 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.063 participant=Set::Scalar::difference

 #table11#
 {dataset=>"1_1"}
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::difference | 0.05   |     12000 |     80    |                 0.00% |              2735.58% | 1.1e-07 |      20 |
 | Set::Scalar::difference | 0.063  |     12000 |     80    |                 0.35% |              2725.65% | 1.9e-07 |      26 |
 | Set::Scalar::difference | 0.02   |     13000 |     78    |                 2.73% |              2660.23% | 3.2e-07 |      20 |
 | Array::Set::set_diff    | 0.02   |    100000 |      9.8  |               720.55% |               245.57% | 1.3e-08 |      20 |
 | Set::Object::difference | 0.063  |    200000 |      5.1  |              1488.43% |                78.51% | 6.7e-09 |      20 |
 | Set::Object::difference | 0.05   |    198000 |      5.04 |              1492.94% |                78.01% | 1.7e-09 |      20 |
 | Set::Object::difference | 0.02   |    200000 |      5    |              1493.12% |                77.99% | 6.7e-09 |      20 |
 | Array::Set::set_diff    | 0.063  |    350000 |      2.8  |              2719.88% |                 0.56% | 1.3e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |    350000 |      2.8  |              2735.58% |                 0.00% | 2.4e-08 |      21 |
 +-------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  Set::Scalar::difference  Set::Scalar::difference  Set::Scalar::difference  Array::Set::set_diff  Set::Object::difference  Set::Object::difference  Set::Object::difference  Array::Set::set_diff  Array::Set::set_diff 
  Set::Scalar::difference   12000/s                       --                       0%                      -2%                  -87%                     -93%                     -93%                     -93%                  -96%                  -96% 
  Set::Scalar::difference   12000/s                       0%                       --                      -2%                  -87%                     -93%                     -93%                     -93%                  -96%                  -96% 
  Set::Scalar::difference   13000/s                       2%                       2%                       --                  -87%                     -93%                     -93%                     -93%                  -96%                  -96% 
  Array::Set::set_diff     100000/s                     716%                     716%                     695%                    --                     -47%                     -48%                     -48%                  -71%                  -71% 
  Set::Object::difference  200000/s                    1468%                    1468%                    1429%                   92%                       --                      -1%                      -1%                  -45%                  -45% 
  Set::Object::difference  198000/s                    1487%                    1487%                    1447%                   94%                       1%                       --                       0%                  -44%                  -44% 
  Set::Object::difference  200000/s                    1500%                    1500%                    1460%                   96%                       2%                       0%                       --                  -44%                  -44% 
  Array::Set::set_diff     350000/s                    2757%                    2757%                    2685%                  250%                      82%                      80%                      78%                    --                    0% 
  Array::Set::set_diff     350000/s                    2757%                    2757%                    2685%                  250%                      82%                      80%                      78%                    0%                    -- 
 
 Legends:
   Array::Set::set_diff: modver=0.05 participant=Array::Set::set_diff
   Set::Object::difference: modver=0.02 participant=Set::Object::difference
   Set::Scalar::difference: modver=0.02 participant=Set::Scalar::difference


Benchmark module startup overhead (C<< bencher -m Array::Set::diff --module-startup >>):

 #table12#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Set::Object         |      25.2 |              15.6 |                 0.00% |               161.84% | 1.1e-05 |      21 |
 | Set::Scalar         |      22.1 |              12.5 |                14.11% |               129.46% | 1.2e-05 |      20 |
 | Array::Set          |      14   |               4.4 |                82.02% |                43.86% | 1.5e-05 |      20 |
 | perl -e1 (baseline) |       9.6 |               0   |               161.84% |                 0.00% | 2.4e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:O   S:S   A:S  perl -e1 (baseline) 
  S:O                   39.7/s    --  -12%  -44%                 -61% 
  S:S                   45.2/s   14%    --  -36%                 -56% 
  A:S                   71.4/s   80%   57%    --                 -31% 
  perl -e1 (baseline)  104.2/s  162%  130%   45%                   -- 
 
 Legends:
   A:S: mod_overhead_time=4.4 participant=Array::Set
   S:O: mod_overhead_time=15.6 participant=Set::Object
   S:S: mod_overhead_time=12.5 participant=Set::Scalar
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
