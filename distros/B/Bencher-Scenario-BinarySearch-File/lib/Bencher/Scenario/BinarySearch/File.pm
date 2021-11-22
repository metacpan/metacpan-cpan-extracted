package Bencher::Scenario::BinarySearch::File;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-21'; # DATE
our $DIST = 'Bencher-Scenario-BinarySearch-File'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempdir);
use Tie::Simple;

my $dir = tempdir(CLEANUP => !$ENV{DEBUG});
say "tempdir: $dir" if $ENV{DEBUG};

our $fh_1k_num  ; open $fh_1k_num  , ">", "$dir/1k_num"  ; for (0..       999) { print $fh_1k_num   "$_\n" } close $fh_1k_num   ; open $fh_1k_num   , "<", "$dir/1k_num";
our $fh_10k_num ; open $fh_10k_num , ">", "$dir/10k_num" ; for (0..     9_999) { print $fh_10k_num  "$_\n" } close $fh_10k_num  ; open $fh_10k_num  , "<", "$dir/10k_num";
our $fh_100k_num; open $fh_100k_num, ">", "$dir/100k_num"; for (0..    99_999) { print $fh_100k_num "$_\n" } close $fh_100k_num  ; open $fh_100k_num  , "<", "$dir/100k_num";
our $fh_1m_num  ; open $fh_1m_num  , ">", "$dir/1m_num"  ; for (0..   999_999) { print $fh_1m_num   "$_\n" } close $fh_1m_num  ; open $fh_1m_num  , "<", "$dir/1m_num";
our $fh_10m_num ; open $fh_10m_num , ">", "$dir/10m_num" ; for (0.. 9_999_999) { print $fh_10m_num  "$_\n" } close $fh_10m_num ; open $fh_10m_num , "<", "$dir/10m_num";
our $fh_100m_num; open $fh_100m_num, ">", "$dir/100m_num"; for (0..99_999_999) { print $fh_100m_num "$_\n" } close $fh_100m_num; open $fh_100m_num, "<", "$dir/100m_num";

our $scenario = {
    summary => 'Benchmark binary searching sorted lines from a file',
    participants => [
        {module=>'File::SortedSeek', name=>'File::SortedSeek-1k-num'  , code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_1k_num  , int (     1_000*rand()))'},
        {module=>'File::SortedSeek', name=>'File::SortedSeek-10k-num' , code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_10k_num , int(     10_000*rand()))'},
        {module=>'File::SortedSeek', name=>'File::SortedSeek-100k-num', code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_100k_num, int(    100_000*rand()))'},
        {module=>'File::SortedSeek', name=>'File::SortedSeek-1m-num'  , code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_1m_num  , int(  1_000_000*rand()))'},
        {module=>'File::SortedSeek', name=>'File::SortedSeek-10m-num' , code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_10m_num , int( 10_000_000*rand()))'},
        {module=>'File::SortedSeek', name=>'File::SortedSeek-100m-num', code_template=>'File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_100m_num, int(100_000_000*rand()))'},
    ],
};

1;
# ABSTRACT: Benchmark binary searching sorted lines from a file

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BinarySearch::File - Benchmark binary searching sorted lines from a file

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::BinarySearch::File (from Perl distribution Bencher-Scenario-BinarySearch-File), released on 2021-04-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BinarySearch::File

To run module startup overhead benchmark:

 % bencher --module-startup -m BinarySearch::File

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::SortedSeek> 0.015

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::SortedSeek-1k-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_1k_num  , int (     1_000*rand()))



=item * File::SortedSeek-10k-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_10k_num , int(     10_000*rand()))



=item * File::SortedSeek-100k-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_100k_num, int(    100_000*rand()))



=item * File::SortedSeek-1m-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_1m_num  , int(  1_000_000*rand()))



=item * File::SortedSeek-10m-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_10m_num , int( 10_000_000*rand()))



=item * File::SortedSeek-100m-num (perl_code)

Code template:

 File::SortedSeek::numeric($Bencher::Scenario::BinarySearch::File::fh_100m_num, int(100_000_000*rand()))



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m BinarySearch::File >>):

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | File::SortedSeek-1k-num   |      3000 |       400 |                 0.00% |                68.79% | 1.8e-05 |      20 |
 | File::SortedSeek-10k-num  |      3000 |       300 |                21.42% |                39.01% | 1.4e-05 |      30 |
 | File::SortedSeek-10m-num  |      4000 |       300 |                33.04% |                26.87% | 8.7e-06 |      20 |
 | File::SortedSeek-100m-num |      4000 |       300 |                44.59% |                16.74% | 1.1e-05 |      29 |
 | File::SortedSeek-100k-num |      4000 |       200 |                60.71% |                 5.03% |   1e-05 |      22 |
 | File::SortedSeek-1m-num   |      5000 |       200 |                68.79% |                 0.00% |   1e-05 |      26 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m BinarySearch::File --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors  | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+
 | File::SortedSeek    |      21   |              11.3 |                 0.00% |               117.71% |   0.0002 |      20 |
 | perl -e1 (baseline) |       9.7 |               0   |               117.71% |                 0.00% | 3.6e-05  |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BinarySearch-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BinarySearch-File>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenario-BinarySearch-File/issues>

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
