package Bencher::Scenario::App::Sorted;

use 5.010001;
use strict;
use warnings;

use File::Slurper 'write_text';
use File::Temp qw(tempdir);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-12'; # DATE
our $DIST = 'Bencher-Scenario-App-Sorted'; # DIST
our $VERSION = '0.002'; # VERSION

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

Bencher::Scenario::App::Sorted - Benchmark sorted vs is-sorted

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::App::Sorted (from Perl distribution Bencher-Scenario-App-Sorted), released on 2021-10-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m App::Sorted

To run module startup overhead benchmark:

 % bencher --module-startup -m App::Sorted

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<App::sorted> 0.002

L<File::IsSorted> 0.0.6

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m App::Sorted >>):

 #table1#
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset                 | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | sorted      | 100k-sorted             |       4.8 |       210 |                 0.00% |                98.62% | 0.00023 |       8 |
 | sorted      | 100k-unsorted-middle    |       5.9 |       170 |                21.83% |                63.03% | 0.00048 |       7 |
 | sorted      | 100k-unsorted-beginning |       7.6 |       130 |                58.79% |                25.08% | 0.0002  |       7 |
 | is-sorted   | 100k-sorted             |       8.1 |       120 |                67.48% |                18.59% | 0.00018 |       8 |
 | is-sorted   | 100k-unsorted-middle    |       8.7 |       110 |                80.98% |                 9.75% | 0.0004  |       7 |
 | is-sorted   | 100k-unsorted-beginning |       9.5 |       100 |                98.62% |                 0.00% | 0.00017 |       8 |
 +-------------+-------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                      Rate  sorted 100k-sorted  sorted 100k-unsorted-middle  sorted 100k-unsorted-beginning  is-sorted 100k-sorted  is-sorted 100k-unsorted-middle  is-sorted 100k-unsorted-beginning 
  sorted 100k-sorted                 4.8/s                  --                         -19%                            -38%                   -42%                            -47%                               -52% 
  sorted 100k-unsorted-middle        5.9/s                 23%                           --                            -23%                   -29%                            -35%                               -41% 
  sorted 100k-unsorted-beginning     7.6/s                 61%                          30%                              --                    -7%                            -15%                               -23% 
  is-sorted 100k-sorted              8.1/s                 75%                          41%                              8%                     --                             -8%                               -16% 
  is-sorted 100k-unsorted-middle     8.7/s                 90%                          54%                             18%                     9%                              --                                -9% 
  is-sorted 100k-unsorted-beginning  9.5/s                110%                          70%                             30%                    19%                             10%                                 -- 
 
 Legends:
   is-sorted 100k-sorted: dataset=100k-sorted participant=is-sorted
   is-sorted 100k-unsorted-beginning: dataset=100k-unsorted-beginning participant=is-sorted
   is-sorted 100k-unsorted-middle: dataset=100k-unsorted-middle participant=is-sorted
   sorted 100k-sorted: dataset=100k-sorted participant=sorted
   sorted 100k-unsorted-beginning: dataset=100k-unsorted-beginning participant=sorted
   sorted 100k-unsorted-middle: dataset=100k-unsorted-middle participant=sorted

Benchmark module startup overhead (C<< bencher -m App::Sorted --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | File::IsSorted      |      50   |              41.7 |                 0.00% |               503.14% |   0.00011 |      11 |
 | App::sorted         |      13   |               4.7 |               275.04% |                60.82% | 2.1e-05   |       7 |
 | perl -e1 (baseline) |       8.3 |               0   |               503.14% |                 0.00% | 2.8e-05   |       7 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   F:I   A:s  perl -e1 (baseline) 
  F:I                   20.0/s    --  -74%                 -83% 
  A:s                   76.9/s  284%    --                 -36% 
  perl -e1 (baseline)  120.5/s  502%   56%                   -- 
 
 Legends:
   A:s: mod_overhead_time=4.7 participant=App::sorted
   F:I: mod_overhead_time=41.7 participant=File::IsSorted
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-App-Sorted>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-AppSorted>.

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

This software is copyright (c) 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-App-Sorted>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
