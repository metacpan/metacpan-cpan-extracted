package Bencher::Scenario::DataComparisonModules::Compare;

our $DATE = '2018-08-16'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark data comparison modules',
    modules => {
        'Data::Cmp' => {version=>0.002},
    },
    participants => [
        {
            fcall_template => 'Data::Compare::Compare(<d1>, <d2>)',
        },
        {
            fcall_template => 'Data::Cmp::cmp_data(<d1>, <d2>)',
        },
        {
            fcall_template => 'Data::Cmp::Numeric::cmp_data(<d1>, <d2>)',
        },
        {
            fcall_template => 'Data::Cmp::StrOrNumeric::cmp_data(<d1>, <d2>)',
        },
        {
            name => 'Test::Deep::NoTest::eq_deeply',
            module => 'Test::Deep::NoTest',
            code_template => 'use Test::Deep::NoTest; eq_deeply(<d1>, <d2>)',
        },
        {
            fcall_template => 'Data::Comparator::data_comparator(<d1>, <d2>)',
        },
        {
            name => 'Data::Diff::diff',
            module => 'Data::Diff',
            # diff not exported by Data::Diff as advertised
            #code_template => 'use Data::Diff qw(diff); diff(<d1>, <d2>)',
            code_template => 'use Data::Diff; Data::Diff->new(<d1>, <d2>)',
        },
    ],
    datasets => [
        {name => 'simple scalar'  , args=>{d1=>1, d2=>1}},
        {name => 'array len=10'   , args=>{d1=>[1..10], d2=>[1..10]}},
        {name => 'array len=1000' , args=>{d1=>[1..1000], d2=>[1..1000]}},
        {name => 'array len=10000', args=>{d1=>[1..10000], d2=>[1..10000]}, include_by_default=>0},
        {name => 'hash keys=10'   , args=>{d1=>{1..20}, d2=>{1..20}}},
        {name => 'hash keys=1000' , args=>{d1=>{1..2000}, d2=>{1..2000}}},
    ],
};

1;
# ABSTRACT: Benchmark data comparison modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataComparisonModules::Compare - Benchmark data comparison modules

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DataComparisonModules::Compare (from Perl distribution Bencher-Scenarios-DataComparisonModules), released on 2018-08-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataComparisonModules::Compare

To run module startup overhead benchmark:

 % bencher --module-startup -m DataComparisonModules::Compare

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Cmp> 0.005

L<Data::Cmp::Numeric> 0.005

L<Data::Cmp::StrOrNumeric> 0.005

L<Data::Comparator>

L<Data::Compare> 1.25

L<Data::Diff> 0.01

L<Test::Deep::NoTest>

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Compare::Compare (perl_code)

Function call template:

 Data::Compare::Compare(<d1>, <d2>)



=item * Data::Cmp::cmp_data (perl_code)

Function call template:

 Data::Cmp::cmp_data(<d1>, <d2>)



=item * Data::Cmp::Numeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::Numeric::cmp_data(<d1>, <d2>)



=item * Data::Cmp::StrOrNumeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::StrOrNumeric::cmp_data(<d1>, <d2>)



=item * Test::Deep::NoTest::eq_deeply (perl_code)

Code template:

 use Test::Deep::NoTest; eq_deeply(<d1>, <d2>)



=item * Data::Comparator::data_comparator (perl_code)

Function call template:

 Data::Comparator::data_comparator(<d1>, <d2>)



=item * Data::Diff::diff (perl_code)

Code template:

 use Data::Diff; Data::Diff->new(<d1>, <d2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * simple scalar

=item * array len=10

=item * array len=1000

=item * hash keys=10

=item * hash keys=1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DataComparisonModules::Compare >>):

 #table1#
 +-----------------------------------+----------------+-----------+-----------+------------+---------+---------+
 | participant                       | dataset        | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+----------------+-----------+-----------+------------+---------+---------+
 | Data::Diff::diff                  | array len=1000 |       150 |  6.9      |        1   | 2.4e-05 |      20 |
 | Data::Diff::diff                  | hash keys=1000 |       170 |  5.8      |        1.2 | 2.4e-05 |      20 |
 | Data::Comparator::data_comparator | hash keys=1000 |       180 |  5.6      |        1.2 | 8.7e-06 |      21 |
 | Data::Compare::Compare            | hash keys=1000 |       190 |  5.2      |        1.3 |   9e-06 |      20 |
 | Data::Comparator::data_comparator | array len=1000 |       190 |  5.2      |        1.3 | 1.7e-05 |      20 |
 | Data::Compare::Compare            | array len=1000 |       250 |  3.9      |        1.7 | 1.8e-05 |      20 |
 | Test::Deep::NoTest::eq_deeply     | hash keys=1000 |       320 |  3.1      |        2.2 | 9.9e-06 |      20 |
 | Data::Cmp::Numeric::cmp_data      | hash keys=1000 |       350 |  2.9      |        2.4 |   1e-05 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | hash keys=1000 |       500 |  2        |        3   | 2.8e-05 |      20 |
 | Data::Cmp::cmp_data               | hash keys=1000 |       600 |  1.7      |        4.1 | 2.2e-06 |      20 |
 | Data::Cmp::cmp_data               | array len=1000 |       620 |  1.6      |        4.2 | 5.4e-06 |      20 |
 | Data::Cmp::Numeric::cmp_data      | array len=1000 |       630 |  1.6      |        4.3 | 1.1e-05 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | array len=1000 |       800 |  1.2      |        5.5 |   2e-06 |      20 |
 | Test::Deep::NoTest::eq_deeply     | array len=1000 |      1200 |  0.82     |        8.4 |   2e-06 |      20 |
 | Test::Deep::NoTest::eq_deeply     | hash keys=10   |      5300 |  0.19     |       36   | 2.1e-07 |      20 |
 | Test::Deep::NoTest::eq_deeply     | array len=10   |      7000 |  0.14     |       48   | 4.8e-07 |      20 |
 | Data::Compare::Compare            | array len=10   |     12000 |  0.084    |       82   | 1.1e-07 |      20 |
 | Data::Diff::diff                  | array len=10   |     13000 |  0.076    |       90   |   8e-08 |      20 |
 | Data::Compare::Compare            | hash keys=10   |     16000 |  0.061    |      110   | 8.9e-08 |      29 |
 | Data::Comparator::data_comparator | hash keys=10   |     17000 |  0.059    |      120   | 1.1e-07 |      20 |
 | Data::Diff::diff                  | hash keys=10   |     18000 |  0.056    |      120   | 1.1e-07 |      20 |
 | Data::Comparator::data_comparator | array len=10   |     18000 |  0.054    |      130   | 1.2e-07 |      23 |
 | Data::Cmp::Numeric::cmp_data      | hash keys=10   |     32000 |  0.031    |      220   | 2.2e-07 |      22 |
 | Data::Cmp::StrOrNumeric::cmp_data | array len=10   |     36000 |  0.027    |      250   | 1.2e-07 |      20 |
 | Data::Cmp::cmp_data               | array len=10   |     45000 |  0.022    |      310   |   7e-08 |      20 |
 | Data::Cmp::Numeric::cmp_data      | array len=10   |     45000 |  0.022    |      310   | 1.4e-07 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | hash keys=10   |     49000 |  0.021    |      330   |   6e-08 |      20 |
 | Data::Cmp::cmp_data               | hash keys=10   |     62000 |  0.016    |      430   |   2e-08 |      20 |
 | Test::Deep::NoTest::eq_deeply     | simple scalar  |    150000 |  0.0069   |     1000   | 1.1e-08 |      32 |
 | Data::Diff::diff                  | simple scalar  |    209000 |  0.00478  |     1440   | 7.9e-10 |      20 |
 | Data::Compare::Compare            | simple scalar  |    210000 |  0.0048   |     1400   | 2.2e-08 |      20 |
 | Data::Comparator::data_comparator | simple scalar  |    301000 |  0.00332  |     2070   | 1.6e-09 |      24 |
 | Data::Cmp::StrOrNumeric::cmp_data | simple scalar  |    500000 |  0.002    |     3500   | 6.7e-09 |      20 |
 | Data::Cmp::Numeric::cmp_data      | simple scalar  |    650000 |  0.0015   |     4500   | 3.3e-09 |      20 |
 | Data::Cmp::cmp_data               | simple scalar  |   1220000 |  0.000821 |     8370   | 4.2e-10 |      20 |
 +-----------------------------------+----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataComparisonModules::Compare --module-startup >>):

 #table2#
 +-------------------------+-----------+------------------------+------------+-----------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+-----------+------------------------+------------+-----------+---------+
 | Data::Diff              |      57.3 |                   49.7 |        1   | 3.3e-05   |      21 |
 | Data::Compare           |      40   |                   32.4 |        2   |   0.0011  |      20 |
 | Test::Deep::NoTest      |      19   |                   11.4 |        3   | 6.4e-05   |      20 |
 | Data::Cmp::StrOrNumeric |      10   |                    2.4 |        4   |   0.0003  |      21 |
 | Data::Comparator        |      13   |                    5.4 |        4.3 | 3.4e-05   |      21 |
 | Data::Cmp::Numeric      |      10   |                    2.4 |        4   |   0.00024 |      20 |
 | Data::Cmp               |      12   |                    4.4 |        4.6 | 2.6e-05   |      20 |
 | perl -e1 (baseline)     |       7.6 |                    0   |        7.5 | 6.5e-05   |      24 |
 +-------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataComparisonModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataComparisonModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataComparisonModules>

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
