package Bencher::Scenario::Data::CSel::WrapStruct::wrap_struct;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel-WrapStruct'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark wrap_struct()',
    participants => [
        {fcall_template => 'Data::CSel::WrapStruct::wrap_struct(<data>)'},
    ],
    datasets => [
        {name => 'scalar', args => {data=>1}},
        {name => 'array1', args => {data=>[1]}},
        {name => 'array100', args => {data=>[1..100]}},
        {name => 'array1000', args => {data=>[1..1000]}},
        {name => 'hash1', args => {data=>{1=>1}}},
        {name => 'hash100', args => {data=>{ map {$_=>$_} 1..100 }}},
        {name => 'hash1000', args => {data=>{ map {$_=>$_} 1..1000 }}},
    ],
};

1;
# ABSTRACT: Benchmark wrap_struct()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::CSel::WrapStruct::wrap_struct - Benchmark wrap_struct()

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Data::CSel::WrapStruct::wrap_struct (from Perl distribution Bencher-Scenarios-Data-CSel-WrapStruct), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::CSel::WrapStruct::wrap_struct

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::CSel::WrapStruct::wrap_struct

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel::WrapStruct> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel::WrapStruct::wrap_struct (perl_code)

Function call template:

 Data::CSel::WrapStruct::wrap_struct(<data>)



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

Benchmark with C<< bencher -m Data::CSel::WrapStruct::wrap_struct --with-args-size --with-result-size >>:

 #table1#
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+
 | dataset   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest | arg_data_size (kB) | result_size (kB) |  errors | samples |
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+
 | hash1000  |       722 |   1390    |                 0.00% |            187783.10% |             99     |           349    | 1.3e-06 |      20 |
 | array1000 |      1100 |    910    |                52.31% |            123258.53% |             31     |           240    | 2.3e-06 |      20 |
 | hash100   |      7300 |    140    |               910.20% |             18498.61% |             10     |            36    | 4.1e-07 |      22 |
 | array100  |     12200 |     82.2  |              1585.52% |             11046.90% |              3.19  |            24.5  | 2.3e-08 |      26 |
 | hash1     |    280000 |      3.6  |             38730.70% |               383.85% |              0.25  |             0.86 | 8.3e-09 |      20 |
 | array1    |    430000 |      2.3  |             59575.07% |               214.84% |              0.094 |             0.55 | 1.3e-08 |      20 |
 | scalar    |   1400000 |      0.74 |            187783.10% |                 0.00% |              0.023 |             0.18 | 8.3e-10 |      20 |
 +-----------+-----------+-----------+-----------------------+-----------------------+--------------------+------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                      Rate  hash1000 99  array1000 31  hash100 10  array100 3.19  hash1 0.25  array1 0.094  scalar 0.023 
  hash1000 99        722/s           --          -34%        -89%           -94%        -99%          -99%          -99% 
  array1000 31      1100/s          52%            --        -84%           -90%        -99%          -99%          -99% 
  hash100 10        7300/s         892%          550%          --           -41%        -97%          -98%          -99% 
  array100 3.19    12200/s        1590%         1007%         70%             --        -95%          -97%          -99% 
  hash1 0.25      280000/s       38511%        25177%       3788%          2183%          --          -36%          -79% 
  array1 0.094    430000/s       60334%        39465%       5986%          3473%         56%            --          -67% 
  scalar 0.023   1400000/s      187737%       122872%      18818%         11008%        386%          210%            -- 
 
 Legends:
   array1 0.094: arg_data_size=0.094 dataset=array1 result_size=0.55
   array100 3.19: arg_data_size=3.19 dataset=array100 result_size=24.5
   array1000 31: arg_data_size=31 dataset=array1000 result_size=240
   hash1 0.25: arg_data_size=0.25 dataset=hash1 result_size=0.86
   hash100 10: arg_data_size=10 dataset=hash100 result_size=36
   hash1000 99: arg_data_size=99 dataset=hash1000 result_size=349
   scalar 0.023: arg_data_size=0.023 dataset=scalar result_size=0.18

Benchmark module startup overhead (C<< bencher -m Data::CSel::WrapStruct::wrap_struct --module-startup >>):

 #table2#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::CSel::WrapStruct |      16   |               7.8 |                 0.00% |                97.80% |   5e-05 |      20 |
 | perl -e1 (baseline)    |       8.2 |               0   |                97.80% |                 0.00% | 1.2e-05 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DC:W  perl -e1 (baseline) 
  DC:W                  62.5/s    --                 -48% 
  perl -e1 (baseline)  122.0/s   95%                   -- 
 
 Legends:
   DC:W: mod_overhead_time=7.8 participant=Data::CSel::WrapStruct
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
