package Bencher::Scenario::DataCmp;

our $DATE = '2018-12-06'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

$main::data1M = join("", map {chr(256*rand)} 1..(1024*1024));

our $scenario = {
    summary => 'Benchmark Data::Cmp against similar solutions',
    participants => [
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
            module => 'JSON::PP',
            code_template => 'JSON::PP::encode_json(<data1>) eq JSON::PP::encode_json(<data2>)',
        },
        {
            fcall_template => 'Data::Compare::Compare(<data1>, <data2>)',
        },
    ],

    datasets => [
        {
            name=>'empty arrays',
            args=>{
                data1=>[],
                data2=>[],
            },
        },
        {
            name=>'small arrays',
            args=>{
                data1=>[1,2,[],3,4],
                data2=>[1,2,[],5,4],
            },
        },
        {
            name=>'1k array of ints',
            args=>{
                data1=>[1..1000],
                data2=>[1..1000],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark Data::Cmp against similar solutions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCmp - Benchmark Data::Cmp against similar solutions

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DataCmp (from Perl distribution Bencher-Scenario-DataCmp), released on 2018-12-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCmp

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCmp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Cmp> 0.006

L<Data::Cmp::Numeric> 0.006

L<Data::Cmp::StrOrNumeric> 0.006

L<JSON::PP> 2.27400_02

L<Data::Compare> 1.25

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Cmp::cmp_data (perl_code)

Function call template:

 Data::Cmp::cmp_data(<data1>, <data2>)



=item * Data::Cmp::Numeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::Numeric::cmp_data(<data1>, <data2>)



=item * Data::Cmp::StrOrNumeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::StrOrNumeric::cmp_data(<data1>, <data2>)



=item * JSON::PP (perl_code)

Code template:

 JSON::PP::encode_json(<data1>) eq JSON::PP::encode_json(<data2>)



=item * Data::Compare::Compare (perl_code)

Function call template:

 Data::Compare::Compare(<data1>, <data2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty arrays

=item * small arrays

=item * 1k array of ints

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m DataCmp >>):

 #table1#
 +-----------------------------------+------------------+-----------+-----------+------------+---------+---------+
 | participant                       | dataset          | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+------------------+-----------+-----------+------------+---------+---------+
 | Data::Compare::Compare            | 1k array of ints |       238 |  4.21     |       1    | 4.1e-06 |      20 |
 | JSON::PP                          | 1k array of ints |       330 |  3        |       1.4  | 6.3e-06 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | 1k array of ints |       830 |  1.2      |       3.5  | 3.4e-06 |      20 |
 | Data::Cmp::Numeric::cmp_data      | 1k array of ints |      1120 |  0.891    |       4.72 | 6.9e-07 |      20 |
 | Data::Cmp::cmp_data               | 1k array of ints |      1140 |  0.88     |       4.78 | 6.4e-07 |      20 |
 | Data::Compare::Compare            | small arrays     |     30000 |  0.033    |     130    | 5.3e-08 |      20 |
 | JSON::PP                          | small arrays     |     36000 |  0.028    |     150    |   4e-08 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | small arrays     |     93700 |  0.0107   |     394    | 3.3e-09 |      20 |
 | Data::Cmp::cmp_data               | small arrays     |    100000 |  0.0098   |     430    | 5.5e-08 |      21 |
 | Data::Cmp::Numeric::cmp_data      | small arrays     |    100000 |  0.0097   |     440    |   1e-08 |      20 |
 | JSON::PP                          | empty arrays     |    128000 |  0.00782  |     538    | 3.3e-09 |      20 |
 | Data::Compare::Compare            | empty arrays     |    154000 |  0.00649  |     648    | 3.2e-09 |      22 |
 | Data::Cmp::Numeric::cmp_data      | empty arrays     |    300000 |  0.0033   |    1300    | 6.7e-09 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | empty arrays     |    310000 |  0.0032   |    1300    |   5e-09 |      20 |
 | Data::Cmp::cmp_data               | empty arrays     |    315000 |  0.003175 |    1325    | 3.4e-11 |      20 |
 +-----------------------------------+------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCmp --module-startup >>):

 #table2#
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | Data::Compare           |        32 |                     24 |        1   | 7.7e-05 |      20 |
 | JSON::PP                |        27 |                     19 |        1.2 | 5.4e-05 |      21 |
 | Data::Cmp               |        13 |                      5 |        2.5 | 3.4e-05 |      20 |
 | Data::Cmp::StrOrNumeric |        13 |                      5 |        2.5 | 1.9e-05 |      20 |
 | Data::Cmp::Numeric      |        13 |                      5 |        2.5 | 1.9e-05 |      21 |
 | perl -e1 (baseline)     |         8 |                      0 |        4   | 1.3e-05 |      20 |
 +-------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-DataCmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataCmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-DataCmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::ScalarCmp>

L<Bencher::Scenario::Serializers>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
