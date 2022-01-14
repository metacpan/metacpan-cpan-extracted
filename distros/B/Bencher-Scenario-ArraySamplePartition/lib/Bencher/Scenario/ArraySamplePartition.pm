package Bencher::Scenario::ArraySamplePartition;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Array::Sample::Partition hash',
    participants => [
        {
            fcall_template => 'Array::Sample::Partition::sample_partition(<array>, <n>)',
        },
    ],
    datasets => [
        {name=>'1/10'    , args=>{array=>[1..10]  , n=>1}},
        {name=>'5/10'    , args=>{array=>[1..10]  , n=>5}},
        {name=>'1/100'   , args=>{array=>[1..100] , n=>1}},
        {name=>'10/100'  , args=>{array=>[1..100] , n=>10}},
        {name=>'50/100'  , args=>{array=>[1..100] , n=>50}},
        {name=>'1/1000'  , args=>{array=>[1..1000], n=>1}},
        {name=>'10/1000' , args=>{array=>[1..1000], n=>10}},
        {name=>'100/1000', args=>{array=>[1..1000], n=>100}},
        {name=>'500/1000', args=>{array=>[1..1000], n=>500}},
    ],
};

1;
# ABSTRACT: Benchmark Array::Sample::Partition hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySamplePartition - Benchmark Array::Sample::Partition hash

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ArraySamplePartition (from Perl distribution Bencher-Scenario-ArraySamplePartition), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySamplePartition

To run module startup overhead benchmark:

 % bencher --module-startup -m ArraySamplePartition

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Sample::Partition> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Sample::Partition::sample_partition (perl_code)

Function call template:

 Array::Sample::Partition::sample_partition(<array>, <n>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1/10

=item * 5/10

=item * 1/100

=item * 10/100

=item * 50/100

=item * 1/1000

=item * 10/1000

=item * 100/1000

=item * 500/1000

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m ArraySamplePartition

Result formatted as table:

 #table1#
 | dataset  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |----------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | 500/1000 |    8650   |  116      |                 0.00% |             14836.87% | 5.3e-08 |      20 |
 | 100/1000 |   28900   |   34.6    |               234.18% |              4369.68% |   1e-08 |      34 |
 | 10/1000  |   61200   |   16.3    |               607.56% |              2011.04% | 6.5e-09 |      21 |
 | 1/1000   |   68900   |   14.5    |               695.89% |              1776.76% | 5.6e-09 |      28 |
 | 50/100   |   83954.7 |   11.9112 |               870.43% |              1439.20% | 5.8e-12 |      26 |
 | 10/100   |  257240   |    3.8874 |              2873.47% |               402.34% | 5.8e-12 |      20 |
 | 1/100    |  492000   |    2.03   |              5590.87% |               162.47% | 8.3e-10 |      20 |
 | 5/10     |  620000   |    1.6    |              7061.39% |               108.58% | 3.3e-09 |      20 |
 | 1/10     | 1300000   |    0.77   |             14836.87% |                 0.00% | 1.2e-09 |      21 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                 Rate  500/1000  100/1000  10/1000  1/1000  50/100  10/100  1/100  5/10  1/10 
  500/1000     8650/s        --      -70%     -85%    -87%    -89%    -96%   -98%  -98%  -99% 
  100/1000    28900/s      235%        --     -52%    -58%    -65%    -88%   -94%  -95%  -97% 
  10/1000     61200/s      611%      112%       --    -11%    -26%    -76%   -87%  -90%  -95% 
  1/1000      68900/s      700%      138%      12%      --    -17%    -73%   -86%  -88%  -94% 
  50/100    83954.7/s      873%      190%      36%     21%      --    -67%   -82%  -86%  -93% 
  10/100     257240/s     2883%      790%     319%    272%    206%      --   -47%  -58%  -80% 
  1/100      492000/s     5614%     1604%     702%    614%    486%     91%     --  -21%  -62% 
  5/10       620000/s     7150%     2062%     918%    806%    644%    142%    26%    --  -51% 
  1/10      1300000/s    14964%     4393%    2016%   1783%   1446%    404%   163%  107%    -- 
 
 Legends:
   1/10: dataset=1/10
   1/100: dataset=1/100
   1/1000: dataset=1/1000
   10/100: dataset=10/100
   10/1000: dataset=10/1000
   100/1000: dataset=100/1000
   5/10: dataset=5/10
   50/100: dataset=50/100
   500/1000: dataset=500/1000

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m ArraySamplePartition --module-startup

Result formatted as table:

 #table2#
 | participant              | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------|
 | Array::Sample::Partition |         7 |                 3 |                 0.00% |                64.41% | 0.00025 |      21 |
 | perl -e1 (baseline)      |         4 |                 0 |                64.41% |                 0.00% | 0.00014 |      27 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  AS:P  perl -e1 (baseline) 
  AS:P                 142.9/s    --                 -42% 
  perl -e1 (baseline)  250.0/s   75%                   -- 
 
 Legends:
   AS:P: mod_overhead_time=3 participant=Array::Sample::Partition
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (on pc-home)

perlancar (on pc-home) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ArraySamplePartition>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ArraySamplePartition>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ArraySamplePartition>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
