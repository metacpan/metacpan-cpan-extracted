package Bencher::Scenario::StringFunctions::Trim;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-30'; # DATE
our $DIST = 'Bencher-Scenarios-StringFunctions'; # DIST
our $VERSION = '0.004'; # VERSION

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

This document describes version 0.004 of Bencher::Scenario::StringFunctions::Trim (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-07-30.

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

L<String::Trim::NonRegex> 0.002

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::Trim >>):

 #table1#
 {dataset=>"empty"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Util::trim           |   1777940 |   562.449 |                 0.00% |               460.90% |   0     |      20 |
 | String::Trim::NonRegex::trim |   1969350 |   507.781 |                10.77% |               406.38% |   0     |      20 |
 | String::Trim::More::trim     |   7200000 |   140     |               303.11% |                39.14% | 2.1e-10 |      20 |
 | String::Trim::Regex::trim    |   8525000 |   117.3   |               379.51% |                16.97% | 5.8e-12 |      20 |
 | Text::Minify::XS::minify     |  10000000 |   100     |               460.90% |                 0.00% | 1.5e-10 |      21 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

               Rate  SU:t  STN:t  STM:t  STR:t  TMX:m 
  SU:t    1777940/s    --    -9%   -75%   -79%   -82% 
  STN:t   1969350/s   10%     --   -72%   -76%   -80% 
  STM:t   7200000/s  301%   262%     --   -16%   -28% 
  STR:t   8525000/s  379%   332%    19%     --   -14% 
  TMX:m  10000000/s  462%   407%    39%    17%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table2#
 {dataset=>"len1000ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   19816.9 |   50.4621 |                 0.00% |              6175.56% |   0     |      21 |
 | String::Util::trim           |   26170.2 |   38.2114 |                32.06% |              4652.04% | 5.8e-12 |      20 |
 | String::Trim::More::trim     |  459000   |    2.18   |              2217.43% |               170.80% | 7.6e-10 |      24 |
 | Text::Minify::XS::minify     |  514760   |    1.9427 |              2497.59% |               141.59% | 5.8e-12 |      20 |
 | String::Trim::NonRegex::trim | 1200000   |    0.8    |              6175.56% |                 0.00% | 1.4e-09 |      27 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t   SU:t  STM:t  TMX:m  STN:t 
  STR:t  19816.9/s     --   -24%   -95%   -96%   -98% 
  SU:t   26170.2/s    32%     --   -94%   -94%   -97% 
  STM:t   459000/s  2214%  1652%     --   -10%   -63% 
  TMX:m   514760/s  2497%  1866%    12%     --   -58% 
  STN:t  1200000/s  6207%  4676%   172%   142%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table3#
 {dataset=>"len1000ws10"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   19824.7 |  50.4422  |                 0.00% |              2433.81% |   0     |      20 |
 | String::Util::trim           |   26162.1 |  38.2233  |                31.97% |              1820.03% | 5.8e-12 |      20 |
 | String::Trim::NonRegex::trim |  367320   |   2.7224  |              1752.85% |                36.75% |   2e-11 |      23 |
 | String::Trim::More::trim     |  473249   |   2.11305 |              2287.17% |                 6.14% |   0     |      23 |
 | Text::Minify::XS::minify     |  502320   |   1.9908  |              2433.81% |                 0.00% | 5.8e-12 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t   SU:t  STN:t  STM:t  TMX:m 
  STR:t  19824.7/s     --   -24%   -94%   -95%   -96% 
  SU:t   26162.1/s    31%     --   -92%   -94%   -94% 
  STN:t   367320/s  1752%  1304%     --   -22%   -26% 
  STM:t   473249/s  2287%  1708%    28%     --    -5% 
  TMX:m   502320/s  2433%  1819%    36%     6%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table4#
 {dataset=>"len1000ws100"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |   19896.3 |   50.2606 |                 0.00% |              2182.66% | 5.5e-12 |      20 |
 | String::Util::trim           |   26000   |   38      |                31.05% |              1641.82% | 4.3e-08 |      31 |
 | String::Trim::NonRegex::trim |   46200   |   21.6    |               132.24% |               882.89% | 6.7e-09 |      20 |
 | Text::Minify::XS::minify     |  441000   |    2.27   |              2116.06% |                 3.01% | 8.1e-10 |      21 |
 | String::Trim::More::trim     |  450000   |    2.2    |              2182.66% |                 0.00% | 3.3e-09 |      21 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t   SU:t  STN:t  TMX:m  STM:t 
  STR:t  19896.3/s     --   -24%   -57%   -95%   -95% 
  SU:t     26000/s    32%     --   -43%   -94%   -94% 
  STN:t    46200/s   132%    75%     --   -89%   -89% 
  TMX:m   441000/s  2114%  1574%   851%     --    -3% 
  STM:t   450000/s  2184%  1627%   881%     3%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table5#
 {dataset=>"len1000ws1000"}
 +------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s)  | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::NonRegex::trim |   4761.814 | 210.004   |                 0.00% |              7113.61% | 5.6e-12 |      20 |
 | String::Trim::Regex::trim    |  20000     |  51       |               309.53% |              1661.42% | 9.2e-08 |      27 |
 | String::Util::trim           |  25328.7   |  39.4809  |               431.91% |              1256.16% | 5.8e-12 |      20 |
 | Text::Minify::XS::minify     | 206970     |   4.83163 |              4246.44% |                65.97% |   0     |      20 |
 | String::Trim::More::trim     | 343500     |   2.9112  |              7113.61% |                 0.00% | 5.8e-12 |      20 |
 +------------------------------+------------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

               Rate  STN:t  STR:t   SU:t  TMX:m  STM:t 
  STN:t  4761.814/s     --   -75%   -81%   -97%   -98% 
  STR:t     20000/s   311%     --   -22%   -90%   -94% 
  SU:t    25328.7/s   431%    29%     --   -87%   -92% 
  TMX:m    206970/s  4246%   955%   717%     --   -39% 
  STM:t    343500/s  7113%  1651%  1256%    65%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table6#
 {dataset=>"len100ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |    181000 |   5.54    |                 0.00% |              1763.47% | 1.6e-09 |      22 |
 | String::Util::trim           |    223500 |   4.4743  |                23.71% |              1406.31% | 5.7e-12 |      36 |
 | String::Trim::More::trim     |   1190500 |   0.83998 |               558.97% |               182.78% | 5.8e-12 |      20 |
 | String::Trim::NonRegex::trim |   1300000 |   0.772   |               616.99% |               159.90% | 4.2e-10 |      20 |
 | Text::Minify::XS::minify     |   3367000 |   0.297   |              1763.47% |                 0.00% | 5.8e-12 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t   SU:t  STM:t  STN:t  TMX:m 
  STR:t   181000/s     --   -19%   -84%   -86%   -94% 
  SU:t    223500/s    23%     --   -81%   -82%   -93% 
  STM:t  1190500/s   559%   432%     --    -8%   -64% 
  STN:t  1300000/s   617%   479%     8%     --   -61% 
  TMX:m  3367000/s  1765%  1406%   182%   159%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table7#
 {dataset=>"len100ws10"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |    181000 |    5.54   |                 0.00% |              1567.74% | 4.7e-09 |      23 |
 | String::Util::trim           |    223540 |    4.4735 |                23.80% |              1247.12% | 2.3e-11 |      22 |
 | String::Trim::NonRegex::trim |    367440 |    2.7215 |               103.50% |               719.54% |   2e-11 |      20 |
 | String::Trim::More::trim     |   1223400 |    0.8174 |               577.55% |               146.14% | 5.8e-12 |      23 |
 | Text::Minify::XS::minify     |   3010000 |    0.332  |              1567.74% |                 0.00% | 3.1e-10 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t   SU:t  STN:t  STM:t  TMX:m 
  STR:t   181000/s     --   -19%   -50%   -85%   -94% 
  SU:t    223540/s    23%     --   -39%   -81%   -92% 
  STN:t   367440/s   103%    64%     --   -69%   -87% 
  STM:t  1223400/s   577%   447%   232%     --   -59% 
  TMX:m  3010000/s  1568%  1247%   719%   146%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table8#
 {dataset=>"len100ws100"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::NonRegex::trim |     46200 | 21.6      |                 0.00% |              3519.03% | 5.4e-09 |      30 |
 | String::Trim::Regex::trim    |    177300 |  5.64     |               283.62% |               843.39% | 5.7e-12 |      20 |
 | String::Util::trim           |    216740 |  4.6138   |               368.95% |               671.73% | 2.3e-11 |      20 |
 | String::Trim::More::trim     |   1031900 |  0.96908  |              2132.66% |                62.09% | 5.6e-12 |      21 |
 | Text::Minify::XS::minify     |   1672670 |  0.597848 |              3519.03% |                 0.00% |   0     |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STN:t  STR:t  SU:t  STM:t  TMX:m 
  STN:t    46200/s     --   -73%  -78%   -95%   -97% 
  STR:t   177300/s   282%     --  -18%   -82%   -89% 
  SU:t    216740/s   368%    22%    --   -78%   -87% 
  STM:t  1031900/s  2128%   481%  376%     --   -38% 
  TMX:m  1672670/s  3512%   843%  671%    62%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify

 #table9#
 {dataset=>"len10ws1"}
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::Trim::Regex::trim    |    965665 |   1035.56 |                 0.00% |               737.52% |   0     |      20 |
 | String::Util::trim           |    974424 |   1026.25 |                 0.91% |               730.00% |   0     |      20 |
 | String::Trim::NonRegex::trim |   1287400 |    776.76 |                33.32% |               528.22% | 5.7e-12 |      20 |
 | String::Trim::More::trim     |   1590000 |    630    |                64.40% |               409.45% | 2.1e-10 |      20 |
 | Text::Minify::XS::minify     |   8100000 |    120    |               737.52% |                 0.00% | 1.8e-10 |      27 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

              Rate  STR:t  SU:t  STN:t  STM:t  TMX:m 
  STR:t   965665/s     --    0%   -24%   -39%   -88% 
  SU:t    974424/s     0%    --   -24%   -38%   -88% 
  STN:t  1287400/s    33%   32%     --   -18%   -84% 
  STM:t  1590000/s    64%   62%    23%     --   -80% 
  TMX:m  8100000/s   762%  755%   547%   425%     -- 
 
 Legends:
   STM:t: participant=String::Trim::More::trim
   STN:t: participant=String::Trim::NonRegex::trim
   STR:t: participant=String::Trim::Regex::trim
   SU:t: participant=String::Util::trim
   TMX:m: participant=Text::Minify::XS::minify


Benchmark module startup overhead (C<< bencher -m StringFunctions::Trim --module-startup >>):

 #table10#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | String::Util           |        10 |                 6 |                 0.00% |               219.35% |   0.0003  |      20 |
 | String::Trim::Regex    |         9 |                 5 |                35.00% |               136.55% |   0.00018 |      20 |
 | Text::Minify::XS       |         8 |                 4 |                53.13% |               108.54% |   0.00013 |      20 |
 | String::Trim::NonRegex |         7 |                 3 |                67.35% |                90.83% | 9.9e-05   |      20 |
 | String::Trim::More     |         7 |                 3 |                72.79% |                84.82% |   0.00032 |      20 |
 | perl -e1 (baseline)    |         4 |                 0 |               219.35% |                 0.00% |   0.00014 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                Rate   S:U  ST:R  TM:X  ST:N  ST:M  :perl -e1 ( 
  S:U          0.1/s    --   -9%  -19%  -30%  -30%         -60% 
  ST:R         0.1/s   11%    --  -11%  -22%  -22%         -55% 
  TM:X         0.1/s   25%   12%    --  -12%  -12%         -50% 
  ST:N         0.1/s   42%   28%   14%    --    0%         -42% 
  ST:M         0.1/s   42%   28%   14%    0%    --         -42% 
  :perl -e1 (  0.2/s  150%  125%  100%   75%   75%           -- 
 
 Legends:
   :perl -e1 (: mod_overhead_time=0 participant=perl -e1 (baseline)
   S:U: mod_overhead_time=6 participant=String::Util
   ST:M: mod_overhead_time=3 participant=String::Trim::More
   ST:N: mod_overhead_time=3 participant=String::Trim::NonRegex
   ST:R: mod_overhead_time=5 participant=String::Trim::Regex
   TM:X: mod_overhead_time=4 participant=Text::Minify::XS

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
