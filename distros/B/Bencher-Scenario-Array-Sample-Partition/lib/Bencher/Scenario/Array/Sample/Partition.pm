package Bencher::Scenario::Array::Sample::Partition;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenario-Array-Sample-Partition'; # DIST
our $VERSION = '0.002'; # VERSION

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

Bencher::Scenario::Array::Sample::Partition - Benchmark Array::Sample::Partition hash

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Array::Sample::Partition (from Perl distribution Bencher-Scenario-Array-Sample-Partition), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Sample::Partition

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Sample::Partition

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m Array::Sample::Partition >>):

 #table1#
 +----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset  | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 500/1000 |      5200 |    190    |                 0.00% |             15337.13% | 2.7e-07 |      20 |
 | 100/1000 |     17200 |     58.3  |               228.27% |              4602.52% | 2.7e-08 |      20 |
 | 10/1000  |     35000 |     28    |               572.46% |              2195.62% | 5.3e-08 |      20 |
 | 1/1000   |     40600 |     24.6  |               677.01% |              1886.75% | 6.7e-09 |      20 |
 | 50/100   |     51000 |     20    |               869.79% |              1491.80% | 2.7e-08 |      20 |
 | 10/100   |    160000 |      6.3  |              2926.00% |               410.15% | 6.7e-09 |      20 |
 | 1/100    |    300000 |      3    |              5669.96% |               167.54% | 3.5e-08 |      20 |
 | 5/10     |    400000 |      3    |              6899.13% |               120.56% | 3.2e-08 |      20 |
 | 1/10     |    807000 |      1.24 |             15337.13% |                 0.00% | 5.6e-10 |      20 |
 +----------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                Rate  500/1000  100/1000  10/1000  1/1000  50/100  10/100  1/100  5/10  1/10 
  500/1000    5200/s        --      -69%     -85%    -87%    -89%    -96%   -98%  -98%  -99% 
  100/1000   17200/s      225%        --     -51%    -57%    -65%    -89%   -94%  -94%  -97% 
  10/1000    35000/s      578%      108%       --    -12%    -28%    -77%   -89%  -89%  -95% 
  1/1000     40600/s      672%      136%      13%      --    -18%    -74%   -87%  -87%  -94% 
  50/100     51000/s      850%      191%      39%     23%      --    -68%   -85%  -85%  -93% 
  10/100    160000/s     2915%      825%     344%    290%    217%      --   -52%  -52%  -80% 
  1/100     300000/s     6233%     1843%     833%    720%    566%    110%     --    0%  -58% 
  5/10      400000/s     6233%     1843%     833%    720%    566%    110%     0%    --  -58% 
  1/10      807000/s    15222%     4601%    2158%   1883%   1512%    408%   141%  141%    -- 
 
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

Benchmark module startup overhead (C<< bencher -m Array::Sample::Partition --module-startup >>):

 #table2#
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant              | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Array::Sample::Partition |      10   |               1.7 |                 0.00% |                51.25% |   0.00018 |      21 |
 | perl -e1 (baseline)      |       8.3 |               0   |                51.25% |                 0.00% | 6.5e-05   |      21 |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  AS:P  perl -e1 (baseline) 
  AS:P                 100.0/s    --                 -16% 
  perl -e1 (baseline)  120.5/s   20%                   -- 
 
 Legends:
   AS:P: mod_overhead_time=1.7 participant=Array::Sample::Partition
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Array-Sample-Partition>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Array-Sample-Partition>.

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

This software is copyright (c) 2021, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Array-Sample-Partition>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
