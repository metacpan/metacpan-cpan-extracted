package Bencher::Scenario::Scalar::Cmp;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenario-Scalar-Cmp'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark Scalar::Cmp against similar solutions',
    participants => [
        {
            fcall_template => 'Scalar::Cmp::cmp_scalar(<data1>, <data2>)',
        },
        {
            fcall_template => 'Scalar::Cmp::cmpnum_scalar(<data1>, <data2>)',
        },
        {
            fcall_template => 'Scalar::Cmp::cmpstrornum_scalar(<data1>, <data2>)',
        },
        {
            fcall_template => 'Data::Cmp::cmp_data(<data1>, <data2>)',
        },
        {
            fcall_template => 'Data::Cmp::Numeric::cmp_data(<data1>, <data2>)',
        },
        {
            fcall_template => 'Data::Cmp::StrOrNumeric::cmp_data(<data1>, <data2>)',
        },
        {
            name => 'cmp',
            code_template => '<data1> cmp <data2>',
        },
        {
            name => '<=>',
            code_template => '<data1> <=> <data2>',
        },
    ],

    datasets => [
        {
            name=>'nums',
            args=>{
                data1=>1,
                data2=>2,
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark Scalar::Cmp against similar solutions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Scalar::Cmp - Benchmark Scalar::Cmp against similar solutions

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Scalar::Cmp (from Perl distribution Bencher-Scenario-Scalar-Cmp), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Scalar::Cmp

To run module startup overhead benchmark:

 % bencher --module-startup -m Scalar::Cmp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Scalar::Cmp> 0.003

L<Data::Cmp> 0.007

L<Data::Cmp::Numeric> 0.007

L<Data::Cmp::StrOrNumeric> 0.007

=head1 BENCHMARK PARTICIPANTS

=over

=item * Scalar::Cmp::cmp_scalar (perl_code)

Function call template:

 Scalar::Cmp::cmp_scalar(<data1>, <data2>)



=item * Scalar::Cmp::cmpnum_scalar (perl_code)

Function call template:

 Scalar::Cmp::cmpnum_scalar(<data1>, <data2>)



=item * Scalar::Cmp::cmpstrornum_scalar (perl_code)

Function call template:

 Scalar::Cmp::cmpstrornum_scalar(<data1>, <data2>)



=item * Data::Cmp::cmp_data (perl_code)

Function call template:

 Data::Cmp::cmp_data(<data1>, <data2>)



=item * Data::Cmp::Numeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::Numeric::cmp_data(<data1>, <data2>)



=item * Data::Cmp::StrOrNumeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::StrOrNumeric::cmp_data(<data1>, <data2>)



=item * cmp (perl_code)

Code template:

 <data1> cmp <data2>



=item * <=> (perl_code)

Code template:

 <data1> <=> <data2>



=back

=head1 BENCHMARK DATASETS

=over

=item * nums

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Scalar::Cmp >>):

 #table1#
 +-----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                       | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Cmp::StrOrNumeric::cmp_data |   1130000 |    884    |                 0.00% |             46435.26% | 3.5e-10 |      29 |
 | Data::Cmp::cmp_data               |   1463500 |    683.29 |                29.38% |             35867.99% | 5.8e-12 |      20 |
 | Data::Cmp::Numeric::cmp_data      |   1506800 |    663.64 |                33.21% |             34833.49% | 5.8e-12 |      20 |
 | Scalar::Cmp::cmpstrornum_scalar   |   1514500 |    660.3  |                33.89% |             34657.51% | 5.8e-12 |      20 |
 | Scalar::Cmp::cmp_scalar           |   2140000 |    467    |                89.43% |             24465.31% | 1.9e-10 |      24 |
 | Scalar::Cmp::cmpnum_scalar        |   2307000 |    433.4  |               103.98% |             22713.74% | 5.7e-12 |      20 |
 | cmp                               | 200000000 |      6    |             14167.58% |               226.16% | 7.3e-10 |      20 |
 | <=>                               | 530000000 |      1.9  |             46435.26% |                 0.00% | 1.4e-11 |      20 |
 +-----------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                            Rate  Data::Cmp::StrOrNumeric::cmp_data  Data::Cmp::cmp_data  Data::Cmp::Numeric::cmp_data  Scalar::Cmp::cmpstrornum_scalar  Scalar::Cmp::cmp_scalar  Scalar::Cmp::cmpnum_scalar   cmp   <=> 
  Data::Cmp::StrOrNumeric::cmp_data    1130000/s                                 --                 -22%                          -24%                             -25%                     -47%                        -50%  -99%  -99% 
  Data::Cmp::cmp_data                  1463500/s                                29%                   --                           -2%                              -3%                     -31%                        -36%  -99%  -99% 
  Data::Cmp::Numeric::cmp_data         1506800/s                                33%                   2%                            --                               0%                     -29%                        -34%  -99%  -99% 
  Scalar::Cmp::cmpstrornum_scalar      1514500/s                                33%                   3%                            0%                               --                     -29%                        -34%  -99%  -99% 
  Scalar::Cmp::cmp_scalar              2140000/s                                89%                  46%                           42%                              41%                       --                         -7%  -98%  -99% 
  Scalar::Cmp::cmpnum_scalar           2307000/s                               103%                  57%                           53%                              52%                       7%                          --  -98%  -99% 
  cmp                                200000000/s                             14633%               11288%                        10960%                           10905%                    7683%                       7123%    --  -68% 
  <=>                                530000000/s                             46426%               35862%                        34828%                           34652%                   24478%                      22710%  215%    -- 
 
 Legends:
   <=>: participant=<=>
   Data::Cmp::Numeric::cmp_data: participant=Data::Cmp::Numeric::cmp_data
   Data::Cmp::StrOrNumeric::cmp_data: participant=Data::Cmp::StrOrNumeric::cmp_data
   Data::Cmp::cmp_data: participant=Data::Cmp::cmp_data
   Scalar::Cmp::cmp_scalar: participant=Scalar::Cmp::cmp_scalar
   Scalar::Cmp::cmpnum_scalar: participant=Scalar::Cmp::cmpnum_scalar
   Scalar::Cmp::cmpstrornum_scalar: participant=Scalar::Cmp::cmpstrornum_scalar
   cmp: participant=cmp

Benchmark module startup overhead (C<< bencher -m Scalar::Cmp --module-startup >>):

 #table2#
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Cmp::StrOrNumeric |      10.1 |               4   |                 0.00% |                65.39% | 6.7e-06 |      20 |
 | Data::Cmp::Numeric      |      10   |               3.9 |                 0.44% |                64.67% | 1.8e-05 |      20 |
 | Data::Cmp               |      10   |               3.9 |                 0.57% |                64.44% | 9.4e-06 |      20 |
 | Scalar::Cmp             |      10   |               3.9 |                 0.91% |                63.90% | 1.7e-05 |      20 |
 | perl -e1 (baseline)     |       6.1 |               0   |                65.39% |                 0.00% | 1.5e-05 |      20 |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DC:S  DC:N  D:C  S:C  perl -e1 (baseline) 
  DC:S                  99.0/s    --    0%   0%   0%                 -39% 
  DC:N                 100.0/s    1%    --   0%   0%                 -39% 
  D:C                  100.0/s    1%    0%   --   0%                 -39% 
  S:C                  100.0/s    1%    0%   0%   --                 -39% 
  perl -e1 (baseline)  163.9/s   65%   63%  63%  63%                   -- 
 
 Legends:
   D:C: mod_overhead_time=3.9 participant=Data::Cmp
   DC:N: mod_overhead_time=3.9 participant=Data::Cmp::Numeric
   DC:S: mod_overhead_time=4 participant=Data::Cmp::StrOrNumeric
   S:C: mod_overhead_time=3.9 participant=Scalar::Cmp
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Scalar-Cmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Scalar-Cmp>.

=head1 SEE ALSO

L<Bencher::Scenario::DataCmp>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Scalar-Cmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
