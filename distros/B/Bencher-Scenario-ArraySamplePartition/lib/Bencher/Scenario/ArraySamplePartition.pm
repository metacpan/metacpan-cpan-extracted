package Bencher::Scenario::ArraySamplePartition;

our $DATE = '2017-07-23'; # DATE
our $VERSION = '0.001'; # VERSION

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

This document describes version 0.001 of Bencher::Scenario::ArraySamplePartition (from Perl distribution Bencher-Scenario-ArraySamplePartition), released on 2017-07-23.

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m ArraySamplePartition >>):

 #table1#
 +----------+------------+-----------+------------+---------+---------+
 | dataset  | rate (/s)  | time (μs) | vs_slowest |  errors | samples |
 +----------+------------+-----------+------------+---------+---------+
 | 500/1000 |    8195.54 | 122.018   |    1       |   0     |      20 |
 | 100/1000 |   27000    |  37       |    3.3     | 5.3e-08 |      20 |
 | 10/1000  |   56000    |  18       |    6.8     | 3.3e-08 |      20 |
 | 1/1000   |   61000    |  16       |    7.4     |   2e-08 |      20 |
 | 50/100   |   77844.2  |  12.8462  |    9.49836 |   0     |      38 |
 | 10/100   |  240000    |   4.2     |   29       | 6.7e-09 |      20 |
 | 1/100    |  469700    |   2.129   |   57.31    | 4.6e-11 |      29 |
 | 5/10     |  547890    |   1.82518 |   66.8523  |   0     |      20 |
 | 1/10     | 1200000    |   0.87    |  140       | 1.7e-09 |      20 |
 +----------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ArraySamplePartition --module-startup >>):

 #table2#
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant              | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Array::Sample::Partition | 836                          | 4.1                | 20             |       5.1 |                    2.3 |        1   | 3.9e-05 |      20 |
 | perl -e1 (baseline)      | 936                          | 4.2                | 20             |       2.8 |                    0   |        1.8 | 7.8e-06 |      20 |
 +--------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
