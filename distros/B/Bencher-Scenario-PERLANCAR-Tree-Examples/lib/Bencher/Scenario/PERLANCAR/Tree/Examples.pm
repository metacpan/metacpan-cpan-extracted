package Bencher::Scenario::PERLANCAR::Tree::Examples;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-07'; # DATE
our $DIST = 'Bencher-Scenario-PERLANCAR-Tree-Examples'; # DIST
our $VERSION = '0.031'; # VERSION

our $scenario = {
    summary => 'Benchmark PERLANCAR::Tree::Examples',
    modules => {
        'PERLANCAR::Tree::Examples' => {version=>1.0.4},
    },
    description => <<'_',

Created just for testing, while adding feature in `Bencher` to return result
size.

_
    participants => [
        {
            fcall_template => 'PERLANCAR::Tree::Examples::gen_sample_data(size => <size>, backend => <backend>)',
        },
    ],
    datasets => [
        {name => 'dataset', args=>{'size@'=>['tiny1', 'medium1'], 'backend@'=>['hash', 'array']}},
    ],
    include_result_size => 1,
};

1;
# ABSTRACT: Benchmark PERLANCAR::Tree::Examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::Tree::Examples - Benchmark PERLANCAR::Tree::Examples

=head1 VERSION

This document describes version 0.031 of Bencher::Scenario::PERLANCAR::Tree::Examples (from Perl distribution Bencher-Scenario-PERLANCAR-Tree-Examples), released on 2022-05-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::Tree::Examples

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCAR::Tree::Examples

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Created just for testing, while adding feature in C<Bencher> to return result
size.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Tree::Examples> 1.0.6

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Tree::Examples::gen_sample_data (perl_code)

Function call template:

 PERLANCAR::Tree::Examples::gen_sample_data(size => <size>, backend => <backend>)



=back

=head1 BENCHMARK DATASETS

=over

=item * dataset

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m PERLANCAR::Tree::Examples

Result formatted as table:

 #table1#
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | arg_backend | arg_size | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | hash        | medium1  |      14.9 |    67.3   |                 0.00% |            505089.06% | 2.8e-05 |      22 |
 | array       | medium1  |      16   |    63     |                 6.12% |            475952.09% | 7.7e-05 |      20 |
 | hash        | tiny1    |   71000   |     0.014 |            480825.90% |                 5.05% |   6e-08 |      20 |
 | array       | tiny1    |   75000   |     0.013 |            505089.06% |                 0.00% | 2.7e-08 |      20 |
 +-------------+----------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                    Rate  hash medium1  array medium1  hash tiny1  array tiny1 
  hash medium1    14.9/s            --            -6%        -99%         -99% 
  array medium1     16/s            6%             --        -99%         -99% 
  hash tiny1     71000/s       480614%        449900%          --          -7% 
  array tiny1    75000/s       517592%        484515%          7%           -- 
 
 Legends:
   array medium1: arg_backend=array arg_size=medium1
   array tiny1: arg_backend=array arg_size=tiny1
   hash medium1: arg_backend=hash arg_size=medium1
   hash tiny1: arg_backend=hash arg_size=tiny1

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m PERLANCAR::Tree::Examples --module-startup

Result formatted as table:

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | PERLANCAR::Tree::Examples |        33 |                13 |                 0.00% |               118.25% | 6.6e-05   |      20 |
 | perl -e1 (baseline)       |        20 |                 0 |               118.25% |                 0.00% |   0.00021 |      21 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                         Rate  PT:E  perl -e1 (baseline) 
  PT:E                 30.3/s    --                 -39% 
  perl -e1 (baseline)  50.0/s   64%                   -- 
 
 Legends:
   PT:E: mod_overhead_time=13 participant=PERLANCAR::Tree::Examples
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-PERLANCAR-Tree-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-PERLANCAR-Tree-Examples>.

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

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-PERLANCAR-Tree-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
