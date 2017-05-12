package Bencher::Scenario::BitManipulation::Set;

our $DATE = '2017-01-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark setting bits',
    participants => [
        {
            name => '1k-vec-data=1byte-set=1bit',
            code_template => 'state $data = "\0"; for(1..1000) { vec($data, 4, 1) = 1 }'
        },
        {
            name => '1k-vec-data=1byte-set=3bit',
            code_template => 'state $data = "\0"; for(1..1000) { vec($data, 4, 4) = 0b1011 }'
        },
        {
            name => '1k-bit_on-data=1byte-set=1bit',
            module => 'Bit::Manip',
            code_template => 'state $data = 0; for(1..1000) { $data = Bit::Manip::bit_on($data, 3) }'
        },
        {
            name => '1k-bit_on-pp-data=1byte-set=1bit',
            module => 'Bit::Manip::PP',
            code_template => 'state $data = 0; for(1..1000) { $data = Bit::Manip::PP::bit_on($data, 3) }'
        },
    ],
};

1;
# ABSTRACT: Benchmark setting bits

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BitManipulation::Set - Benchmark setting bits

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::BitManipulation::Set (from Perl distribution Bencher-Scenarios-BitManipulation), released on 2017-01-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BitManipulation::Set

To run module startup overhead benchmark:

 % bencher --module-startup -m BitManipulation::Set

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Bit::Manip> 1.01

L<Bit::Manip::PP> 1.00

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-vec-data=1byte-set=1bit (perl_code)

Code template:

 state $data = "\0"; for(1..1000) { vec($data, 4, 1) = 1 }



=item * 1k-vec-data=1byte-set=3bit (perl_code)

Code template:

 state $data = "\0"; for(1..1000) { vec($data, 4, 4) = 0b1011 }



=item * 1k-bit_on-data=1byte-set=1bit (perl_code)

Code template:

 state $data = 0; for(1..1000) { $data = Bit::Manip::bit_on($data, 3) }



=item * 1k-bit_on-pp-data=1byte-set=1bit (perl_code)

Code template:

 state $data = 0; for(1..1000) { $data = Bit::Manip::PP::bit_on($data, 3) }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m BitManipulation::Set >>):

 #table1#
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | 1k-vec-data=1byte-set=3bit       |  3656.548 |  273.482  |   1        | 9.5e-12 |      22 |
 | 1k-vec-data=1byte-set=1bit       |  3659.872 |  273.2336 |   1.000909 | 9.5e-12 |      29 |
 | 1k-bit_on-data=1byte-set=1bit    |  3891.724 |  256.9555 |   1.064316 |   1e-11 |      20 |
 | 1k-bit_on-pp-data=1byte-set=1bit |  4854.13  |  206.01   |   1.32752  | 4.7e-11 |      20 |
 +----------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m BitManipulation::Set --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Bit::Manip          | 844                          | 4.1                | 16             |       9.1 |                    3.6 |        1   | 2.4e-05 |      21 |
 | Bit::Manip::PP      | 1044                         | 4.5                | 18             |       8.8 |                    3.3 |        1   | 1.7e-05 |      20 |
 | perl -e1 (baseline) | 844                          | 4.2                | 16             |       5.5 |                    0   |        1.6 | 1.5e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Differences between C<vec()> and L<Bit::Manip> routines:

=over

=item * C<vec()> counts bit position from left, while Bit::Manip from right

=item * C<vec()> works with binary data, while Bit::Manip expects numbers

=item * Bit::Manip currently supports only 32-bit number while C<vec()> far more than that

=item * Bit::Manip provides convenience functions for toggling, masking, shifting, and bit counting

=item * C<vec()> provides convenience when setting multiple bits in one go

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-BitManipulation>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-BitManipulation>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-BitManipulation>

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
