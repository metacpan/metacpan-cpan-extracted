package Bencher::Scenario::Data::CSel::Parsing;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Data-CSel'; # DIST
our $VERSION = '0.041'; # VERSION

our $scenario = {
    summary => 'Benchmark parsing speed',
    modules => {
        'Data::CSel' => {version => '0.128'},
    },
    participants => [
        { fcall_template => 'Data::CSel::parse_csel(<expr>)' },
    ],
    datasets => [
        {args=>{expr=>'*'}},
        {args=>{expr=>'T'}},
        {args=>{expr=>'T T2 T3 T4 T5'}},
        {args=>{expr=>'T ~ T ~ T ~ T ~ T'}},
        {args=>{expr=>':has(T[length > 1])'}},
    ],
};

1;
# ABSTRACT: Benchmark parsing speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::CSel::Parsing - Benchmark parsing speed

=head1 VERSION

This document describes version 0.041 of Bencher::Scenario::Data::CSel::Parsing (from Perl distribution Bencher-Scenarios-Data-CSel), released on 2023-01-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::CSel::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::CSel::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel> 0.128

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel::parse_csel (perl_code)

Function call template:

 Data::CSel::parse_csel(<expr>)



=back

=head1 BENCHMARK DATASETS

=over

=item * *

=item * T

=item * T T2 T3 T4 T5

=item * T ~ T ~ T ~ T ~ T

=item * :has(T[length > 1])

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::CSel::Parsing >>):

 #table1#
 +---------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset             | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | :has(T[length > 1]) |     22000 |      45   |                 0.00% |               627.35% | 6.7e-08 |      20 |
 | T ~ T ~ T ~ T ~ T   |     39000 |      25   |                78.09% |               308.41% |   4e-08 |      20 |
 | T T2 T3 T4 T5       |     42000 |      24   |                88.05% |               286.79% | 2.7e-08 |      20 |
 | T                   |    100000 |       8   |               449.21% |                32.44% | 1.9e-07 |      20 |
 | *                   |    160000 |       6.2 |               627.35% |                 0.00% | 6.7e-09 |      20 |
 +---------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                           Rate  :has(T[length > 1])  T ~ T ~ T ~ T ~ T  T T2 T3 T4 T5     T     * 
  :has(T[length > 1])   22000/s                   --               -44%           -46%  -82%  -86% 
  T ~ T ~ T ~ T ~ T     39000/s                  80%                 --            -4%  -68%  -75% 
  T T2 T3 T4 T5         42000/s                  87%                 4%             --  -66%  -74% 
  T                    100000/s                 462%               212%           200%    --  -22% 
  *                    160000/s                 625%               303%           287%   29%    -- 
 
 Legends:
   *: dataset=*
   :has(T[length > 1]): dataset=:has(T[length > 1])
   T: dataset=T
   T T2 T3 T4 T5: dataset=T T2 T3 T4 T5
   T ~ T ~ T ~ T ~ T: dataset=T ~ T ~ T ~ T ~ T

Benchmark module startup overhead (C<< bencher -m Data::CSel::Parsing --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Data::CSel          |      14   |               7.3 |                 0.00% |               116.09% |   0.00013 |      20 |
 | perl -e1 (baseline) |       6.7 |               0   |               116.09% |                 0.00% | 6.1e-05   |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   D:C  perl -e1 (baseline) 
  D:C                   71.4/s    --                 -52% 
  perl -e1 (baseline)  149.3/s  108%                   -- 
 
 Legends:
   D:C: mod_overhead_time=7.3 participant=Data::CSel
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-CSel>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
