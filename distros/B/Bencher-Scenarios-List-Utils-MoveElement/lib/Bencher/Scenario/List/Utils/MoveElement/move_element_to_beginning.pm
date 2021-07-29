package Bencher::Scenario::List::Utils::MoveElement::move_element_to_beginning;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Bencher-Scenarios-List-Utils-MoveElement'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark move_to_beginning()",
    participants => [
        {fcall_template=>'List::Utils::MoveElement::move_element_to_beginning(<i>, @{<array>})', result_is_list=>1},
        {fcall_template=>'List::Utils::MoveElement::PP::to_beginning(<i>, @{<array>})', result_is_list=>1},
        {fcall_template=>'List::Utils::MoveElement::Splice::to_beginning_copy(<i>, @{<array>})', result_is_list=>1},
        {fcall_template=>'List::Utils::MoveElement::Splice::to_beginning_nocopy(<i>, @{<array>})', result_is_list=>1},
    ],
    datasets => [
        {name=>'a1_1'       , args=>{i=>1, array=>[qw/a b/]}, result=>[qw/b a/]},
        {name=>'a5_10'      , args=>{i=>5, array=>[(('a') x 5), 'b', (('a') x 4)]}, result=>['b', (('a') x 9)]},
        {name=>'a500_1000'  , args=>{i=>500, array=>[(('a') x 500), 'b', (('a') x 499)]}, result=>['b', (('a') x 999)]},
        {name=>'a5000_10000', args=>{i=>5000, array=>[(('a') x 5000), 'b', (('a') x 4999)]}, result=>['b', (('a') x 9999)]},
    ],
};

1;
# ABSTRACT: Benchmark move_to_beginning()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::List::Utils::MoveElement::move_element_to_beginning - Benchmark move_to_beginning()

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::List::Utils::MoveElement::move_element_to_beginning (from Perl distribution Bencher-Scenarios-List-Utils-MoveElement), released on 2021-07-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m List::Utils::MoveElement::move_element_to_beginning

To run module startup overhead benchmark:

 % bencher --module-startup -m List::Utils::MoveElement::move_element_to_beginning

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::Utils::MoveElement> 0.02

L<List::Utils::MoveElement::PP>

L<List::Utils::MoveElement::Splice>

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::Utils::MoveElement::move_element_to_beginning (perl_code)

Function call template:

 List::Utils::MoveElement::move_element_to_beginning(<i>, @{<array>})



=item * List::Utils::MoveElement::PP::to_beginning (perl_code)

Function call template:

 List::Utils::MoveElement::PP::to_beginning(<i>, @{<array>})



=item * List::Utils::MoveElement::Splice::to_beginning_copy (perl_code)

Function call template:

 List::Utils::MoveElement::Splice::to_beginning_copy(<i>, @{<array>})



=item * List::Utils::MoveElement::Splice::to_beginning_nocopy (perl_code)

Function call template:

 List::Utils::MoveElement::Splice::to_beginning_nocopy(<i>, @{<array>})



=back

=head1 BENCHMARK DATASETS

=over

=item * a1_1

=item * a5_10

=item * a500_1000

=item * a5000_10000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m List::Utils::MoveElement::move_element_to_beginning >>):

 #table1#
 +-------------------------------------------------------+-------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                           | dataset     | rate (/s)  | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------------------------+-------------+------------+-----------+-----------------------+-----------------------+---------+---------+
 | List::Utils::MoveElement::PP::to_beginning            | a5000_10000 |    1050    | 956       |                 0.00% |            180333.55% | 1.6e-07 |      20 |
 | List::Utils::MoveElement::move_element_to_beginning   | a5000_10000 |    1050    | 955       |                 0.09% |            180164.76% | 2.1e-07 |      20 |
 | List::Utils::MoveElement::Splice::to_beginning_copy   | a5000_10000 |    1231    | 812.5     |                17.62% |            153310.15% | 4.5e-08 |      28 |
 | List::Utils::MoveElement::Splice::to_beginning_nocopy | a5000_10000 |    2280    | 439       |               117.57% |             82831.54% | 4.7e-08 |      26 |
 | List::Utils::MoveElement::move_element_to_beginning   | a500_1000   |   10400    |  96.1     |               894.62% |             18040.98% | 2.1e-08 |      32 |
 | List::Utils::MoveElement::PP::to_beginning            | a500_1000   |   10425.3  |  95.9204  |               896.24% |             18011.43% | 1.6e-11 |      20 |
 | List::Utils::MoveElement::Splice::to_beginning_copy   | a500_1000   |   12269.75 |  81.50123 |              1072.50% |             15288.85% | 5.4e-12 |      23 |
 | List::Utils::MoveElement::Splice::to_beginning_nocopy | a500_1000   |   20500    |  48.8     |              1856.65% |              9121.53% | 1.3e-08 |      21 |
 | List::Utils::MoveElement::Splice::to_beginning_nocopy | a5_10       |  160320    |   6.2377  |             15219.68% |              1077.79% | 1.7e-11 |      20 |
 | List::Utils::MoveElement::Splice::to_beginning_nocopy | a1_1        |  170000    |   5.88    |             16148.19% |              1010.48% | 1.3e-09 |      32 |
 | List::Utils::MoveElement::PP::to_beginning            | a5_10       |  743000    |   1.35    |             70887.68% |               154.18% | 4.2e-10 |      20 |
 | List::Utils::MoveElement::move_element_to_beginning   | a5_10       |  749830    |   1.3336  |             71553.16% |               151.82% | 5.6e-12 |      21 |
 | List::Utils::MoveElement::Splice::to_beginning_copy   | a5_10       |  828680    |   1.2067  |             79088.58% |               127.85% | 5.5e-12 |      20 |
 | List::Utils::MoveElement::Splice::to_beginning_copy   | a1_1        | 1900000    |   0.53    |            179509.88% |                 0.46% | 6.2e-10 |      20 |
 | List::Utils::MoveElement::PP::to_beginning            | a1_1        | 1882000    |   0.5314  |            179715.00% |                 0.34% | 1.6e-11 |      20 |
 | List::Utils::MoveElement::move_element_to_beginning   | a1_1        | 1900000    |   0.53    |            180333.55% |                 0.00% | 8.1e-10 |      21 |
 +-------------------------------------------------------+-------------+------------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                 Rate  LUMP:t_b a5000_10000  LUM:m_e_t_b a5000_10000  LUMS:t_b_c a5000_10000  LUMS:t_b_n a5000_10000  LUM:m_e_t_b a500_1000  LUMP:t_b a500_1000  LUMS:t_b_c a500_1000  LUMS:t_b_n a500_1000  LUMS:t_b_n a5_10  LUMS:t_b_n a1_1  LUMP:t_b a5_10  LUM:m_e_t_b a5_10  LUMS:t_b_c a5_10  LUMP:t_b a1_1  LUMS:t_b_c a1_1  LUM:m_e_t_b a1_1 
  LUMP:t_b a5000_10000         1050/s                    --                       0%                    -15%                    -54%                   -89%                -89%                  -91%                  -94%              -99%             -99%            -99%               -99%              -99%           -99%             -99%              -99% 
  LUM:m_e_t_b a5000_10000      1050/s                    0%                       --                    -14%                    -54%                   -89%                -89%                  -91%                  -94%              -99%             -99%            -99%               -99%              -99%           -99%             -99%              -99% 
  LUMS:t_b_c a5000_10000       1231/s                   17%                      17%                      --                    -45%                   -88%                -88%                  -89%                  -93%              -99%             -99%            -99%               -99%              -99%           -99%             -99%              -99% 
  LUMS:t_b_n a5000_10000       2280/s                  117%                     117%                     85%                      --                   -78%                -78%                  -81%                  -88%              -98%             -98%            -99%               -99%              -99%           -99%             -99%              -99% 
  LUM:m_e_t_b a500_1000       10400/s                  894%                     893%                    745%                    356%                     --                  0%                  -15%                  -49%              -93%             -93%            -98%               -98%              -98%           -99%             -99%              -99% 
  LUMP:t_b a500_1000        10425.3/s                  896%                     895%                    747%                    357%                     0%                  --                  -15%                  -49%              -93%             -93%            -98%               -98%              -98%           -99%             -99%              -99% 
  LUMS:t_b_c a500_1000     12269.75/s                 1072%                    1071%                    896%                    438%                    17%                 17%                    --                  -40%              -92%             -92%            -98%               -98%              -98%           -99%             -99%              -99% 
  LUMS:t_b_n a500_1000        20500/s                 1859%                    1856%                   1564%                    799%                    96%                 96%                   67%                    --              -87%             -87%            -97%               -97%              -97%           -98%             -98%              -98% 
  LUMS:t_b_n a5_10           160320/s                15226%                   15210%                  12925%                   6937%                  1440%               1437%                 1206%                  682%                --              -5%            -78%               -78%              -80%           -91%             -91%              -91% 
  LUMS:t_b_n a1_1            170000/s                16158%                   16141%                  13718%                   7365%                  1534%               1531%                 1286%                  729%                6%               --            -77%               -77%              -79%           -90%             -90%              -90% 
  LUMP:t_b a5_10             743000/s                70714%                   70640%                  60085%                  32418%                  7018%               7005%                 5937%                 3514%              362%             335%              --                -1%              -10%           -60%             -60%              -60% 
  LUM:m_e_t_b a5_10          749830/s                71585%                   71510%                  60825%                  32818%                  7106%               7092%                 6011%                 3559%              367%             340%              1%                 --               -9%           -60%             -60%              -60% 
  LUMS:t_b_c a5_10           828680/s                79124%                   79041%                  67232%                  36280%                  7863%               7848%                 6654%                 3944%              416%             387%             11%                10%                --           -55%             -56%              -56% 
  LUMP:t_b a1_1             1882000/s               179802%                  179613%                 152798%                  82511%                 17984%              17950%                15237%                 9083%             1073%            1006%            154%               150%              127%             --               0%                0% 
  LUMS:t_b_c a1_1           1900000/s               180277%                  180088%                 153201%                  82730%                 18032%              17998%                15277%                 9107%             1076%            1009%            154%               151%              127%             0%               --                0% 
  LUM:m_e_t_b a1_1          1900000/s               180277%                  180088%                 153201%                  82730%                 18032%              17998%                15277%                 9107%             1076%            1009%            154%               151%              127%             0%               0%                -- 
 
 Legends:
   LUM:m_e_t_b a1_1: dataset=a1_1 participant=List::Utils::MoveElement::move_element_to_beginning
   LUM:m_e_t_b a5000_10000: dataset=a5000_10000 participant=List::Utils::MoveElement::move_element_to_beginning
   LUM:m_e_t_b a500_1000: dataset=a500_1000 participant=List::Utils::MoveElement::move_element_to_beginning
   LUM:m_e_t_b a5_10: dataset=a5_10 participant=List::Utils::MoveElement::move_element_to_beginning
   LUMP:t_b a1_1: dataset=a1_1 participant=List::Utils::MoveElement::PP::to_beginning
   LUMP:t_b a5000_10000: dataset=a5000_10000 participant=List::Utils::MoveElement::PP::to_beginning
   LUMP:t_b a500_1000: dataset=a500_1000 participant=List::Utils::MoveElement::PP::to_beginning
   LUMP:t_b a5_10: dataset=a5_10 participant=List::Utils::MoveElement::PP::to_beginning
   LUMS:t_b_c a1_1: dataset=a1_1 participant=List::Utils::MoveElement::Splice::to_beginning_copy
   LUMS:t_b_c a5000_10000: dataset=a5000_10000 participant=List::Utils::MoveElement::Splice::to_beginning_copy
   LUMS:t_b_c a500_1000: dataset=a500_1000 participant=List::Utils::MoveElement::Splice::to_beginning_copy
   LUMS:t_b_c a5_10: dataset=a5_10 participant=List::Utils::MoveElement::Splice::to_beginning_copy
   LUMS:t_b_n a1_1: dataset=a1_1 participant=List::Utils::MoveElement::Splice::to_beginning_nocopy
   LUMS:t_b_n a5000_10000: dataset=a5000_10000 participant=List::Utils::MoveElement::Splice::to_beginning_nocopy
   LUMS:t_b_n a500_1000: dataset=a500_1000 participant=List::Utils::MoveElement::Splice::to_beginning_nocopy
   LUMS:t_b_n a5_10: dataset=a5_10 participant=List::Utils::MoveElement::Splice::to_beginning_nocopy

=begin html

<img src="data:image/png;base64,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" />

=end html


Benchmark module startup overhead (C<< bencher -m List::Utils::MoveElement::move_element_to_beginning --module-startup >>):

 #table2#
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                      | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | List::Utils::MoveElement         |      10   |               5.3 |                 0.00% |               143.56% |   0.00027 |      20 |
 | List::Utils::MoveElement::PP     |      10   |               5.3 |                17.46% |               107.35% |   0.00025 |      20 |
 | List::Utils::MoveElement::Splice |       5   |               0.3 |               114.09% |                13.77% |   0.00023 |      20 |
 | perl -e1 (baseline)              |       4.7 |               0   |               143.56% |                 0.00% | 2.4e-05   |      20 |
 +----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                Rate  LU:M  LUM:P  LUM:S  :perl -e1 ( 
  LU:M         0.1/s    --     0%   -50%         -53% 
  LUM:P        0.1/s    0%     --   -50%         -53% 
  LUM:S        0.2/s  100%   100%     --          -5% 
  :perl -e1 (  0.2/s  112%   112%     6%           -- 
 
 Legends:
   :perl -e1 (: mod_overhead_time=0 participant=perl -e1 (baseline)
   LU:M: mod_overhead_time=5.3 participant=List::Utils::MoveElement
   LUM:P: mod_overhead_time=5.3 participant=List::Utils::MoveElement::PP
   LUM:S: mod_overhead_time=0.3 participant=List::Utils::MoveElement::Splice

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Using copy+splice+unshift (L<List::Utils::MoveElement::Splice>) is faster. And
we can get significantly faster still with larger list by avoiding copying
C<@_>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-List-Utils-MoveElement>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-List-Utils-MoveElement>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-List-Utils-MoveElement>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
