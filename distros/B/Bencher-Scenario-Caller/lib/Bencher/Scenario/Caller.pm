package Bencher::Scenario::Caller;

our $DATE = '2019-04-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark some variations of caller()',
    participants => [
        {
            name => 'CORE::caller() (scalar)',
            code_template => 'CORE::caller()',
        },
        {
            name => 'CORE::caller() (list)',
            code_template => 'CORE::caller()',
            result_is_list => 1,
        },
        {
            name => 'CORE::caller(0)',
            code_template => 'CORE::caller(0)',
            result_is_list => 1,
        },
        {
            name => 'CORE::caller(1)',
            code_template => 'CORE::caller(1)',
            result_is_list => 1,
        },
        {
            name => 'CORE::caller(2)',
            code_template => 'CORE::caller(2)',
            result_is_list => 1,
        },

        {
            name => 'Devel::Caller::Util::caller(0)',
            module => 'Devel::Caller::Util',
            code_template => 'Devel::Caller::Util::caller(0)',
            result_is_list => 1,
        },
        {
            name => 'Devel::Caller::Util::caller(1)',
            module => 'Devel::Caller::Util',
            code_template => 'Devel::Caller::Util::caller(1)',
            result_is_list => 1,
        },
        {
            name => 'Devel::Caller::Util::caller(2)',
            module => 'Devel::Caller::Util',
            code_template => 'Devel::Caller::Util::caller(2)',
            result_is_list => 1,
        },
        {
            name => 'Devel::Caller::Util::caller(0) with-args',
            module => 'Devel::Caller::Util',
            code_template => 'Devel::Caller::Util::caller(0, 1)',
            result_is_list => 1,
        },
        {
            name => 'Devel::Caller::Util::caller(0) with-packages-to-ignore=re',
            module => 'Devel::Caller::Util',
            code_template => 'Devel::Caller::Util::caller(0, 0, qr/^Bencher::Scenario$/)',
            result_is_list => 1,
        },
    ],
};

1;
# ABSTRACT: Benchmark some variations of caller()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Caller - Benchmark some variations of caller()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Caller (from Perl distribution Bencher-Scenario-Caller), released on 2019-04-14.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Caller

To run module startup overhead benchmark:

 % bencher --module-startup -m Caller

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Devel::Caller::Util> 0.042

=head1 BENCHMARK PARTICIPANTS

=over

=item * CORE::caller() (scalar) (perl_code)

Code template:

 CORE::caller()



=item * CORE::caller() (list) (perl_code)

Code template:

 CORE::caller()



=item * CORE::caller(0) (perl_code)

Code template:

 CORE::caller(0)



=item * CORE::caller(1) (perl_code)

Code template:

 CORE::caller(1)



=item * CORE::caller(2) (perl_code)

Code template:

 CORE::caller(2)



=item * Devel::Caller::Util::caller(0) (perl_code)

Code template:

 Devel::Caller::Util::caller(0)



=item * Devel::Caller::Util::caller(1) (perl_code)

Code template:

 Devel::Caller::Util::caller(1)



=item * Devel::Caller::Util::caller(2) (perl_code)

Code template:

 Devel::Caller::Util::caller(2)



=item * Devel::Caller::Util::caller(0) with-args (perl_code)

Code template:

 Devel::Caller::Util::caller(0, 1)



=item * Devel::Caller::Util::caller(0) with-packages-to-ignore=re (perl_code)

Code template:

 Devel::Caller::Util::caller(0, 0, qr/^Bencher::Scenario$/)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m Caller >>):

 #table1#
 +-----------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                                               | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------------------------------+-----------+-----------+------------+---------+---------+
 | Devel::Caller::Util::caller(2)                            |    100000 |     9.7   |        1   | 9.8e-09 |      21 |
 | Devel::Caller::Util::caller(1)                            |    150000 |     6.8   |        1.4 |   1e-08 |      20 |
 | Devel::Caller::Util::caller(0) with-args                  |    230000 |     4.3   |        2.3 | 8.3e-09 |      20 |
 | Devel::Caller::Util::caller(0) with-packages-to-ignore=re |    200000 |     4     |        2   |   2e-07 |      20 |
 | Devel::Caller::Util::caller(0)                            |    280000 |     3.6   |        2.7 | 2.1e-08 |      20 |
 | CORE::caller(1)                                           |  23000000 |     0.043 |      230   | 2.9e-10 |      20 |
 | CORE::caller(0)                                           |  24000000 |     0.042 |      230   |   1e-10 |      22 |
 | CORE::caller(2)                                           |  25000000 |     0.04  |      240   | 5.8e-11 |      20 |
 | CORE::caller() (scalar)                                   |  25000000 |     0.039 |      250   | 1.2e-10 |      20 |
 | CORE::caller() (list)                                     |  27000000 |     0.038 |      260   | 2.4e-10 |      24 |
 +-----------------------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Caller --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Devel::Caller::Util |        10 |                      2 |          1 | 0.00022 |      22 |
 | perl -e1 (baseline) |         8 |                      0 |          2 | 0.0001  |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Caller>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Caller>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Caller>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
