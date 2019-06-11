package Bencher::Scenario::FileWhichCached;

our $DATE = '2019-06-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark File::Which::Cached',

    participants => [
        {fcall_template=>'File::Which::which("ls")'},
        {fcall_template=>'File::Which::Cached::which("ls")'},
    ],
};

1;
# ABSTRACT: Benchmark File::Which::Cached

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FileWhichCached - Benchmark File::Which::Cached

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::FileWhichCached (from Perl distribution Bencher-Scenario-FileWhichCached), released on 2019-06-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FileWhichCached

To run module startup overhead benchmark:

 % bencher --module-startup -m FileWhichCached

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Which> 1.22

L<File::Which::Cached> 1.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Which::which (perl_code)

Function call template:

 File::Which::which("ls")



=item * File::Which::Cached::which (perl_code)

Function call template:

 File::Which::Cached::which("ls")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m FileWhichCached >>):

 #table1#
 +----------------------------+-----------+-----------+------------+---------+---------+
 | participant                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------+-----------+-----------+------------+---------+---------+
 | File::Which::which         |     23000 |     44    |          1 | 4.4e-08 |      29 |
 | File::Which::Cached::which |   8310000 |      0.12 |        364 | 6.2e-11 |      20 |
 +----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m FileWhichCached --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | File::Which::Cached |       9.9 |                    5.9 |        1   | 2.5e-05 |      20 |
 | File::Which         |       9.7 |                    5.7 |        1   | 2.2e-05 |      20 |
 | perl -e1 (baseline) |       4   |                    0   |        2.5 | 2.1e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-FileWhichCached>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-FileWhichCached>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-FileWhichCached>

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
