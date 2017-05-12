package Bencher::Scenario::MathPrimeModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark modules that find prime numbers',
    modules => {
    },
    participants => [
        {
            module => 'Acme::PERLANCAR::Prime',
            code_template => 'Acme::PERLANCAR::Prime::_empty_cache(); Acme::PERLANCAR::Prime::primes(<num>)',
            result_is_list => 1,
        },

        {
            fcall_template => 'Math::Prime::Util::erat_primes(2,<num>)',
        },

        {
            module => 'Math::Prime::FastSieve',
            function => 'primes',
            code_template => 'Math::Prime::FastSieve->import(); Inline->init(); my $sieve = Math::Prime::FastSieve::Sieve->new(<num>); $sieve->primes(<num>)',
        },

        {
            fcall_template => 'Math::Prime::XS::primes(<num>)',
            result_is_list => 1,
        },
    ],

    precision => 6,

    datasets => [
        # just for testing correctness
        {args=>{num=>100}, result=>[2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97]},

        {args=>{num=>1000_000}},
    ],
};

1;
# ABSTRACT: Benchmark modules that find prime numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MathPrimeModules - Benchmark modules that find prime numbers

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::MathPrimeModules (from Perl distribution Bencher-Scenario-MathPrimeModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MathPrimeModules

To run module startup overhead benchmark:

 % bencher --module-startup -m MathPrimeModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Acme::PERLANCAR::Prime> 0.001

L<Math::Prime::FastSieve> 0.19

L<Math::Prime::Util> 0.59

L<Math::Prime::XS> 0.27

=head1 BENCHMARK PARTICIPANTS

=over

=item * Acme::PERLANCAR::Prime (perl_code)

Code template:

 Acme::PERLANCAR::Prime::_empty_cache(); Acme::PERLANCAR::Prime::primes(<num>)



=item * Math::Prime::Util::erat_primes (perl_code)

Function call template:

 Math::Prime::Util::erat_primes(2,<num>)



=item * Math::Prime::FastSieve::primes (perl_code)

Code template:

 Math::Prime::FastSieve->import(); Inline->init(); my $sieve = Math::Prime::FastSieve::Sieve->new(<num>); $sieve->primes(<num>)



=item * Math::Prime::XS::primes (perl_code)

Function call template:

 Math::Prime::XS::primes(<num>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 100

=item * 1000000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m MathPrimeModules --exclude-dataset-names 100 >>:

 #table1#
 +--------------------------------+-----------+--------+------------+-----------+---------+
 | participant                    | rate (/s) |   time | vs_slowest |  errors   | samples |
 +--------------------------------+-----------+--------+------------+-----------+---------+
 | Acme::PERLANCAR::Prime         |      0.48 | 2.1    |          1 |   0.018   |       6 |
 | Math::Prime::XS::primes        |    100    | 0.009  |        200 |   0.00011 |       6 |
 | Math::Prime::FastSieve::primes |    100    | 0.008  |        300 |   0.00021 |       7 |
 | Math::Prime::Util::erat_primes |    200    | 0.0051 |        410 | 1.6e-05   |       7 |
 +--------------------------------+-----------+--------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m MathPrimeModules --module-startup >>):

 #table2#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant            | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Math::Prime::FastSieve | 2.3                          | 5.7                | 24             |        34 |                     27 |        1   |   0.00022 |       6 |
 | Math::Prime::XS        | 0.82                         | 4.1                | 16             |        25 |                     18 |        1.4 |   0.00021 |       6 |
 | Math::Prime::Util      | 3.7                          | 7                  | 23             |        19 |                     12 |        1.8 |   0.00013 |       6 |
 | Acme::PERLANCAR::Prime | 2.3                          | 6.1                | 20             |        11 |                      4 |        3.2 | 5.2e-05   |       7 |
 | perl -e1 (baseline)    | 0.9                          | 4                  | 20             |         7 |                      0 |        5   | 9.9e-05   |       6 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-MathPrimeModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-MathPrimeModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-MathPrimeModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://blogs.perl.org/users/dana_jacobsen/2014/08/a-comparison-of-memory-use-for-primality-modules.html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
