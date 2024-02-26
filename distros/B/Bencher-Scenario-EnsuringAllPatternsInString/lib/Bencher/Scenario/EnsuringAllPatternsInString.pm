package Bencher::Scenario::EnsuringAllPatternsInString;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-11'; # DATE
our $DIST = 'Bencher-Scenario-EnsuringAllPatternsInString'; # DIST
our $VERSION = '0.020'; # VERSION

my @ajrand = qw(f e j b a i g d c h);
my @bjrand = qw(f e j b   i g d c h);

our $scenario = {
    summary => 'Ensuring all patterns are in a string',
    description => <<'MARKDOWN',

This scenario is inspired by <http://perlmonks.org/?node_id=1153410>. I want to
know how much faster/slower using the single regex with look-around assertions
is compared to using multiple regex.

As I expect, the single_re technique becomes exponentially slow as the number of
patterns and length of string increases.

MARKDOWN
    participants => [
        {
            name => 'single_re',
            summary => 'Uses look-around assertions',
            code_template => <<'MARKDOWN',
state $re = do {
    my $re = join "", map {"(?=.*?".quotemeta($_).")"} @{<patterns>};
    qr/$re/;
};
<string> =~ $re;
MARKDOWN
        },
        {
            name => 'multiple_re',
            code_template => <<'MARKDOWN',
state $re = [map {my $re=quotemeta; qr/$re/} @{<patterns>}];
for (@$re) { return 0 unless <string> =~ $_ }
1;
MARKDOWN
        },
    ],
    datasets => [
        {
            name => 'dataset',
            args => {
                'patterns@' => {
                    '2short'  => ['a','b'],
                    '5short'  => ['a'..'e'],
                    '10short' => ['a'..'j'],
                    '2long'   => [map {$_ x 20} 'a','b'],
                    '5long'   => [map {$_ x 20} 'a'..'e'],
                    '10long'  => [map {$_ x 20} 'a'..'j'],
                },
                'string@' => {
                    'match_short'    => join("", map {$_ x 20} @ajrand),
                    'match_medium'   => join("", map {$_ x 200} @ajrand),
                    'match_long'     => join("", map {$_ x 2000} @ajrand),
                    'nomatch_short'  => join("", map {$_ x 20} @bjrand),
                    'nomatch_medium' => join("", map {$_ x 200} @bjrand),
                    'nomatch_long'   => join("", map {$_ x 2000} @bjrand),
                },
            },
        },
    ],
};

1;
# ABSTRACT: Ensuring all patterns are in a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::EnsuringAllPatternsInString - Ensuring all patterns are in a string

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::EnsuringAllPatternsInString (from Perl distribution Bencher-Scenario-EnsuringAllPatternsInString), released on 2024-02-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m EnsuringAllPatternsInString

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

This scenario is inspired by L<http://perlmonks.org/?node_id=1153410>. I want to
know how much faster/slower using the single regex with look-around assertions
is compared to using multiple regex.

As I expect, the single_re technique becomes exponentially slow as the number of
patterns and length of string increases.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * single_re (perl_code)

Uses look-around assertions.

Code template:

 state $re = do {
     my $re = join "", map {"(?=.*?".quotemeta($_).")"} @{<patterns>};
     qr/$re/;
 };
 <string> =~ $re;




=item * multiple_re (perl_code)

Code template:

 state $re = [map {my $re=quotemeta; qr/$re/} @{<patterns>}];
 for (@$re) { return 0 unless <string> =~ $_ }
 1;




=back

=head1 BENCHMARK DATASETS

=over

=item * dataset

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m EnsuringAllPatternsInString

Result formatted as table (split, part 1 of 36):

 #table1#
 {arg_patterns=>"10long",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    215000 |      4.65 |                 0.00% |                68.39% | 1.2e-09 |      20 |
 | single_re   |    362000 |      2.76 |                68.39% |                 0.00% | 7.8e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  215000/s           --       -40% 
  single_re    362000/s          68%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 2 of 36):

 #table2#
 {arg_patterns=>"10long",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    259000 |      3.86 |                 0.00% |               206.06% | 9.1e-10 |      20 |
 | single_re   |    793000 |      1.26 |               206.06% |                 0.00% | 1.9e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  259000/s           --       -67% 
  single_re    793000/s         206%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 3 of 36):

 #table3#
 {arg_patterns=>"10long",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    272000 |      3.68 |                 0.00% |               229.65% | 1.2e-09 |      20 |
 | single_re   |    896000 |      1.12 |               229.65% |                 0.00% |   2e-10 |      21 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  272000/s           --       -69% 
  single_re    896000/s         228%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 4 of 36):

 #table4#
 {arg_patterns=>"10long",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       370 |  2.7      |                 0.00% |            584746.14% | 8.6e-07 |      20 |
 | multiple_re |   2160000 |  0.000462 |            584746.14% |                 0.00% | 1.5e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        370/s         --         -99% 
  multiple_re  2160000/s    584315%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 5 of 36):

 #table5#
 {arg_patterns=>"10long",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6500 |     150   |                 0.00% |             51472.02% | 1.7e-07 |      20 |
 | multiple_re |   3330000 |       0.3 |             51472.02% |                 0.00% | 8.2e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6500/s         --         -99% 
  multiple_re  3330000/s     49900%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 6 of 36):

 #table6#
 {arg_patterns=>"10long",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68500 |    14.6   |                 0.00% |              5084.37% | 5.7e-09 |      23 |
 | multiple_re |   3550000 |     0.282 |              5084.37% |                 0.00% | 5.3e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68500/s         --         -98% 
  multiple_re  3550000/s      5077%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 7 of 36):

 #table7#
 {arg_patterns=>"10short",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    280000 |      3.57 |                 0.00% |                30.70% |   7e-10 |      20 |
 | single_re   |    366000 |      2.73 |                30.70% |                 0.00% | 5.9e-10 |      21 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  280000/s           --       -23% 
  single_re    366000/s          30%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 8 of 36):

 #table8#
 {arg_patterns=>"10short",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    358000 |      2.79 |                 0.00% |               127.02% | 5.4e-10 |      23 |
 | single_re   |    813000 |      1.23 |               127.02% |                 0.00% | 2.5e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  358000/s           --       -55% 
  single_re    813000/s         126%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 9 of 36):

 #table9#
 {arg_patterns=>"10short",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    365000 |      2.74 |                 0.00% |               147.68% | 6.8e-10 |      20 |
 | single_re   |    903000 |      1.11 |               147.68% |                 0.00% | 5.9e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  365000/s           --       -59% 
  single_re    903000/s         146%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 10 of 36):

 #table10#
 {arg_patterns=>"10short",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       368 |  2.72     |                 0.00% |            606634.60% | 7.7e-07 |      20 |
 | multiple_re |   2230000 |  0.000448 |            606634.60% |                 0.00% | 1.9e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        368/s         --         -99% 
  multiple_re  2230000/s    607042%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 11 of 36):

 #table11#
 {arg_patterns=>"10short",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6480 |   154     |                 0.00% |             52891.17% | 4.3e-08 |      20 |
 | multiple_re |   3430000 |     0.291 |             52891.17% |                 0.00% | 9.8e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6480/s         --         -99% 
  multiple_re  3430000/s     52820%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 12 of 36):

 #table12#
 {arg_patterns=>"10short",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68200 |    14.7   |                 0.00% |              5219.14% | 5.2e-09 |      20 |
 | multiple_re |   3630000 |     0.276 |              5219.14% |                 0.00% | 6.1e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68200/s         --         -98% 
  multiple_re  3630000/s      5226%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 13 of 36):

 #table13#
 {arg_patterns=>"2long",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1040000 |       964 |                 0.00% |                36.82% | 3.9e-10 |      20 |
 | single_re   |   1420000 |       704 |                36.82% |                 0.00% |   1e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1040000/s           --       -26% 
  single_re    1420000/s          36%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 14 of 36):

 #table14#
 {arg_patterns=>"2long",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1150000 |       867 |                 0.00% |                72.16% | 5.1e-10 |      20 |
 | single_re   |   1990000 |       504 |                72.16% |                 0.00% | 8.6e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1150000/s           --       -41% 
  single_re    1990000/s          72%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 15 of 36):

 #table15#
 {arg_patterns=>"2long",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1110000 |       900 |                 0.00% |                85.34% | 3.5e-10 |      20 |
 | single_re   |   2060000 |       486 |                85.34% |                 0.00% | 7.3e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1110000/s           --       -46% 
  single_re    2060000/s          85%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 16 of 36):

 #table16#
 {arg_patterns=>"2long",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       371 |  2.69     |                 0.00% |            595832.38% | 4.1e-07 |      20 |
 | multiple_re |   2210000 |  0.000452 |            595832.38% |                 0.00% | 8.9e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        371/s         --         -99% 
  multiple_re  2210000/s    595032%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 17 of 36):

 #table17#
 {arg_patterns=>"2long",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6430 |   155     |                 0.00% |             51894.39% | 3.5e-08 |      20 |
 | multiple_re |   3340000 |     0.299 |             51894.39% |                 0.00% | 1.1e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6430/s         --         -99% 
  multiple_re  3340000/s     51739%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 18 of 36):

 #table18#
 {arg_patterns=>"2long",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68400 |    14.6   |                 0.00% |              5093.95% | 6.1e-09 |      21 |
 | multiple_re |   3550000 |     0.282 |              5093.95% |                 0.00% | 5.1e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68400/s         --         -98% 
  multiple_re  3550000/s      5077%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 19 of 36):

 #table19#
 {arg_patterns=>"2short",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1400000 |       714 |                 0.00% |                 3.65% | 1.1e-10 |      20 |
 | single_re   |   1450000 |       689 |                 3.65% |                 0.00% | 1.1e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1400000/s           --        -3% 
  single_re    1450000/s           3%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 20 of 36):

 #table20#
 {arg_patterns=>"2short",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1600000 |       620 |                 0.00% |                25.29% | 6.7e-10 |      21 |
 | single_re   |   2020000 |       494 |                25.29% |                 0.00% | 9.7e-11 |      21 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1600000/s           --       -20% 
  single_re    2020000/s          25%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 21 of 36):

 #table21#
 {arg_patterns=>"2short",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |   1680000 |       593 |                 0.00% |                24.41% | 2.4e-10 |      20 |
 | single_re   |   2100000 |       477 |                24.41% |                 0.00% | 1.2e-10 |      21 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re  1680000/s           --       -19% 
  single_re    2100000/s          24%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 22 of 36):

 #table22#
 {arg_patterns=>"2short",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       370 |  2.7      |                 0.00% |            612968.99% | 1.5e-06 |      20 |
 | multiple_re |   2270000 |  0.000441 |            612968.99% |                 0.00% |   2e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        370/s         --         -99% 
  multiple_re  2270000/s    612144%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 23 of 36):

 #table23#
 {arg_patterns=>"2short",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6480 |   154     |                 0.00% |             52889.61% | 4.5e-08 |      21 |
 | multiple_re |   3430000 |     0.291 |             52889.61% |                 0.00% | 4.3e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6480/s         --         -99% 
  multiple_re  3430000/s     52820%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 24 of 36):

 #table24#
 {arg_patterns=>"2short",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68100 |    14.7   |                 0.00% |              5225.33% |   5e-09 |      20 |
 | multiple_re |   3630000 |     0.276 |              5225.33% |                 0.00% | 5.6e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68100/s         --         -98% 
  multiple_re  3630000/s      5226%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 25 of 36):

 #table25#
 {arg_patterns=>"5long",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    418000 |      2.39 |                 0.00% |                48.44% | 1.1e-09 |      20 |
 | single_re   |    620000 |      1.61 |                48.44% |                 0.00% | 4.6e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  418000/s           --       -32% 
  single_re    620000/s          48%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 26 of 36):

 #table26#
 {arg_patterns=>"5long",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    488000 |    2.05   |                 0.00% |               156.06% |   5e-10 |      20 |
 | single_re   |   1251000 |    0.7997 |               156.06% |                 0.00% | 6.8e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re   488000/s           --       -60% 
  single_re    1251000/s         156%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 27 of 36):

 #table27#
 {arg_patterns=>"5long",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    509000 |     1.97  |                 0.00% |               178.69% | 6.5e-10 |      20 |
 | single_re   |   1420000 |     0.706 |               178.69% |                 0.00% | 1.6e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re   509000/s           --       -64% 
  single_re    1420000/s         179%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 28 of 36):

 #table28#
 {arg_patterns=>"5long",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       370 |  2.71     |                 0.00% |            597003.41% | 1.4e-06 |      21 |
 | multiple_re |   2210000 |  0.000453 |            597003.41% |                 0.00% | 2.6e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        370/s         --         -99% 
  multiple_re  2210000/s    598133%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 29 of 36):

 #table29#
 {arg_patterns=>"5long",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6470 |   154     |                 0.00% |             51673.97% |   7e-08 |      20 |
 | multiple_re |   3350000 |     0.298 |             51673.97% |                 0.00% | 4.4e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6470/s         --         -99% 
  multiple_re  3350000/s     51577%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 30 of 36):

 #table30#
 {arg_patterns=>"5long",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68500 |    14.6   |                 0.00% |              5078.94% | 8.3e-09 |      20 |
 | multiple_re |   3550000 |     0.282 |              5078.94% |                 0.00% | 7.2e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68500/s         --         -98% 
  multiple_re  3550000/s      5077%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 31 of 36):

 #table31#
 {arg_patterns=>"5short",arg_string=>"match_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    550000 |      1.82 |                 0.00% |                16.65% | 5.2e-10 |      20 |
 | single_re   |    642000 |      1.56 |                16.65% |                 0.00% | 6.2e-10 |      22 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                   Rate  multiple_re  single_re 
  multiple_re  550000/s           --       -14% 
  single_re    642000/s          16%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 32 of 36):

 #table32#
 {arg_patterns=>"5short",arg_string=>"match_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    697000 |      1430 |                 0.00% |                85.83% | 1.5e-10 |      20 |
 | single_re   |   1300000 |       772 |                85.83% |                 0.00% | 1.9e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re   697000/s           --       -46% 
  single_re    1300000/s          85%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 33 of 36):

 #table33#
 {arg_patterns=>"5short",arg_string=>"match_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | multiple_re |    719000 |      1390 |                 0.00% |               103.21% | 4.4e-10 |      20 |
 | single_re   |   1460000 |       684 |               103.21% |                 0.00% | 1.3e-10 |      21 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  multiple_re  single_re 
  multiple_re   719000/s           --       -50% 
  single_re    1460000/s         103%         -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 34 of 36):

 #table34#
 {arg_patterns=>"5short",arg_string=>"nomatch_long"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |       369 |  2.71     |                 0.00% |            606400.48% | 3.7e-07 |      20 |
 | multiple_re |   2240000 |  0.000446 |            606400.48% |                 0.00% | 2.4e-10 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re        369/s         --         -99% 
  multiple_re  2240000/s    607523%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 35 of 36):

 #table35#
 {arg_patterns=>"5short",arg_string=>"nomatch_medium"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |      6400 |   160     |                 0.00% |             53604.41% | 2.3e-07 |      20 |
 | multiple_re |   3430000 |     0.292 |             53604.41% |                 0.00% | 5.5e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re       6400/s         --         -99% 
  multiple_re  3430000/s     54694%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re

Result formatted as table (split, part 36 of 36):

 #table36#
 {arg_patterns=>"5short",arg_string=>"nomatch_short"}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | single_re   |     68600 |    14.6   |                 0.00% |              5190.03% | 3.2e-09 |      20 |
 | multiple_re |   3630000 |     0.276 |              5190.03% |                 0.00% | 6.4e-11 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  single_re  multiple_re 
  single_re      68600/s         --         -98% 
  multiple_re  3630000/s      5189%           -- 
 
 Legends:
   multiple_re: participant=multiple_re
   single_re: participant=single_re


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-EnsuringAllPatternsInString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-EnsuringAllPatternsInString>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-EnsuringAllPatternsInString>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
