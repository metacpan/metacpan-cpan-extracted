package Bencher::Scenario::ListFlatten;

our $DATE = '2018-01-21'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various List::Flatten implementaitons',
    participants => [
        {
            fcall_template => 'List::Flatten::flat(@{<data>})',
            result_is_list => 1,
        },
        {
            fcall_template => 'List::Flatten::XS::flatten(<data>)',
        },
        {
            fcall_template => 'List::Flat::flat(@{<data>})',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name => '10_1_1', args => {data=>[1, 2, 3, 4, [5], 6, 7, 8, 9, 10]}},
        {name => '10_10_1', args => {data=>[[1], [2], [3], [4], [5], [6], [7], [8], [9], [10]]}},
        {name => '10_1_10', args => {data=>[1, 2, 3, 4, [5, 2..10], 6, 7, 8, 9, 10]}},
        {name => '10_1_100', args => {data=>[1, 2, 3, 4, [5, 2..100], 6, 7, 8, 9, 10]}},

        {name => '100_1_1', args => {data=>[1..49, [50], 51..100]}},

        {name => '1000_1_1', args => {data=>[1..499, [500], 501..1000]}},
    ],
};

1;
# ABSTRACT: Benchmark various List::Flatten implementaitons

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListFlatten - Benchmark various List::Flatten implementaitons

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ListFlatten (from Perl distribution Bencher-Scenario-ListFlatten), released on 2018-01-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListFlatten

To run module startup overhead benchmark:

 % bencher --module-startup -m ListFlatten

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::Flatten> 0.01

L<List::Flatten::XS> 0.04

L<List::Flat> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::Flatten::flat (perl_code)

Function call template:

 List::Flatten::flat(@{<data>})



=item * List::Flatten::XS::flatten (perl_code)

Function call template:

 List::Flatten::XS::flatten(<data>)



=item * List::Flat::flat (perl_code)

Function call template:

 List::Flat::flat(@{<data>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 10_1_1

=item * 10_10_1

=item * 10_1_10

=item * 10_1_100

=item * 100_1_1

=item * 1000_1_1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m ListFlatten >>):

 #table1#
 +----------------------------+----------+-----------+------------+------------+---------+---------+
 | participant                | dataset  | rate (/s) | time (μs)  | vs_slowest |  errors | samples |
 +----------------------------+----------+-----------+------------+------------+---------+---------+
 | List::Flat::flat           | 1000_1_1 |      6500 | 154        |     1      | 4.8e-08 |      25 |
 | List::Flatten::flat        | 1000_1_1 |     18000 |  56        |     2.7    | 1.1e-07 |      20 |
 | List::Flatten::XS::flatten | 1000_1_1 |     20000 |  49        |     3.1    |   1e-07 |      21 |
 | List::Flat::flat           | 10_1_100 |     40500 |  24.7      |     6.23   |   2e-08 |      21 |
 | List::Flat::flat           | 100_1_1  |     56000 |  18        |     8.6    | 2.7e-08 |      20 |
 | List::Flat::flat           | 10_10_1  |    132999 |   7.51885  |    20.4616 |   0     |      20 |
 | List::Flatten::XS::flatten | 100_1_1  |    140000 |   7.1      |    22      | 2.7e-08 |      20 |
 | List::Flatten::XS::flatten | 10_1_100 |    150000 |   6.6      |    23      |   1e-08 |      20 |
 | List::Flatten::flat        | 100_1_1  |    168000 |   5.96     |    25.8    | 1.7e-09 |      20 |
 | List::Flat::flat           | 10_1_10  |    182000 |   5.5      |    28      |   5e-09 |      20 |
 | List::Flat::flat           | 10_1_1   |    340000 |   3        |    52      | 3.3e-09 |      20 |
 | List::Flatten::flat        | 10_1_100 |    375000 |   2.67     |    57.6    | 8.3e-10 |      20 |
 | List::Flatten::XS::flatten | 10_10_1  |    390000 |   2.56     |    60      | 2.5e-09 |      20 |
 | List::Flatten::flat        | 10_10_1  |    487152 |   2.05275  |    74.9472 |   0     |      20 |
 | List::Flatten::XS::flatten | 10_1_10  |    520000 |   1.9      |    79      | 1.1e-08 |      20 |
 | List::Flatten::XS::flatten | 10_1_1   |    770000 |   1.3      |   120      | 3.7e-09 |      20 |
 | List::Flatten::flat        | 10_1_10  |    856000 |   1.17     |   132      | 3.3e-10 |      31 |
 | List::Flatten::flat        | 10_1_1   |   1025140 |   0.975481 |   157.715  |   0     |      20 |
 +----------------------------+----------+-----------+------------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ListFlatten --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | List::Flatten       | 0.961                        | 4.39               | 18.3           |      9.79 |                   3.29 |       1    | 8.5e-06 |      20 |
 | List::Flat          | 0.82                         | 4.16               | 16.1           |      9.74 |                   3.24 |       1    | 2.5e-06 |      20 |
 | List::Flatten::XS   | 1.05                         | 4.45               | 18.3           |      9.06 |                   2.56 |       1.08 | 6.1e-06 |      21 |
 | perl -e1 (baseline) | 1.1                          | 4.5                | 16             |      6.5  |                   0    |       1.5  | 2.3e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

In general, from the provided benchmark datasets, I don't see the advantage of
using the XS implementation.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ListFlatten>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ListFlatten>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ListFlatten>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
