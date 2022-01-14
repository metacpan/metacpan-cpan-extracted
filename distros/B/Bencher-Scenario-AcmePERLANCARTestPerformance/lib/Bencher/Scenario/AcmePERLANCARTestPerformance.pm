package Bencher::Scenario::AcmePERLANCARTestPerformance;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.060'; # VERSION

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

This document describes version 0.060 of Bencher::Scenario::AcmePERLANCARTestPerformance (from Perl distribution Bencher-Scenario-AcmePERLANCARTestPerformance), released on 2021-07-31.

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

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command:

 % bencher -m AcmePERLANCARTestPerformance --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.01 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.02 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.03 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.04 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.05 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.06 --multimodver Acme::PERLANCAR::Test::Performance

Result formatted as table:

 #table1#
 | participant                                | dataset | perl | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples | ds_tags | p_tags |
 |--------------------------------------------+---------+------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+---------+--------|
 | Acme::PERLANCAR::Test::Performance::primes | 100     | perl | 0.06   |    108000 |      9.24 |                 0.00% |                 0.00% | 3.3e-09 |      20 |         |        |


The above result formatted in L<Benchmark.pm|Benchmark> style:

         Rate     
     108000/s  -- 
 
 Legends:
   : dataset=100 ds_tags= modver=0.06 p_tags= participant=Acme::PERLANCAR::Test::Performance::primes perl=perl

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command:

 % bencher -m AcmePERLANCARTestPerformance --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.01 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.02 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.03 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.04 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.05 --include-path /home/s1/repos/perl-Acme-PERLANCAR-Test-Performance/archive/0.06 --module-startup --multimodver Acme::PERLANCAR::Test::Performance

Result formatted as table:

 #table2#
 | participant                        | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors  | samples |
 |------------------------------------+-----------+-------------------+-----------------------+-----------------------+----------+---------|
 | Acme::PERLANCAR::Test::Performance |       5.5 |               3.5 |                 0.00% |               166.32% | 4.8e-05  |      20 |
 | perl -e1 (baseline)                |       2   |               0   |               166.32% |                 0.00% |   0.0001 |      33 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  APT:P  perl -e1 (baseline) 
  APT:P                181.8/s     --                 -63% 
  perl -e1 (baseline)  500.0/s   175%                   -- 
 
 Legends:
   APT:P: mod_overhead_time=3.5 participant=Acme::PERLANCAR::Test::Performance
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-zenbook-ux305)

perlancar (on netbook-zenbook-ux305) <perlancar@gmail.com>

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

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
