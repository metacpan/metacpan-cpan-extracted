package Bencher::Scenario::Array::Set::union;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark union operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_union(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'union',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'union',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);', # $res->as_string
        },
    ],
    datasets => [
        { name => '1_1'  , args => { set1=>[1], set2=>[1] } },

        { name => '10_1' , args => { set1=>[1..10], set2=>[1] } },
        { name => '10_5' , args => { set1=>[1..10], set2=>[3..7] } },
        { name => '10_10', args => { set1=>[1..10], set2=>[1..10] } },

        { name => '100_1'  , args => { set1=>[1..100], set2=>[1] } },
        { name => '100_10' , args => { set1=>[1..100], set2=>[96..105] } },
        { name => '100_100', args => { set1=>[1..100], set2=>[1..100] } },

        { name => '1000_1'   , args => { set1=>[1..1000], set2=>[1] } },
        { name => '1000_10'  , args => { set1=>[1..1000], set2=>[996..1005] } },
        { name => '1000_100' , args => { set1=>[1..1000], set2=>[951..1050] } },
        { name => '1000_1000', args => { set1=>[1..1000], set2=>[1..1000] } },
    ],
};

1;
# ABSTRACT: Benchmark union operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Set::union - Benchmark union operation

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Array::Set::union (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Set::union

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Set::union

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

=item * Array::Set::set_union (perl_code)

Function call template:

 Array::Set::set_union(<set1>, <set2>)



=item * Set::Object::union (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);



=item * Set::Scalar::union (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);



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

Benchmark with C<< bencher -m Array::Set::union --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.063  |       200 |     5     |                 0.00% |               734.08% | 6.1e-06 |      20 |
 | Set::Scalar::union    | 0.02   |       204 |     4.89  |                 2.08% |               717.11% |   2e-06 |      20 |
 | Set::Scalar::union    | 0.05   |       210 |     4.9   |                 2.39% |               714.60% | 5.4e-06 |      20 |
 | Array::Set::set_union | 0.02   |       286 |     3.5   |                42.88% |               483.77% | 3.3e-06 |      20 |
 | Set::Object::union    | 0.05   |      1350 |     0.74  |               574.67% |                23.63% | 4.7e-07 |      21 |
 | Set::Object::union    | 0.063  |      1400 |     0.73  |               584.37% |                21.88% | 1.1e-06 |      20 |
 | Set::Object::union    | 0.02   |      1400 |     0.71  |               601.00% |                18.99% | 9.1e-07 |      20 |
 | Array::Set::set_union | 0.063  |      1600 |     0.625 |               699.46% |                 4.33% | 4.8e-07 |      20 |
 | Array::Set::set_union | 0.05   |      1700 |     0.6   |               734.08% |                 0.00% | 1.1e-06 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      200/s                  --                 -1%                 -2%                   -30%                -85%                -85%                -85%                   -87%                   -88% 
  Set::Scalar::union      210/s                  2%                  --                  0%                   -28%                -84%                -85%                -85%                   -87%                   -87% 
  Set::Scalar::union      204/s                  2%                  0%                  --                   -28%                -84%                -85%                -85%                   -87%                   -87% 
  Array::Set::set_union   286/s                 42%                 40%                 39%                     --                -78%                -79%                -79%                   -82%                   -82% 
  Set::Object::union     1350/s                575%                562%                560%                   372%                  --                 -1%                 -4%                   -15%                   -18% 
  Set::Object::union     1400/s                584%                571%                569%                   379%                  1%                  --                 -2%                   -14%                   -17% 
  Set::Object::union     1400/s                604%                590%                588%                   392%                  4%                  2%                  --                   -11%                   -15% 
  Array::Set::set_union  1600/s                700%                684%                682%                   459%                 18%                 16%                 13%                     --                    -4% 
  Array::Set::set_union  1700/s                733%                716%                715%                   483%                 23%                 21%                 18%                     4%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union

 #table2#
 {dataset=>"1000_10"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.02   |       190 |     5.2   |                 0.00% |               747.32% | 2.1e-05 |      20 |
 | Set::Scalar::union    | 0.063  |       190 |     5.2   |                 0.01% |               747.21% | 9.6e-06 |      20 |
 | Set::Scalar::union    | 0.05   |       202 |     4.95  |                 4.27% |               712.66% | 3.3e-06 |      21 |
 | Array::Set::set_union | 0.02   |       284 |     3.52  |                46.43% |               478.67% | 2.9e-06 |      20 |
 | Set::Object::union    | 0.063  |      1300 |     0.75  |               589.13% |                22.96% |   2e-06 |      20 |
 | Set::Object::union    | 0.05   |      1340 |     0.744 |               593.73% |                22.14% | 6.9e-07 |      20 |
 | Set::Object::union    | 0.02   |      1400 |     0.72  |               615.58% |                18.41% | 1.1e-06 |      20 |
 | Array::Set::set_union | 0.063  |      1600 |     0.64  |               712.37% |                 4.30% | 1.7e-06 |      22 |
 | Array::Set::set_union | 0.05   |      1640 |     0.609 |               747.32% |                 0.00% | 4.3e-07 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      190/s                  --                  0%                 -4%                   -32%                -85%                -85%                -86%                   -87%                   -88% 
  Set::Scalar::union      190/s                  0%                  --                 -4%                   -32%                -85%                -85%                -86%                   -87%                   -88% 
  Set::Scalar::union      202/s                  5%                  5%                  --                   -28%                -84%                -84%                -85%                   -87%                   -87% 
  Array::Set::set_union   284/s                 47%                 47%                 40%                     --                -78%                -78%                -79%                   -81%                   -82% 
  Set::Object::union     1300/s                593%                593%                560%                   369%                  --                  0%                 -4%                   -14%                   -18% 
  Set::Object::union     1340/s                598%                598%                565%                   373%                  0%                  --                 -3%                   -13%                   -18% 
  Set::Object::union     1400/s                622%                622%                587%                   388%                  4%                  3%                  --                   -11%                   -15% 
  Array::Set::set_union  1600/s                712%                712%                673%                   450%                 17%                 16%                 12%                     --                    -4% 
  Array::Set::set_union  1640/s                753%                753%                712%                   477%                 23%                 22%                 18%                     5%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.05 participant=Set::Scalar::union

 #table3#
 {dataset=>"1000_100"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.063  |       170 |     5.7   |                 0.00% |               777.03% | 2.9e-05 |      20 |
 | Set::Scalar::union    | 0.02   |       170 |     5.7   |                 0.13% |               775.87% | 1.2e-05 |      20 |
 | Set::Scalar::union    | 0.05   |       190 |     5.4   |                 6.89% |               720.47% |   6e-06 |      20 |
 | Array::Set::set_union | 0.02   |       264 |     3.78  |                51.75% |               477.95% | 1.3e-06 |      20 |
 | Set::Object::union    | 0.05   |      1200 |     0.85  |               576.86% |                29.57% | 1.2e-06 |      22 |
 | Set::Object::union    | 0.063  |      1200 |     0.83  |               588.69% |                27.35% | 1.2e-06 |      23 |
 | Set::Object::union    | 0.02   |      1230 |     0.814 |               605.68% |                24.28% | 4.3e-07 |      20 |
 | Array::Set::set_union | 0.063  |      1500 |     0.68  |               741.84% |                 4.18% | 2.2e-06 |      20 |
 | Array::Set::set_union | 0.05   |      1530 |     0.655 |               777.03% |                 0.00% | 4.8e-07 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      170/s                  --                  0%                 -5%                   -33%                -85%                -85%                -85%                   -88%                   -88% 
  Set::Scalar::union      170/s                  0%                  --                 -5%                   -33%                -85%                -85%                -85%                   -88%                   -88% 
  Set::Scalar::union      190/s                  5%                  5%                  --                   -30%                -84%                -84%                -84%                   -87%                   -87% 
  Array::Set::set_union   264/s                 50%                 50%                 42%                     --                -77%                -78%                -78%                   -82%                   -82% 
  Set::Object::union     1200/s                570%                570%                535%                   344%                  --                 -2%                 -4%                   -19%                   -22% 
  Set::Object::union     1200/s                586%                586%                550%                   355%                  2%                  --                 -1%                   -18%                   -21% 
  Set::Object::union     1230/s                600%                600%                563%                   364%                  4%                  1%                  --                   -16%                   -19% 
  Array::Set::set_union  1500/s                738%                738%                694%                   455%                 24%                 22%                 19%                     --                    -3% 
  Array::Set::set_union  1530/s                770%                770%                724%                   477%                 29%                 26%                 24%                     3%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.05 participant=Set::Scalar::union

 #table4#
 {dataset=>"1000_1000"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant           | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Set::Scalar::union    | 0.063  |        56 |     18    |                 0.00% |              1912.60% |   0.00011 |      21 |
 | Set::Scalar::union    | 0.05   |       122 |      8.19 |               119.86% |               815.42% | 5.6e-06   |      20 |
 | Set::Scalar::union    | 0.02   |       124 |      8.05 |               123.65% |               799.90% | 2.7e-06   |      20 |
 | Array::Set::set_union | 0.02   |       170 |      5.8  |               208.69% |               551.98% | 7.1e-06   |      20 |
 | Set::Object::union    | 0.05   |       720 |      1.4  |              1199.91% |                54.83% | 1.8e-06   |      20 |
 | Set::Object::union    | 0.063  |       740 |      1.4  |              1225.33% |                51.86% | 2.2e-06   |      20 |
 | Set::Object::union    | 0.02   |       754 |      1.33 |              1258.13% |                48.19% | 9.1e-07   |      20 |
 | Array::Set::set_union | 0.05   |      1100 |      0.94 |              1825.98% |                 4.50% | 2.2e-06   |      20 |
 | Array::Set::set_union | 0.063  |      1100 |      0.89 |              1912.60% |                 0.00% | 3.1e-06   |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union       56/s                  --                -54%                -55%                   -67%                -92%                -92%                -92%                   -94%                   -95% 
  Set::Scalar::union      122/s                119%                  --                 -1%                   -29%                -82%                -82%                -83%                   -88%                   -89% 
  Set::Scalar::union      124/s                123%                  1%                  --                   -27%                -82%                -82%                -83%                   -88%                   -88% 
  Array::Set::set_union   170/s                210%                 41%                 38%                     --                -75%                -75%                -77%                   -83%                   -84% 
  Set::Object::union      720/s               1185%                484%                475%                   314%                  --                  0%                 -4%                   -32%                   -36% 
  Set::Object::union      740/s               1185%                484%                475%                   314%                  0%                  --                 -4%                   -32%                   -36% 
  Set::Object::union      754/s               1253%                515%                505%                   336%                  5%                  5%                  --                   -29%                   -33% 
  Array::Set::set_union  1100/s               1814%                771%                756%                   517%                 48%                 48%                 41%                     --                    -5% 
  Array::Set::set_union  1100/s               1922%                820%                804%                   551%                 57%                 57%                 49%                     5%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.063 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union

 #table5#
 {dataset=>"100_1"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.05   |      1700 |       570 |                 0.00% |               887.94% | 1.8e-06 |      21 |
 | Set::Scalar::union    | 0.02   |      1800 |       570 |                 0.42% |               883.79% | 1.1e-06 |      21 |
 | Set::Scalar::union    | 0.063  |      1800 |       560 |                 1.63% |               872.14% | 6.4e-07 |      20 |
 | Array::Set::set_union | 0.02   |      2700 |       360 |                57.52% |               527.20% | 4.1e-07 |      22 |
 | Set::Object::union    | 0.05   |     14000 |        74 |               673.77% |                27.68% | 5.5e-07 |      21 |
 | Set::Object::union    | 0.063  |     14000 |        73 |               688.29% |                25.33% | 6.7e-07 |      20 |
 | Set::Object::union    | 0.02   |     14000 |        72 |               700.68% |                23.39% | 6.4e-07 |      20 |
 | Array::Set::set_union | 0.063  |     17000 |        59 |               870.49% |                 1.80% | 1.1e-07 |      20 |
 | Array::Set::set_union | 0.05   |     17000 |        58 |               887.94% |                 0.00% | 1.1e-07 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                            Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      1700/s                  --                  0%                 -1%                   -36%                -87%                -87%                -87%                   -89%                   -89% 
  Set::Scalar::union      1800/s                  0%                  --                 -1%                   -36%                -87%                -87%                -87%                   -89%                   -89% 
  Set::Scalar::union      1800/s                  1%                  1%                  --                   -35%                -86%                -86%                -87%                   -89%                   -89% 
  Array::Set::set_union   2700/s                 58%                 58%                 55%                     --                -79%                -79%                -80%                   -83%                   -83% 
  Set::Object::union     14000/s                670%                670%                656%                   386%                  --                 -1%                 -2%                   -20%                   -21% 
  Set::Object::union     14000/s                680%                680%                667%                   393%                  1%                  --                 -1%                   -19%                   -20% 
  Set::Object::union     14000/s                691%                691%                677%                   400%                  2%                  1%                  --                   -18%                   -19% 
  Array::Set::set_union  17000/s                866%                866%                849%                   510%                 25%                 23%                 22%                     --                    -1% 
  Array::Set::set_union  17000/s                882%                882%                865%                   520%                 27%                 25%                 24%                     1%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.063 participant=Set::Scalar::union

 #table6#
 {dataset=>"100_10"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.02   |      1600 |     610   |                 0.00% |               914.47% | 8.8e-07 |      21 |
 | Set::Scalar::union    | 0.05   |      1600 |     610   |                 0.76% |               906.82% | 1.8e-06 |      20 |
 | Set::Scalar::union    | 0.063  |      1700 |     600   |                 1.76% |               896.94% | 1.8e-06 |      20 |
 | Array::Set::set_union | 0.02   |      2600 |     390   |                57.71% |               543.26% |   2e-06 |      21 |
 | Set::Object::union    | 0.02   |     12000 |      83   |               644.99% |                36.17% | 1.1e-07 |      20 |
 | Set::Object::union    | 0.05   |     12000 |      82   |               652.38% |                34.83% | 1.1e-07 |      20 |
 | Set::Object::union    | 0.063  |     13000 |      79   |               675.17% |                30.87% | 1.3e-07 |      20 |
 | Array::Set::set_union | 0.063  |     16500 |      60.7 |               912.56% |                 0.19% | 2.5e-08 |      22 |
 | Array::Set::set_union | 0.05   |     16000 |      61   |               914.47% |                 0.00% |   8e-08 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                            Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      1600/s                  --                  0%                 -1%                   -36%                -86%                -86%                -87%                   -90%                   -90% 
  Set::Scalar::union      1600/s                  0%                  --                 -1%                   -36%                -86%                -86%                -87%                   -90%                   -90% 
  Set::Scalar::union      1700/s                  1%                  1%                  --                   -35%                -86%                -86%                -86%                   -89%                   -89% 
  Array::Set::set_union   2600/s                 56%                 56%                 53%                     --                -78%                -78%                -79%                   -84%                   -84% 
  Set::Object::union     12000/s                634%                634%                622%                   369%                  --                 -1%                 -4%                   -26%                   -26% 
  Set::Object::union     12000/s                643%                643%                631%                   375%                  1%                  --                 -3%                   -25%                   -25% 
  Set::Object::union     13000/s                672%                672%                659%                   393%                  5%                  3%                  --                   -22%                   -23% 
  Array::Set::set_union  16000/s                900%                900%                883%                   539%                 36%                 34%                 29%                     --                     0% 
  Array::Set::set_union  16500/s                904%                904%                888%                   542%                 36%                 35%                 30%                     0%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.063 participant=Array::Set::set_union
   Set::Object::union: modver=0.063 participant=Set::Object::union
   Set::Scalar::union: modver=0.063 participant=Set::Scalar::union

 #table7#
 {dataset=>"100_100"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.02   |      1100 |       900 |                 0.00% |              1002.34% | 1.6e-06 |      21 |
 | Set::Scalar::union    | 0.05   |      1100 |       890 |                 1.35% |               987.70% | 2.2e-06 |      20 |
 | Set::Scalar::union    | 0.063  |      1140 |       874 |                 2.68% |               973.54% | 6.8e-07 |      21 |
 | Array::Set::set_union | 0.02   |      1700 |       590 |                53.38% |               618.71% | 1.3e-06 |      20 |
 | Set::Object::union    | 0.02   |      7700 |       130 |               591.52% |                59.41% | 2.1e-07 |      20 |
 | Set::Object::union    | 0.05   |      7800 |       130 |               595.88% |                58.41% |   2e-07 |      22 |
 | Set::Object::union    | 0.063  |      7900 |       130 |               610.26% |                55.20% | 2.1e-07 |      21 |
 | Array::Set::set_union | 0.063  |     12000 |        82 |               988.63% |                 1.26% | 1.1e-07 |      20 |
 | Array::Set::set_union | 0.05   |     12000 |        81 |              1002.34% |                 0.00% | 1.1e-07 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                            Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      1100/s                  --                 -1%                 -2%                   -34%                -85%                -85%                -85%                   -90%                   -91% 
  Set::Scalar::union      1100/s                  1%                  --                 -1%                   -33%                -85%                -85%                -85%                   -90%                   -90% 
  Set::Scalar::union      1140/s                  2%                  1%                  --                   -32%                -85%                -85%                -85%                   -90%                   -90% 
  Array::Set::set_union   1700/s                 52%                 50%                 48%                     --                -77%                -77%                -77%                   -86%                   -86% 
  Set::Object::union      7700/s                592%                584%                572%                   353%                  --                  0%                  0%                   -36%                   -37% 
  Set::Object::union      7800/s                592%                584%                572%                   353%                  0%                  --                  0%                   -36%                   -37% 
  Set::Object::union      7900/s                592%                584%                572%                   353%                  0%                  0%                  --                   -36%                   -37% 
  Array::Set::set_union  12000/s                997%                985%                965%                   619%                 58%                 58%                 58%                     --                    -1% 
  Array::Set::set_union  12000/s               1011%                998%                979%                   628%                 60%                 60%                 60%                     1%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.063 participant=Set::Object::union
   Set::Scalar::union: modver=0.063 participant=Set::Scalar::union

 #table8#
 {dataset=>"10_1"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.05   |      8000 |     130   |                 0.00% |              1320.53% | 2.1e-07 |      21 |
 | Set::Scalar::union    | 0.063  |      8000 |     120   |                 0.43% |              1314.43% |   2e-07 |      23 |
 | Set::Scalar::union    | 0.02   |      8100 |     120   |                 1.01% |              1306.30% | 2.1e-07 |      20 |
 | Array::Set::set_union | 0.02   |     24000 |      41.6 |               200.38% |               372.90% | 1.3e-08 |      20 |
 | Set::Object::union    | 0.05   |     89000 |      11   |              1011.20% |                27.84% | 2.8e-08 |      23 |
 | Set::Object::union    | 0.063  |     91000 |      11   |              1037.03% |                24.93% | 1.7e-08 |      20 |
 | Set::Object::union    | 0.02   |     92000 |      11   |              1051.88% |                23.32% | 1.3e-08 |      20 |
 | Array::Set::set_union | 0.05   |    100000 |       9   |              1291.81% |                 2.06% | 1.2e-07 |      23 |
 | Array::Set::set_union | 0.063  |    100000 |       9   |              1320.53% |                 0.00% | 1.3e-07 |      23 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union       8000/s                  --                 -7%                 -7%                   -68%                -91%                -91%                -91%                   -93%                   -93% 
  Set::Scalar::union       8000/s                  8%                  --                  0%                   -65%                -90%                -90%                -90%                   -92%                   -92% 
  Set::Scalar::union       8100/s                  8%                  0%                  --                   -65%                -90%                -90%                -90%                   -92%                   -92% 
  Array::Set::set_union   24000/s                212%                188%                188%                     --                -73%                -73%                -73%                   -78%                   -78% 
  Set::Object::union      89000/s               1081%                990%                990%                   278%                  --                  0%                  0%                   -18%                   -18% 
  Set::Object::union      91000/s               1081%                990%                990%                   278%                  0%                  --                  0%                   -18%                   -18% 
  Set::Object::union      92000/s               1081%                990%                990%                   278%                  0%                  0%                  --                   -18%                   -18% 
  Array::Set::set_union  100000/s               1344%               1233%               1233%                   362%                 22%                 22%                 22%                     --                     0% 
  Array::Set::set_union  100000/s               1344%               1233%               1233%                   362%                 22%                 22%                 22%                     0%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.063 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union

 #table9#
 {dataset=>"10_10"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.05   |    6600   |  150      |                 0.00% |              1315.52% | 2.5e-07 |      22 |
 | Set::Scalar::union    | 0.063  |    6800   |  150      |                 3.10% |              1272.99% | 1.3e-06 |      20 |
 | Set::Scalar::union    | 0.02   |    6800   |  150      |                 3.29% |              1270.49% | 1.1e-06 |      21 |
 | Array::Set::set_union | 0.02   |   16000   |   63      |               141.63% |               485.83% | 1.1e-07 |      20 |
 | Set::Object::union    | 0.063  |   61711.6 |   16.2044 |               836.43% |                51.16% | 1.1e-11 |      20 |
 | Set::Object::union    | 0.05   |   64000   |   16      |               863.86% |                46.86% |   2e-08 |      21 |
 | Set::Object::union    | 0.02   |   65500   |   15.3    |               893.51% |                42.48% | 6.7e-09 |      20 |
 | Array::Set::set_union | 0.063  |   92000   |   11      |              1295.43% |                 1.44% | 2.5e-08 |      22 |
 | Array::Set::set_union | 0.05   |   93300   |   10.7    |              1315.52% |                 0.00% |   1e-08 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union        6600/s                  --                  0%                  0%                   -58%                -89%                -89%                -89%                   -92%                   -92% 
  Set::Scalar::union        6800/s                  0%                  --                  0%                   -58%                -89%                -89%                -89%                   -92%                   -92% 
  Set::Scalar::union        6800/s                  0%                  0%                  --                   -58%                -89%                -89%                -89%                   -92%                   -92% 
  Array::Set::set_union    16000/s                138%                138%                138%                     --                -74%                -74%                -75%                   -82%                   -83% 
  Set::Object::union     61711.6/s                825%                825%                825%                   288%                  --                 -1%                 -5%                   -32%                   -33% 
  Set::Object::union       64000/s                837%                837%                837%                   293%                  1%                  --                 -4%                   -31%                   -33% 
  Set::Object::union       65500/s                880%                880%                880%                   311%                  5%                  4%                  --                   -28%                   -30% 
  Array::Set::set_union    92000/s               1263%               1263%               1263%                   472%                 47%                 45%                 39%                     --                    -2% 
  Array::Set::set_union    93300/s               1301%               1301%               1301%                   488%                 51%                 49%                 42%                     2%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union

 #table10#
 {dataset=>"10_5"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.05   |      7300 |  140      |                 0.00% |              1287.09% | 4.8e-07 |      20 |
 | Set::Scalar::union    | 0.063  |      7400 |  130      |                 1.42% |              1267.67% | 3.6e-07 |      22 |
 | Set::Scalar::union    | 0.02   |      7600 |  130      |                 2.94% |              1247.50% | 2.1e-07 |      20 |
 | Array::Set::set_union | 0.02   |     19500 |   51.3    |               165.55% |               422.35% | 4.7e-08 |      26 |
 | Set::Object::union    | 0.063  |     73000 |   14      |               900.04% |                38.70% | 3.3e-08 |      20 |
 | Set::Object::union    | 0.05   |     76000 |   13      |               939.65% |                33.42% | 1.3e-08 |      20 |
 | Set::Object::union    | 0.02   |     78000 |   13      |               960.65% |                30.78% | 1.3e-08 |      20 |
 | Array::Set::set_union | 0.05   |    100470 |    9.9529 |              1268.24% |                 1.38% | 4.6e-11 |      23 |
 | Array::Set::set_union | 0.063  |    100000 |    9.8    |              1287.09% |                 0.00% | 1.3e-08 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union       7300/s                  --                 -7%                 -7%                   -63%                -90%                -90%                -90%                   -92%                   -93% 
  Set::Scalar::union       7400/s                  7%                  --                  0%                   -60%                -89%                -90%                -90%                   -92%                   -92% 
  Set::Scalar::union       7600/s                  7%                  0%                  --                   -60%                -89%                -90%                -90%                   -92%                   -92% 
  Array::Set::set_union   19500/s                172%                153%                153%                     --                -72%                -74%                -74%                   -80%                   -80% 
  Set::Object::union      73000/s                900%                828%                828%                   266%                  --                 -7%                 -7%                   -28%                   -29% 
  Set::Object::union      76000/s                976%                900%                900%                   294%                  7%                  --                  0%                   -23%                   -24% 
  Set::Object::union      78000/s                976%                900%                900%                   294%                  7%                  0%                  --                   -23%                   -24% 
  Array::Set::set_union  100470/s               1306%               1206%               1206%                   415%                 40%                 30%                 30%                     --                    -1% 
  Array::Set::set_union  100000/s               1328%               1226%               1226%                   423%                 42%                 32%                 32%                     1%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.063 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union

 #table11#
 {dataset=>"1_1"}
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::union    | 0.063  |     12000 |     82    |                 0.00% |              3488.16% |   1e-07 |      22 |
 | Set::Scalar::union    | 0.05   |     12000 |     82    |                 0.20% |              3481.11% | 1.1e-07 |      20 |
 | Set::Scalar::union    | 0.02   |     12000 |     82    |                 0.45% |              3472.03% |   1e-07 |      21 |
 | Array::Set::set_union | 0.02   |     96400 |     10.4  |               691.24% |               353.49% |   1e-08 |      20 |
 | Set::Object::union    | 0.05   |    170000 |      5.9  |              1280.74% |               159.87% | 1.3e-08 |      20 |
 | Set::Object::union    | 0.063  |    200000 |      6    |              1302.45% |               155.85% |   7e-08 |      20 |
 | Set::Object::union    | 0.02   |    170000 |      5.8  |              1321.21% |               152.47% | 2.8e-08 |      20 |
 | Array::Set::set_union | 0.063  |    260000 |      3.8  |              2068.29% |                65.48% | 6.7e-09 |      20 |
 | Array::Set::set_union | 0.05   |    437000 |      2.29 |              3488.16% |                 0.00% | 8.3e-10 |      20 |
 +-----------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                             Rate  Set::Scalar::union  Set::Scalar::union  Set::Scalar::union  Array::Set::set_union  Set::Object::union  Set::Object::union  Set::Object::union  Array::Set::set_union  Array::Set::set_union 
  Set::Scalar::union      12000/s                  --                  0%                  0%                   -87%                -92%                -92%                -92%                   -95%                   -97% 
  Set::Scalar::union      12000/s                  0%                  --                  0%                   -87%                -92%                -92%                -92%                   -95%                   -97% 
  Set::Scalar::union      12000/s                  0%                  0%                  --                   -87%                -92%                -92%                -92%                   -95%                   -97% 
  Array::Set::set_union   96400/s                688%                688%                688%                     --                -42%                -43%                -44%                   -63%                   -77% 
  Set::Object::union     200000/s               1266%               1266%               1266%                    73%                  --                 -1%                 -3%                   -36%                   -61% 
  Set::Object::union     170000/s               1289%               1289%               1289%                    76%                  1%                  --                 -1%                   -35%                   -61% 
  Set::Object::union     170000/s               1313%               1313%               1313%                    79%                  3%                  1%                  --                   -34%                   -60% 
  Array::Set::set_union  260000/s               2057%               2057%               2057%                   173%                 57%                 55%                 52%                     --                   -39% 
  Array::Set::set_union  437000/s               3480%               3480%               3480%                   354%                162%                157%                153%                    65%                     -- 
 
 Legends:
   Array::Set::set_union: modver=0.05 participant=Array::Set::set_union
   Set::Object::union: modver=0.02 participant=Set::Object::union
   Set::Scalar::union: modver=0.02 participant=Set::Scalar::union


Benchmark module startup overhead (C<< bencher -m Array::Set::union --module-startup >>):

 #table12#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Set::Object         |     26    |             16.64 |                 0.00% |               182.22% | 6.1e-05   |      20 |
 | Set::Scalar         |     24    |             14.64 |                11.31% |               153.55% |   0.00012 |      20 |
 | Array::Set          |     15    |              5.64 |                81.44% |                55.55% | 2.7e-05   |      21 |
 | perl -e1 (baseline) |      9.36 |              0    |               182.22% |                 0.00% | 4.5e-06   |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:O   S:S   A:S  perl -e1 (baseline) 
  S:O                   38.5/s    --   -7%  -42%                 -64% 
  S:S                   41.7/s    8%    --  -37%                 -61% 
  A:S                   66.7/s   73%   60%    --                 -37% 
  perl -e1 (baseline)  106.8/s  177%  156%   60%                   -- 
 
 Legends:
   A:S: mod_overhead_time=5.64 participant=Array::Set
   S:O: mod_overhead_time=16.64 participant=Set::Object
   S:S: mod_overhead_time=14.64 participant=Set::Scalar
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
