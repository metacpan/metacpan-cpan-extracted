package Bencher::Scenario::Array::Set::symdiff;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Set'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark symmetric difference operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_symdiff(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'symmetric_difference',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'symmetric_difference',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);', # $res->as_string
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
# ABSTRACT: Benchmark symmetric difference operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Set::symdiff - Benchmark symmetric difference operation

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Array::Set::symdiff (from Perl distribution Bencher-Scenarios-Array-Set), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Set::symdiff

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Set::symdiff

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

=item * Array::Set::set_symdiff (perl_code)

Function call template:

 Array::Set::set_symdiff(<set1>, <set2>)



=item * Set::Object::symmetric_difference (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);



=item * Set::Scalar::symmetric_difference (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);



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

Benchmark with C<< bencher -m Array::Set::symdiff --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       251 |      3.98 |                 0.00% |               568.62% | 3.4e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |       290 |      3.4  |                15.41% |               479.32% | 4.5e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |       290 |      3.4  |                15.75% |               477.64% | 7.2e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |       290 |      3.4  |                17.31% |               469.96% | 3.6e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |       750 |      1.3  |               197.07% |               125.07% | 3.1e-06 |      20 |
 | Set::Object::symmetric_difference | 0.02   |       760 |      1.3  |               204.06% |               119.90% | 2.2e-06 |      20 |
 | Set::Object::symmetric_difference | 0.05   |       770 |      1.3  |               208.14% |               116.99% | 2.5e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1610 |      0.62 |               542.47% |                 4.07% | 4.3e-07 |      20 |
 | Array::Set::set_symdiff           | 0.063  |      1700 |      0.6  |               568.62% |                 0.00% | 2.2e-06 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                       Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             251/s                       --                               -14%                               -14%                               -14%                               -67%                               -67%                               -67%                     -84%                     -84% 
  Set::Scalar::symmetric_difference   290/s                      17%                                 --                                 0%                                 0%                               -61%                               -61%                               -61%                     -81%                     -82% 
  Set::Scalar::symmetric_difference   290/s                      17%                                 0%                                 --                                 0%                               -61%                               -61%                               -61%                     -81%                     -82% 
  Set::Scalar::symmetric_difference   290/s                      17%                                 0%                                 0%                                 --                               -61%                               -61%                               -61%                     -81%                     -82% 
  Set::Object::symmetric_difference   750/s                     206%                               161%                               161%                               161%                                 --                                 0%                                 0%                     -52%                     -53% 
  Set::Object::symmetric_difference   760/s                     206%                               161%                               161%                               161%                                 0%                                 --                                 0%                     -52%                     -53% 
  Set::Object::symmetric_difference   770/s                     206%                               161%                               161%                               161%                                 0%                                 0%                                 --                     -52%                     -53% 
  Array::Set::set_symdiff            1610/s                     541%                               448%                               448%                               448%                               109%                               109%                               109%                       --                      -3% 
  Array::Set::set_symdiff            1700/s                     563%                               466%                               466%                               466%                               116%                               116%                               116%                       3%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table2#
 {dataset=>"1000_10"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       248 |      4.03 |                 0.00% |               565.42% | 1.8e-06 |      21 |
 | Set::Scalar::symmetric_difference | 0.02   |       280 |      3.6  |                13.34% |               487.11% | 1.7e-05 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |       290 |      3.5  |                16.04% |               473.46% | 7.1e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |       290 |      3.4  |                17.60% |               465.86% | 3.8e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |       737 |      1.36 |               197.07% |               124.00% | 6.4e-07 |      20 |
 | Set::Object::symmetric_difference | 0.02   |       740 |      1.4  |               197.67% |               123.54% | 3.1e-06 |      21 |
 | Set::Object::symmetric_difference | 0.05   |       750 |      1.3  |               200.24% |               121.63% | 4.5e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1600 |      0.63 |               541.24% |                 3.77% | 1.2e-06 |      20 |
 | Array::Set::set_symdiff           | 0.063  |      1700 |      0.61 |               565.42% |                 0.00% | 1.5e-06 |      21 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                       Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             248/s                       --                               -10%                               -13%                               -15%                               -65%                               -66%                               -67%                     -84%                     -84% 
  Set::Scalar::symmetric_difference   280/s                      11%                                 --                                -2%                                -5%                               -61%                               -62%                               -63%                     -82%                     -83% 
  Set::Scalar::symmetric_difference   290/s                      15%                                 2%                                 --                                -2%                               -60%                               -61%                               -62%                     -82%                     -82% 
  Set::Scalar::symmetric_difference   290/s                      18%                                 5%                                 2%                                 --                               -58%                               -60%                               -61%                     -81%                     -82% 
  Set::Object::symmetric_difference   740/s                     187%                               157%                               150%                               142%                                 --                                -2%                                -7%                     -55%                     -56% 
  Set::Object::symmetric_difference   737/s                     196%                               164%                               157%                               149%                                 2%                                 --                                -4%                     -53%                     -55% 
  Set::Object::symmetric_difference   750/s                     210%                               176%                               169%                               161%                                 7%                                 4%                                 --                     -51%                     -53% 
  Array::Set::set_symdiff            1600/s                     539%                               471%                               455%                               439%                               122%                               115%                               106%                       --                      -3% 
  Array::Set::set_symdiff            1700/s                     560%                               490%                               473%                               457%                               129%                               122%                               113%                       3%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.05 participant=Set::Scalar::symmetric_difference

 #table3#
 {dataset=>"1000_100"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       223 |      4.49 |                 0.00% |               595.32% | 4.3e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |       265 |      3.77 |                19.12% |               483.73% | 2.9e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |       270 |      3.8  |                19.46% |               482.07% | 8.3e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |       270 |      3.7  |                19.94% |               479.71% |   6e-06 |      20 |
 | Set::Object::symmetric_difference | 0.02   |       660 |      1.5  |               197.16% |               133.99% | 4.3e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |       660 |      1.5  |               198.49% |               132.94% | 2.4e-06 |      20 |
 | Set::Object::symmetric_difference | 0.05   |       680 |      1.5  |               205.03% |               127.95% |   4e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1500 |      0.68 |               563.94% |                 4.73% | 1.3e-06 |      20 |
 | Array::Set::set_symdiff           | 0.063  |      1500 |      0.65 |               595.32% |                 0.00% | 1.6e-06 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                       Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             223/s                       --                               -15%                               -16%                               -17%                               -66%                               -66%                               -66%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   270/s                      18%                                 --                                 0%                                -2%                               -60%                               -60%                               -60%                     -82%                     -82% 
  Set::Scalar::symmetric_difference   265/s                      19%                                 0%                                 --                                -1%                               -60%                               -60%                               -60%                     -81%                     -82% 
  Set::Scalar::symmetric_difference   270/s                      21%                                 2%                                 1%                                 --                               -59%                               -59%                               -59%                     -81%                     -82% 
  Set::Object::symmetric_difference   660/s                     199%                               153%                               151%                               146%                                 --                                 0%                                 0%                     -54%                     -56% 
  Set::Object::symmetric_difference   660/s                     199%                               153%                               151%                               146%                                 0%                                 --                                 0%                     -54%                     -56% 
  Set::Object::symmetric_difference   680/s                     199%                               153%                               151%                               146%                                 0%                                 0%                                 --                     -54%                     -56% 
  Array::Set::set_symdiff            1500/s                     560%                               458%                               454%                               444%                               120%                               120%                               120%                       --                      -4% 
  Array::Set::set_symdiff            1500/s                     590%                               484%                               480%                               469%                               130%                               130%                               130%                       4%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table4#
 {dataset=>"1000_1000"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       120 |      8.3  |                 0.00% |               899.05% | 1.3e-05 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |       170 |      5.7  |                45.01% |               588.94% |   1e-05 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |       180 |      5.6  |                46.89% |               580.14% | 7.1e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |       180 |      5.56 |                49.10% |               570.04% | 5.1e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |       580 |      1.7  |               382.01% |               107.27% | 2.7e-06 |      20 |
 | Set::Object::symmetric_difference | 0.02   |       580 |      1.7  |               385.09% |               105.95% |   4e-06 |      20 |
 | Set::Object::symmetric_difference | 0.05   |       596 |      1.68 |               394.70% |               101.95% | 1.3e-06 |      20 |
 | Array::Set::set_symdiff           | 0.063  |      1100 |      0.88 |               839.85% |                 6.30% | 1.8e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1200 |      0.83 |               899.05% |                 0.00% |   8e-07 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                       Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             120/s                       --                               -31%                               -32%                               -33%                               -79%                               -79%                               -79%                     -89%                     -90% 
  Set::Scalar::symmetric_difference   170/s                      45%                                 --                                -1%                                -2%                               -70%                               -70%                               -70%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   180/s                      48%                                 1%                                 --                                 0%                               -69%                               -69%                               -70%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   180/s                      49%                                 2%                                 0%                                 --                               -69%                               -69%                               -69%                     -84%                     -85% 
  Set::Object::symmetric_difference   580/s                     388%                               235%                               229%                               227%                                 --                                 0%                                -1%                     -48%                     -51% 
  Set::Object::symmetric_difference   580/s                     388%                               235%                               229%                               227%                                 0%                                 --                                -1%                     -48%                     -51% 
  Set::Object::symmetric_difference   596/s                     394%                               239%                               233%                               230%                                 1%                                 1%                                 --                     -47%                     -50% 
  Array::Set::set_symdiff            1100/s                     843%                               547%                               536%                               531%                                93%                                93%                                90%                       --                      -5% 
  Array::Set::set_symdiff            1200/s                     900%                               586%                               574%                               569%                               104%                               104%                               102%                       6%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.05 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.05 participant=Set::Scalar::symmetric_difference

 #table5#
 {dataset=>"100_1"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |      2400 |     410   |                 0.00% |               595.63% | 6.4e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |      2500 |     400   |                 2.91% |               575.93% | 4.3e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |      2500 |     400   |                 3.38% |               572.90% |   2e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |      2600 |     390   |                 5.13% |               561.71% | 1.8e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |      6600 |     150   |               173.34% |               154.50% | 5.8e-07 |      24 |
 | Set::Object::symmetric_difference | 0.02   |      6800 |     150   |               181.11% |               147.46% | 9.1e-07 |      20 |
 | Set::Object::symmetric_difference | 0.05   |      7000 |     140   |               188.67% |               140.98% | 9.1e-07 |      20 |
 | Array::Set::set_symdiff           | 0.05   |     16300 |      61.3 |               571.77% |                 3.55% | 2.7e-08 |      20 |
 | Array::Set::set_symdiff           | 0.063  |     17000 |      59   |               595.63% |                 0.00% | 1.1e-07 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                        Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             2400/s                       --                                -2%                                -2%                                -4%                               -63%                               -63%                               -65%                     -85%                     -85% 
  Set::Scalar::symmetric_difference   2500/s                       2%                                 --                                 0%                                -2%                               -62%                               -62%                               -65%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   2500/s                       2%                                 0%                                 --                                -2%                               -62%                               -62%                               -65%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   2600/s                       5%                                 2%                                 2%                                 --                               -61%                               -61%                               -64%                     -84%                     -84% 
  Set::Object::symmetric_difference   6600/s                     173%                               166%                               166%                               160%                                 --                                 0%                                -6%                     -59%                     -60% 
  Set::Object::symmetric_difference   6800/s                     173%                               166%                               166%                               160%                                 0%                                 --                                -6%                     -59%                     -60% 
  Set::Object::symmetric_difference   7000/s                     192%                               185%                               185%                               178%                                 7%                                 7%                                 --                     -56%                     -57% 
  Array::Set::set_symdiff            16300/s                     568%                               552%                               552%                               536%                               144%                               144%                               128%                       --                      -3% 
  Array::Set::set_symdiff            17000/s                     594%                               577%                               577%                               561%                               154%                               154%                               137%                       3%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table6#
 {dataset=>"100_10"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |      2200 |       460 |                 0.00% |               624.88% | 8.5e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |      2300 |       430 |                 7.45% |               574.60% | 9.1e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |      2400 |       420 |                 7.77% |               572.62% | 1.1e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |      2400 |       420 |                 8.41% |               568.66% | 8.5e-07 |      23 |
 | Set::Object::symmetric_difference | 0.02   |      5000 |       200 |               107.70% |               249.00% | 1.1e-05 |      35 |
 | Set::Object::symmetric_difference | 0.063  |      6300 |       160 |               186.90% |               152.66% | 2.1e-07 |      20 |
 | Set::Object::symmetric_difference | 0.05   |      6400 |       160 |               193.00% |               147.40% | 4.3e-07 |      20 |
 | Array::Set::set_symdiff           | 0.05   |     16000 |        65 |               610.03% |                 2.09% | 1.1e-07 |      20 |
 | Array::Set::set_symdiff           | 0.063  |     16000 |        63 |               624.88% |                 0.00% |   8e-08 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                        Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             2200/s                       --                                -6%                                -8%                                -8%                               -56%                               -65%                               -65%                     -85%                     -86% 
  Set::Scalar::symmetric_difference   2300/s                       6%                                 --                                -2%                                -2%                               -53%                               -62%                               -62%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   2400/s                       9%                                 2%                                 --                                 0%                               -52%                               -61%                               -61%                     -84%                     -85% 
  Set::Scalar::symmetric_difference   2400/s                       9%                                 2%                                 0%                                 --                               -52%                               -61%                               -61%                     -84%                     -85% 
  Set::Object::symmetric_difference   5000/s                     129%                               114%                               110%                               110%                                 --                               -19%                               -19%                     -67%                     -68% 
  Set::Object::symmetric_difference   6300/s                     187%                               168%                               162%                               162%                                25%                                 --                                 0%                     -59%                     -60% 
  Set::Object::symmetric_difference   6400/s                     187%                               168%                               162%                               162%                                25%                                 0%                                 --                     -59%                     -60% 
  Array::Set::set_symdiff            16000/s                     607%                               561%                               546%                               546%                               207%                               146%                               146%                       --                      -3% 
  Array::Set::set_symdiff            16000/s                     630%                               582%                               566%                               566%                               217%                               153%                               153%                       3%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table7#
 {dataset=>"100_100"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |      1210 |     824   |                 0.00% |               919.91% | 6.1e-07 |      22 |
 | Set::Scalar::symmetric_difference | 0.05   |      1600 |     620   |                32.06% |               672.29% | 1.3e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |      1620 |     618   |                33.33% |               664.95% | 6.1e-07 |      22 |
 | Set::Scalar::symmetric_difference | 0.063  |      1640 |     609   |                35.32% |               653.70% | 4.3e-07 |      20 |
 | Set::Object::symmetric_difference | 0.02   |      3100 |     320   |               155.85% |               298.64% | 8.8e-07 |      21 |
 | Set::Object::symmetric_difference | 0.063  |      5900 |     170   |               384.79% |               110.38% | 2.1e-07 |      20 |
 | Set::Object::symmetric_difference | 0.05   |      6000 |     170   |               393.89% |               106.51% | 2.5e-07 |      22 |
 | Array::Set::set_symdiff           | 0.05   |     12200 |      82.2 |               902.10% |                 1.78% | 2.6e-08 |      21 |
 | Array::Set::set_symdiff           | 0.063  |     12400 |      80.8 |               919.91% |                 0.00% | 2.5e-08 |      22 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                        Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff             1210/s                       --                               -24%                               -25%                               -26%                               -61%                               -79%                               -79%                     -90%                     -90% 
  Set::Scalar::symmetric_difference   1600/s                      32%                                 --                                 0%                                -1%                               -48%                               -72%                               -72%                     -86%                     -86% 
  Set::Scalar::symmetric_difference   1620/s                      33%                                 0%                                 --                                -1%                               -48%                               -72%                               -72%                     -86%                     -86% 
  Set::Scalar::symmetric_difference   1640/s                      35%                                 1%                                 1%                                 --                               -47%                               -72%                               -72%                     -86%                     -86% 
  Set::Object::symmetric_difference   3100/s                     157%                                93%                                93%                                90%                                 --                               -46%                               -46%                     -74%                     -74% 
  Set::Object::symmetric_difference   5900/s                     384%                               264%                               263%                               258%                                88%                                 --                                 0%                     -51%                     -52% 
  Set::Object::symmetric_difference   6000/s                     384%                               264%                               263%                               258%                                88%                                 0%                                 --                     -51%                     -52% 
  Array::Set::set_symdiff            12200/s                     902%                               654%                               651%                               640%                               289%                               106%                               106%                       --                      -1% 
  Array::Set::set_symdiff            12400/s                     919%                               667%                               664%                               653%                               296%                               110%                               110%                       1%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table8#
 {dataset=>"10_1"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::symmetric_difference | 0.063  |     12000 |      80   |                 0.00% |               737.55% | 2.1e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |     13000 |      80   |                 0.68% |               731.87% |   1e-07 |      21 |
 | Set::Scalar::symmetric_difference | 0.05   |     13000 |      79   |                 1.62% |               724.19% | 1.1e-07 |      20 |
 | Array::Set::set_symdiff           | 0.02   |     20000 |      51   |                57.56% |               431.58% | 6.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.063  |     45000 |      22   |               259.82% |               132.77% | 5.2e-08 |      21 |
 | Set::Object::symmetric_difference | 0.02   |     46000 |      22   |               269.17% |               126.88% | 2.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.05   |     46100 |      21.7 |               270.57% |               126.02% | 6.7e-09 |      20 |
 | Array::Set::set_symdiff           | 0.05   |     95900 |      10.4 |               671.70% |                 8.53% | 3.3e-09 |      20 |
 | Array::Set::set_symdiff           | 0.063  |    100000 |       9.6 |               737.55% |                 0.00% | 1.3e-08 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                         Rate  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Array::Set::set_symdiff  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Set::Scalar::symmetric_difference   12000/s                                 --                                 0%                                -1%                     -36%                               -72%                               -72%                               -72%                     -87%                     -88% 
  Set::Scalar::symmetric_difference   13000/s                                 0%                                 --                                -1%                     -36%                               -72%                               -72%                               -72%                     -87%                     -88% 
  Set::Scalar::symmetric_difference   13000/s                                 1%                                 1%                                 --                     -35%                               -72%                               -72%                               -72%                     -86%                     -87% 
  Array::Set::set_symdiff             20000/s                                56%                                56%                                54%                       --                               -56%                               -56%                               -57%                     -79%                     -81% 
  Set::Object::symmetric_difference   45000/s                               263%                               263%                               259%                     131%                                 --                                 0%                                -1%                     -52%                     -56% 
  Set::Object::symmetric_difference   46000/s                               263%                               263%                               259%                     131%                                 0%                                 --                                -1%                     -52%                     -56% 
  Set::Object::symmetric_difference   46100/s                               268%                               268%                               264%                     135%                                 1%                                 1%                                 --                     -52%                     -55% 
  Array::Set::set_symdiff             95900/s                               669%                               669%                               659%                     390%                               111%                               111%                               108%                       --                      -7% 
  Array::Set::set_symdiff            100000/s                               733%                               733%                               722%                     431%                               129%                               129%                               126%                       8%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.05 participant=Set::Scalar::symmetric_difference

 #table9#
 {dataset=>"10_10"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |    7000   |  200      |                 0.00% |              1101.35% | 6.5e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |   10000   |   99      |                51.89% |               690.93% | 1.1e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |   10000   |  100      |                54.71% |               676.50% | 1.2e-06 |      20 |
 | Set::Scalar::symmetric_difference | 0.063  |   10000   |   96      |                56.43% |               668.00% | 2.1e-07 |      21 |
 | Set::Object::symmetric_difference | 0.063  |   40000   |   25      |               502.68% |                99.33% | 2.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.02   |   40000   |   25      |               506.34% |                98.13% | 2.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.05   |   41000   |   25      |               511.28% |                96.53% | 2.7e-08 |      20 |
 | Array::Set::set_symdiff           | 0.063  |   79900   |   12.5    |              1099.08% |                 0.19% | 3.8e-09 |      21 |
 | Array::Set::set_symdiff           | 0.05   |   80045.4 |   12.4929 |              1101.35% |                 0.00% | 1.2e-11 |      20 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                          Rate  Array::Set::set_symdiff  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Array::Set::set_symdiff               7000/s                       --                               -50%                               -50%                               -52%                               -87%                               -87%                               -87%                     -93%                     -93% 
  Set::Scalar::symmetric_difference    10000/s                     100%                                 --                                -1%                                -4%                               -75%                               -75%                               -75%                     -87%                     -87% 
  Set::Scalar::symmetric_difference    10000/s                     102%                                 1%                                 --                                -3%                               -74%                               -74%                               -74%                     -87%                     -87% 
  Set::Scalar::symmetric_difference    10000/s                     108%                                 4%                                 3%                                 --                               -73%                               -73%                               -73%                     -86%                     -86% 
  Set::Object::symmetric_difference    40000/s                     700%                               300%                               296%                               284%                                 --                                 0%                                 0%                     -50%                     -50% 
  Set::Object::symmetric_difference    40000/s                     700%                               300%                               296%                               284%                                 0%                                 --                                 0%                     -50%                     -50% 
  Set::Object::symmetric_difference    41000/s                     700%                               300%                               296%                               284%                                 0%                                 0%                                 --                     -50%                     -50% 
  Array::Set::set_symdiff              79900/s                    1500%                               700%                               692%                               668%                               100%                               100%                               100%                       --                       0% 
  Array::Set::set_symdiff            80045.4/s                    1500%                               700%                               692%                               668%                               100%                               100%                               100%                       0%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.05 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.063 participant=Set::Scalar::symmetric_difference

 #table10#
 {dataset=>"10_5"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::symmetric_difference | 0.063  |     11000 |        87 |                 0.00% |               648.21% | 2.3e-07 |      21 |
 | Set::Scalar::symmetric_difference | 0.02   |     12000 |        86 |                 1.74% |               635.41% | 1.1e-07 |      20 |
 | Set::Scalar::symmetric_difference | 0.05   |     12000 |        85 |                 2.66% |               628.83% | 1.1e-07 |      20 |
 | Array::Set::set_symdiff           | 0.02   |     10000 |        70 |                23.63% |               505.20% | 1.2e-06 |      20 |
 | Set::Object::symmetric_difference | 0.063  |     42000 |        24 |               261.64% |               106.89% | 2.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.05   |     40000 |        20 |               276.94% |                98.49% | 2.5e-07 |      21 |
 | Set::Object::symmetric_difference | 0.02   |     44000 |        23 |               283.73% |                94.98% | 2.7e-08 |      20 |
 | Array::Set::set_symdiff           | 0.05   |     83000 |        12 |               618.69% |                 4.11% | 8.3e-08 |      20 |
 | Array::Set::set_symdiff           | 0.063  |     90000 |        10 |               648.21% |                 0.00% | 1.4e-07 |      21 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                        Rate  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Array::Set::set_symdiff  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Set::Scalar::symmetric_difference  11000/s                                 --                                -1%                                -2%                     -19%                               -72%                               -73%                               -77%                     -86%                     -88% 
  Set::Scalar::symmetric_difference  12000/s                                 1%                                 --                                -1%                     -18%                               -72%                               -73%                               -76%                     -86%                     -88% 
  Set::Scalar::symmetric_difference  12000/s                                 2%                                 1%                                 --                     -17%                               -71%                               -72%                               -76%                     -85%                     -88% 
  Array::Set::set_symdiff            10000/s                                24%                                22%                                21%                       --                               -65%                               -67%                               -71%                     -82%                     -85% 
  Set::Object::symmetric_difference  42000/s                               262%                               258%                               254%                     191%                                 --                                -4%                               -16%                     -50%                     -58% 
  Set::Object::symmetric_difference  44000/s                               278%                               273%                               269%                     204%                                 4%                                 --                               -13%                     -47%                     -56% 
  Set::Object::symmetric_difference  40000/s                               334%                               330%                               325%                     250%                                19%                                14%                                 --                     -40%                     -50% 
  Array::Set::set_symdiff            83000/s                               625%                               616%                               608%                     483%                               100%                                91%                                66%                       --                     -16% 
  Array::Set::set_symdiff            90000/s                               769%                               760%                               750%                     600%                               140%                               129%                               100%                      19%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.05 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.05 participant=Set::Scalar::symmetric_difference

 #table11#
 {dataset=>"1_1"}
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Set::Scalar::symmetric_difference | 0.05   |   20000   |   50      |                 0.00% |              1899.07% |   6e-07 |      21 |
 | Set::Scalar::symmetric_difference | 0.063  |   21000   |   48      |                 0.30% |              1893.13% | 5.3e-08 |      20 |
 | Set::Scalar::symmetric_difference | 0.02   |   21000   |   48      |                 0.37% |              1891.73% | 5.3e-08 |      20 |
 | Array::Set::set_symdiff           | 0.02   |   70000   |   14      |               238.00% |               491.44% | 2.7e-08 |      20 |
 | Set::Object::symmetric_difference | 0.05   |   93481.7 |   10.6973 |               354.55% |               339.79% |   0     |      20 |
 | Set::Object::symmetric_difference | 0.063  |   95500   |   10.5    |               364.38% |               330.48% |   1e-08 |      20 |
 | Set::Object::symmetric_difference | 0.02   |   96600   |   10.3    |               369.91% |               325.42% | 3.3e-09 |      20 |
 | Array::Set::set_symdiff           | 0.05   |  200000   |    5      |               872.52% |               105.56% | 1.7e-09 |      20 |
 | Array::Set::set_symdiff           | 0.063  |  410000   |    2.4    |              1899.07% |                 0.00% | 3.3e-09 |      21 |
 +-----------------------------------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                          Rate  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Set::Scalar::symmetric_difference  Array::Set::set_symdiff  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Set::Object::symmetric_difference  Array::Set::set_symdiff  Array::Set::set_symdiff 
  Set::Scalar::symmetric_difference    20000/s                                 --                                -4%                                -4%                     -72%                               -78%                               -79%                               -79%                     -90%                     -95% 
  Set::Scalar::symmetric_difference    21000/s                                 4%                                 --                                 0%                     -70%                               -77%                               -78%                               -78%                     -89%                     -95% 
  Set::Scalar::symmetric_difference    21000/s                                 4%                                 0%                                 --                     -70%                               -77%                               -78%                               -78%                     -89%                     -95% 
  Array::Set::set_symdiff              70000/s                               257%                               242%                               242%                       --                               -23%                               -25%                               -26%                     -64%                     -82% 
  Set::Object::symmetric_difference  93481.7/s                               367%                               348%                               348%                      30%                                 --                                -1%                                -3%                     -53%                     -77% 
  Set::Object::symmetric_difference    95500/s                               376%                               357%                               357%                      33%                                 1%                                 --                                -1%                     -52%                     -77% 
  Set::Object::symmetric_difference    96600/s                               385%                               366%                               366%                      35%                                 3%                                 1%                                 --                     -51%                     -76% 
  Array::Set::set_symdiff             200000/s                               900%                               860%                               860%                     179%                               113%                               110%                               106%                       --                     -52% 
  Array::Set::set_symdiff             410000/s                              1983%                              1900%                              1900%                     483%                               345%                               337%                               329%                     108%                       -- 
 
 Legends:
   Array::Set::set_symdiff: modver=0.063 participant=Array::Set::set_symdiff
   Set::Object::symmetric_difference: modver=0.02 participant=Set::Object::symmetric_difference
   Set::Scalar::symmetric_difference: modver=0.02 participant=Set::Scalar::symmetric_difference


Benchmark module startup overhead (C<< bencher -m Array::Set::symdiff --module-startup >>):

 #table12#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Set::Object         |      25   |              15.2 |                 0.00% |               160.46% | 3.9e-05 |      20 |
 | Set::Scalar         |      22.3 |              12.5 |                14.01% |               128.45% |   2e-05 |      20 |
 | Array::Set          |      16   |               6.2 |                62.82% |                59.97% | 1.6e-05 |      20 |
 | perl -e1 (baseline) |       9.8 |               0   |               160.46% |                 0.00% | 3.2e-05 |      22 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   S:O   S:S   A:S  perl -e1 (baseline) 
  S:O                   40.0/s    --  -10%  -36%                 -60% 
  S:S                   44.8/s   12%    --  -28%                 -56% 
  A:S                   62.5/s   56%   39%    --                 -38% 
  perl -e1 (baseline)  102.0/s  155%  127%   63%                   -- 
 
 Legends:
   A:S: mod_overhead_time=6.2 participant=Array::Set
   S:O: mod_overhead_time=15.2 participant=Set::Object
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
