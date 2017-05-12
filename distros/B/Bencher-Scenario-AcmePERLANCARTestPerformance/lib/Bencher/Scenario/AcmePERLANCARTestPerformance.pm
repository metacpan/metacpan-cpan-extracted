package Bencher::Scenario::AcmePERLANCARTestPerformance;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Acme::PERLANCAR::Test::Performance',
    participants => [
        {
            fcall_template => 'Acme::PERLANCAR::Test::Performance::primes(<num>)', result_is_list=>1,
        },
    ],
    datasets => [
        {name=>'100', args=>{num=>100}},
    ],
};

1;
# ABSTRACT: Benchmark Acme::PERLANCAR::Test::Performance

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::AcmePERLANCARTestPerformance - Benchmark Acme::PERLANCAR::Test::Performance

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::AcmePERLANCARTestPerformance (from Perl distribution Bencher-Scenario-AcmePERLANCARTestPerformance), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m AcmePERLANCARTestPerformance

To run module startup overhead benchmark:

 % bencher --module-startup -m AcmePERLANCARTestPerformance

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Acme::PERLANCAR::Test::Performance> 0.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * Acme::PERLANCAR::Test::Performance::primes (perl_code)

Function call template:

 Acme::PERLANCAR::Test::Performance::primes(<num>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m AcmePERLANCARTestPerformance --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.01 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.02 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.03 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.04 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.05 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.06 --multimodver Acme::PERLANCAR::Test::Performance >>:

 #table1#
 +--------+-----------+-----------+------------+---------+---------+
 | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +--------+-----------+-----------+------------+---------+---------+
 | 0.01   |    543    | 1.84      |    1       | 2.7e-07 |      20 |
 | 0.02   |   2816.48 | 0.355053  |    5.18631 | 5.7e-11 |      20 |
 | 0.03   |   4045.69 | 0.247177  |    7.44979 | 7.3e-11 |      20 |
 | 0.05   |  78036.3  | 0.0128145 |  143.697   |   0     |      20 |
 | 0.06   |  78300    | 0.0128    |  144       | 6.4e-09 |      22 |
 | 0.04   |  78400    | 0.0128    |  144       | 4.8e-09 |      38 |
 +--------+-----------+-----------+------------+---------+---------+


Benchmark with C<< bencher -m AcmePERLANCARTestPerformance --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.01 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.02 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.03 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.04 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.05 --include-path /home/u1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.06 --module-startup --multimodver Acme::PERLANCAR::Test::Performance >>:

 #table2#
 +------------------------------------+--------+-----------+------------------------+------------+---------+---------+
 | participant                        | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------------------+--------+-----------+------------------------+------------+---------+---------+
 | Acme::PERLANCAR::Test::Performance | 0.06   |       4.9 |                    3.2 |        1   | 1.5e-05 |      20 |
 | Acme::PERLANCAR::Test::Performance | 0.04   |       4.8 |                    3.1 |        1   |   2e-05 |      21 |
 | Acme::PERLANCAR::Test::Performance | 0.01   |       4.8 |                    3.1 |        1   | 2.5e-05 |      20 |
 | Acme::PERLANCAR::Test::Performance | 0.05   |       4.8 |                    3.1 |        1   | 3.4e-05 |      21 |
 | Acme::PERLANCAR::Test::Performance | 0.02   |       4.7 |                    3   |        1.1 | 2.1e-05 |      21 |
 | Acme::PERLANCAR::Test::Performance | 0.03   |       4.7 |                    3   |        1.1 |   4e-05 |      20 |
 | perl -e1 (baseline)                |        |       1.7 |                    0   |        2.9 | 1.1e-05 |      20 |
 +------------------------------------+--------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-AcmePERLANCARTestPerformance>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-AcmePERLANCARTestPerformance>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-AcmePERLANCARTestPerformance>

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
