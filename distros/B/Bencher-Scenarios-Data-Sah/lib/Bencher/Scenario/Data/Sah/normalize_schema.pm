package Bencher::Scenario::Data::Sah::normalize_schema;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

# TODO: benchmark normalize_clset

our $scenario = {
    summary => 'Benchmark normalizing Sah schema',
    participants => [
        {
            fcall_template => 'Data::Sah::Normalize::normalize_schema(<schema>)'
        },
    ],
    datasets => [

        {
            name    => 'str',
            summary => '',
            args    => {
                schema => 'str',
            },
        },

        {
            name => 'str_wildcard',
            args => {
                schema => 'str*',
            },
        },

        {
            name => 'array1',
            args => {
                schema => ['str'],
            },
        },

        {
            name => 'array3',
            args => {
                schema => ['str', len=>1],
            },
        },

        {
            name => 'array5',
            args => {
                schema => ['str', min_len=>8, max_len=>16],
            },
        },

    ],
};

1;
# ABSTRACT: Benchmark normalizing Sah schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::normalize_schema - Benchmark normalizing Sah schema

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::normalize_schema (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::normalize_schema

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Sah::normalize_schema

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Normalize> 0.051

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Sah::Normalize::normalize_schema (perl_code)

Function call template:

 Data::Sah::Normalize::normalize_schema(<schema>)



=back

=head1 BENCHMARK DATASETS

=over

=item * str

.

=item * str_wildcard

=item * array1

=item * array3

=item * array5

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::normalize_schema >>):

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | array5       |    158811 |   6.29679 |                 0.00% |               520.32% | 5.7e-12 |      20 |
 | array3       |    215810 |   4.6338  |                35.89% |               356.49% | 5.7e-12 |      20 |
 | array1       |    453480 |   2.2052  |               185.55% |               117.24% | 5.7e-12 |      20 |
 | str_wildcard |    710000 |   1.4     |               344.69% |                39.50% |   1e-08 |      20 |
 | str          |    990000 |   1       |               520.32% |                 0.00% | 1.6e-09 |      21 |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                    Rate  array5  array3  array1  str_wildcard   str 
  array5        158811/s      --    -26%    -64%          -77%  -84% 
  array3        215810/s     35%      --    -52%          -69%  -78% 
  array1        453480/s    185%    110%      --          -36%  -54% 
  str_wildcard  710000/s    349%    230%     57%            --  -28% 
  str           990000/s    529%    363%    120%           39%    -- 
 
 Legends:
   array1: dataset=array1
   array3: dataset=array3
   array5: dataset=array5
   str: dataset=str
   str_wildcard: dataset=str_wildcard

Benchmark module startup overhead (C<< bencher -m Data::Sah::normalize_schema --module-startup >>):

 #table2#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Sah::Normalize |      11   |               3.7 |                 0.00% |                50.31% | 4.5e-05 |      20 |
 | perl -e1 (baseline)  |       7.3 |               0   |                50.31% |                 0.00% | 4.8e-05 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DS:N  perl -e1 (baseline) 
  DS:N                  90.9/s    --                 -33% 
  perl -e1 (baseline)  137.0/s   50%                   -- 
 
 Legends:
   DS:N: mod_overhead_time=3.7 participant=Data::Sah::Normalize
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah>.

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

This software is copyright (c) 2023, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
