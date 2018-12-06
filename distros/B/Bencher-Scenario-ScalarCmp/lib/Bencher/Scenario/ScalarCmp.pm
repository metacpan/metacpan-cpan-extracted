package Bencher::Scenario::ScalarCmp;

our $DATE = '2018-12-06'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::ScalarCmp - Benchmark Scalar::Cmp against similar solutions

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ScalarCmp (from Perl distribution Bencher-Scenario-ScalarCmp), released on 2018-12-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ScalarCmp

To run module startup overhead benchmark:

 % bencher --module-startup -m ScalarCmp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Scalar::Cmp> 0.001

L<Data::Cmp> 0.006

L<Data::Cmp::Numeric> 0.006

L<Data::Cmp::StrOrNumeric> 0.006

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

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m ScalarCmp >>):

 #table1#
 +-----------------------------------+------------+-----------+------------+---------+---------+
 | participant                       |  rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-----------------------------------+------------+-----------+------------+---------+---------+
 | Data::Cmp::StrOrNumeric::cmp_data |     831170 |    1203.1 |      1     | 1.2e-11 |      20 |
 | Data::Cmp::cmp_data               |    1100000 |     900   |      1.3   | 1.7e-09 |      20 |
 | Scalar::Cmp::cmpstrornum_scalar   |    1127000 |     887.2 |      1.356 | 4.2e-11 |      20 |
 | Data::Cmp::Numeric::cmp_data      |    1200000 |     870   |      1.4   | 1.3e-09 |      20 |
 | Scalar::Cmp::cmp_scalar           |    1500000 |     680   |      1.8   | 4.1e-09 |      21 |
 | Scalar::Cmp::cmpnum_scalar        |    1600000 |     630   |      1.9   | 1.8e-09 |      21 |
 | <=>                               |  300000000 |       3   |    400     | 5.7e-10 |      22 |
 | cmp                               | -400000000 |      -2   |   -500     |   2e-10 |      20 |
 +-----------------------------------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ScalarCmp --module-startup >>):

 #table2#
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | Data::Cmp::Numeric      |       9.5 |                    5.5 |        1   | 7.2e-05 |      20 |
 | Data::Cmp::StrOrNumeric |       8.7 |                    4.7 |        1.1 | 1.3e-05 |      20 |
 | Scalar::Cmp             |       8.7 |                    4.7 |        1.1 | 3.2e-05 |      20 |
 | Data::Cmp               |       8.6 |                    4.6 |        1.1 |   3e-05 |      21 |
 | perl -e1 (baseline)     |       4   |                    0   |        2.4 | 1.1e-05 |      20 |
 +-------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ScalarCmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ScalarCmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ScalarCmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::DataCmp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
