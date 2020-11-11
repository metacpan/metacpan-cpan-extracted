package Bencher::Scenario::AppSorted;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'Bencher-Scenario-AppSorted'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Slurper 'write_text';
use File::Temp qw(tempdir);

my $dir = tempdir();
write_text("$dir/100k-sorted"            , join("", map {sprintf "%06d\n", $_} 1..100_000));
write_text("$dir/100k-unsorted-middle"   , join("", map {sprintf "%06d\n", $_} 1..50_000, 50_002, 50_001, 50_003..100_000));
write_text("$dir/100k-unsorted-beginning", join("", map {sprintf "%06d\n", $_} 2,1, 3..100_000));

our $scenario = {
    summary => 'Benchmark sorted vs is-sorted',
    participants => [
        {name=>"sorted"   , module=>'App::sorted', cmdline_template=>'sorted <filename>; true'},
        {name=>"is-sorted", module=>'File::IsSorted', cmdline_template=>'is-sorted check <filename>; true'},
    ],
    precision => 7,
    datasets => [
        {name=>'100k-sorted', args=>{filename=>"$dir/100k-sorted"}},
        {name=>'100k-unsorted-middle', args=>{filename=>"$dir/100k-unsorted-middle"}},
        {name=>'100k-unsorted-beginning', args=>{filename=>"$dir/100k-unsorted-beginning"}},
    ],
};

1;
# ABSTRACT: Benchmark sorted vs is-sorted

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AppSorted - Benchmark sorted vs is-sorted

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::AppSorted (from Perl distribution Bencher-Scenario-AppSorted), released on 2020-05-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AppSorted

To run module startup overhead benchmark:

 % bencher --module-startup -m AppSorted

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::sorted> 0.001

L<File::IsSorted> 0.0.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * sorted (command)

Command line:

 #TEMPLATE: sorted <filename>; true



=item * is-sorted (command)

Command line:

 #TEMPLATE: is-sorted check <filename>; true



=back

=head1 BENCHMARK DATASETS

=over

=item * 100k-sorted

=item * 100k-unsorted-middle

=item * 100k-unsorted-beginning

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.10 >>, OS kernel: I<< Linux version 5.3.0-46-generic >>.

Benchmark with default options (C<< bencher -m AppSorted >>):

 #table1#
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant | dataset                 | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | sorted      | 100k-sorted             |       7.4 |       140 |                 0.00% |                93.01% |   0.00026 |      11 |
 | sorted      | 100k-unsorted-middle    |       9.2 |       110 |                25.42% |                53.89% |   0.00014 |       7 |
 | is-sorted   | 100k-sorted             |      12   |        85 |                60.86% |                19.99% |   0.00032 |       7 |
 | sorted      | 100k-unsorted-beginning |      12   |        82 |                66.10% |                16.20% |   0.00019 |       7 |
 | is-sorted   | 100k-unsorted-middle    |      13   |        79 |                72.72% |                11.75% |   0.00014 |       7 |
 | is-sorted   | 100k-unsorted-beginning |      14   |        70 |                93.01% |                 0.00% | 7.1e-05   |       7 |
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m AppSorted --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | File::IsSorted      |      35   |              29.4 |                 0.00% |               525.86% | 5.5e-05 |       7 |
 | App::sorted         |       8.2 |               2.6 |               325.09% |                47.23% | 1.4e-05 |       7 |
 | perl -e1 (baseline) |       5.6 |               0   |               525.86% |                 0.00% |   2e-05 |       7 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-AppSorted>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-AppSorted>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-AppSorted>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
