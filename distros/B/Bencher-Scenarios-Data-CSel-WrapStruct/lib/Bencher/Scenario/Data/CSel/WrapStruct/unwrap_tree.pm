package Bencher::Scenario::Data::CSel::WrapStruct::unwrap_tree;

use 5.010001;
use strict;
use warnings;

use Data::CSel::WrapStruct qw(wrap_struct);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel-WrapStruct'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark unwrap_tree()',
    participants => [
        {fcall_template => 'Data::CSel::WrapStruct::unwrap_tree(<tree>)'},
    ],
    datasets => [
        {name => 'scalar', args => {tree=>wrap_struct(1)}},
        {name => 'array1', args => {tree=>wrap_struct([1])}},
        {name => 'array100', args => {tree=>wrap_struct([1..100])}},
        {name => 'array1000', args => {tree=>wrap_struct([1..1000])}},
        {name => 'hash1', args => {tree=>wrap_struct({1=>1})}},
        {name => 'hash100', args => {tree=>wrap_struct({ map {$_=>$_} 1..100 })}},
        {name => 'hash1000', args => {tree=>wrap_struct({ map {$_=>$_} 1..1000 })}},
    ],
};

1;
# ABSTRACT: Benchmark unwrap_tree()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::CSel::WrapStruct::unwrap_tree - Benchmark unwrap_tree()

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Data::CSel::WrapStruct::unwrap_tree (from Perl distribution Bencher-Scenarios-Data-CSel-WrapStruct), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::CSel::WrapStruct::unwrap_tree

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::CSel::WrapStruct::unwrap_tree

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel::WrapStruct> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel::WrapStruct::unwrap_tree (perl_code)

Function call template:

 Data::CSel::WrapStruct::unwrap_tree(<tree>)



=back

=head1 BENCHMARK DATASETS

=over

=item * scalar

=item * array1

=item * array100

=item * array1000

=item * hash1

=item * hash100

=item * hash1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m Data::CSel::WrapStruct::unwrap_tree --with-args-size --with-result-size >>:

 #table1#
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+
 | dataset   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest | arg_tree_size (kB) | result_size (kB) |  errors | samples |
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+
 | hash1000  |       790 |    1300   |                 0.00% |             93235.95% |             350    |           99     | 7.2e-06 |      20 |
 | array1000 |      1100 |     900   |                40.44% |             66358.04% |             240    |           31     | 4.2e-06 |      20 |
 | hash100   |      9400 |     110   |              1086.82% |              7764.36% |              36    |           10     | 2.5e-07 |      23 |
 | array100  |     13000 |      79   |              1511.20% |              5692.95% |              25    |            3.2   | 1.9e-07 |      20 |
 | hash1     |    290000 |       3.5 |             36251.85% |               156.76% |               0.86 |            0.25  | 1.3e-08 |      20 |
 | array1    |    350000 |       2.9 |             43853.76% |               112.35% |               0.55 |            0.094 | 3.4e-09 |      20 |
 | scalar    |    740000 |       1.4 |             93235.95% |                 0.00% |               0.18 |            0.023 | 1.7e-09 |      20 |
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                     Rate  hash1000 350  array1000 240  hash100 36  array100 25  hash1 0.86  array1 0.55  scalar 0.18 
  hash1000 350      790/s            --           -30%        -91%         -93%        -99%         -99%         -99% 
  array1000 240    1100/s           44%             --        -87%         -91%        -99%         -99%         -99% 
  hash100 36       9400/s         1081%           718%          --         -28%        -96%         -97%         -98% 
  array100 25     13000/s         1545%          1039%         39%           --        -95%         -96%         -98% 
  hash1 0.86     290000/s        37042%         25614%       3042%        2157%          --         -17%         -60% 
  array1 0.55    350000/s        44727%         30934%       3693%        2624%         20%           --         -51% 
  scalar 0.18    740000/s        92757%         64185%       7757%        5542%        150%         107%           -- 
 
 Legends:
   array1 0.55: arg_tree_size=0.55 dataset=array1 result_size=0.094
   array100 25: arg_tree_size=25 dataset=array100 result_size=3.2
   array1000 240: arg_tree_size=240 dataset=array1000 result_size=31
   hash1 0.86: arg_tree_size=0.86 dataset=hash1 result_size=0.25
   hash100 36: arg_tree_size=36 dataset=hash100 result_size=10
   hash1000 350: arg_tree_size=350 dataset=hash1000 result_size=99
   scalar 0.18: arg_tree_size=0.18 dataset=scalar result_size=0.023

Benchmark module startup overhead (C<< bencher -m Data::CSel::WrapStruct::unwrap_tree --module-startup >>):

 #table2#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::CSel::WrapStruct |      16   |               8.5 |                 0.00% |               110.39% | 4.3e-05 |      20 |
 | perl -e1 (baseline)    |       7.5 |               0   |               110.39% |                 0.00% | 1.6e-05 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DC:W  perl -e1 (baseline) 
  DC:W                  62.5/s    --                 -53% 
  perl -e1 (baseline)  133.3/s  113%                   -- 
 
 Legends:
   DC:W: mod_overhead_time=8.5 participant=Data::CSel::WrapStruct
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-CSel-WrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-CSel-WrapStruct>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-CSel-WrapStruct>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
