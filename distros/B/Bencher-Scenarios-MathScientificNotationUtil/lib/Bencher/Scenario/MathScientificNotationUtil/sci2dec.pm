package Bencher::Scenario::MathScientificNotationUtil::sci2dec;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark sci2dec()',
    participants => [
        {
            fcall_template => 'Math::ScientificNotation::Util::sci2dec(<num>)',
        },
        {
            name => 'sprintf("%.f")',
            summary => 'As a baseline',
            code_template => 'sprintf("%.f", <num>)',
        },
        {
            name => 'sprintf("%.g")',
            summary => 'As a baseline',
            code_template => 'sprintf("%.g", <num>)',
        },
    ],
    datasets => [
        {
            args => { 'num@' => ["1.23e20", "1.23e3", "1.23e0", "1.23e-20"] },
        },
    ],
};

1;
# ABSTRACT: Benchmark sci2dec()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MathScientificNotationUtil::sci2dec - Benchmark sci2dec()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::MathScientificNotationUtil::sci2dec (from Perl distribution Bencher-Scenarios-MathScientificNotationUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MathScientificNotationUtil::sci2dec

To run module startup overhead benchmark:

 % bencher --module-startup -m MathScientificNotationUtil::sci2dec

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Math::ScientificNotation::Util> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * Math::ScientificNotation::Util::sci2dec (perl_code)

Function call template:

 Math::ScientificNotation::Util::sci2dec(<num>)



=item * sprintf("%.f") (perl_code)

As a baseline.

Code template:

 sprintf("%.f", <num>)



=item * sprintf("%.g") (perl_code)

As a baseline.

Code template:

 sprintf("%.g", <num>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ["1.23e20","1.23e3","1.23e0",1.23e-20]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m MathScientificNotationUtil::sci2dec >>):

 #table1#
 +-----------------------------------------+----------+------------+-----------+------------+---------+---------+
 | participant                             | arg_num  |  rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------------+----------+------------+-----------+------------+---------+---------+
 | Math::ScientificNotation::Util::sci2dec | 1.23e-20 |     440000 |    2.2    |        1   | 3.3e-09 |      20 |
 | Math::ScientificNotation::Util::sci2dec | 1.23e20  |     470000 |    2.1    |        1.1 | 3.3e-09 |      20 |
 | Math::ScientificNotation::Util::sci2dec | 1.23e0   |     600000 |    1.7    |        1.3 | 3.3e-09 |      20 |
 | Math::ScientificNotation::Util::sci2dec | 1.23e3   |     780000 |    1.3    |        1.7 | 1.7e-09 |      20 |
 | sprintf("%.g")                          | 1.23e20  |  100000000 |    0.0098 |      230   | 6.3e-11 |      22 |
 | sprintf("%.g")                          | 1.23e0   |  120000000 |    0.0086 |      260   | 5.7e-11 |      20 |
 | sprintf("%.g")                          | 1.23e-20 |  130000000 |    0.008  |      280   | 1.1e-11 |      20 |
 | sprintf("%.f")                          | 1.23e3   |  200000000 |    0.005  |      400   | 2.2e-10 |      23 |
 | sprintf("%.f")                          | 1.23e20  |  400000000 |    0.003  |      800   | 7.7e-10 |      27 |
 | sprintf("%.f")                          | 1.23e-20 |  550000000 |    0.0018 |     1200   |   1e-11 |      20 |
 | sprintf("%.f")                          | 1.23e0   |  790000000 |    0.0013 |     1800   | 1.1e-11 |      23 |
 | sprintf("%.g")                          | 1.23e3   | 1000000000 |    0.0009 |     3000   | 1.1e-11 |      20 |
 +-----------------------------------------+----------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m MathScientificNotationUtil::sci2dec --module-startup >>):

 #table2#
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                    | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Math::ScientificNotation::Util | 848                          | 4.1                | 16             |       6.1 |                    1.2 |        1   | 2.4e-05 |      20 |
 | perl -e1 (baseline)            | 944                          | 4.3                | 16             |       4.9 |                    0   |        1.3 | 1.3e-05 |      20 |
 +--------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-MathScientificNotationUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-MathScientificNotationUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-MathScientificNotationUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
