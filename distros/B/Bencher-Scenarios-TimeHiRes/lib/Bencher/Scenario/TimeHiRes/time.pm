package Bencher::Scenario::TimeHiRes::time;

our $DATE = '2018-12-21'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark getting current time',
    modules => {
    },
    participants => [
        {
            fcall_template => 'Time::HiRes::time',
        },
        {
            name => 'CORE::time',
            code_template => 'time()',
        },
        {
            fcall_template => 'Time::HiRes::tv_interval',
        },
    ],
};

1;
# ABSTRACT: Benchmark getting current time

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TimeHiRes::time - Benchmark getting current time

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::TimeHiRes::time (from Perl distribution Bencher-Scenarios-TimeHiRes), released on 2018-12-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TimeHiRes::time

To run module startup overhead benchmark:

 % bencher --module-startup -m TimeHiRes::time

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Time::HiRes> 1.9741

=head1 BENCHMARK PARTICIPANTS

=over

=item * Time::HiRes::time (perl_code)

Function call template:

 Time::HiRes::time



=item * CORE::time (perl_code)

Code template:

 time()



=item * Time::HiRes::tv_interval (perl_code)

Function call template:

 Time::HiRes::tv_interval



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m TimeHiRes::time >>):

 #table1#
 +--------------------------+-----------+-----------+------------+---------+---------+
 | participant              | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +--------------------------+-----------+-----------+------------+---------+---------+
 | Time::HiRes::tv_interval |   1200000 |     850   |        1   | 1.7e-09 |      20 |
 | Time::HiRes::time        |  12300000 |      81.6 |       10.5 | 6.9e-11 |      20 |
 | CORE::time               | 200000000 |       6   |      100   | 2.1e-10 |      20 |
 +--------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TimeHiRes::time --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Time::HiRes         |        12 |                      7 |        1   | 2.8e-05 |      20 |
 | perl -e1 (baseline) |         5 |                      0 |        2.4 | 3.8e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Use floating-point time(), because tv_interval() is about 1 order of magnitude
slower!

Ref: David Golden's TPC 2017 talk "Real World Optimization"
L<https://www.youtube.com/watch?v=_PJIVVGAZqA>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TimeHiRes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TimeHiRes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TimeHiRes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
