package Bencher::Scenario::RandomNumbers;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-28'; # DATE
our $DIST = 'Bencher-Scenario-RandomNumbers'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark some random number generation',
    participants => [
        {
            name => 'CORE::rand',
            code_template=>'CORE::rand()',
        },
        {
            fcall_template=>'Data::Entropy::Algorithms::rand()',
        },
        {
            fcall_template=>'Math::LogRand::LogRand(999,9999)',
        },
        {
            fcall_template=>'Math::Random::MT::rand()',
        },
        {
            fcall_template=>'Math::Random::LogUniform::logirand(1000,10000)',
        },
    ],
};

1;
# ABSTRACT: Benchmark some random number generation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RandomNumbers - Benchmark some random number generation

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::RandomNumbers (from Perl distribution Bencher-Scenario-RandomNumbers), released on 2023-12-28.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RandomNumbers

To run module startup overhead benchmark:

 % bencher --module-startup -m RandomNumbers

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Entropy::Algorithms> 0.007

L<Math::LogRand> 0.05

L<Math::Random::MT> 1.17

L<Math::Random::LogUniform> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * CORE::rand (perl_code)

Code template:

 CORE::rand()



=item * Data::Entropy::Algorithms::rand (perl_code)

Function call template:

 Data::Entropy::Algorithms::rand()



=item * Math::LogRand::LogRand (perl_code)

Function call template:

 Math::LogRand::LogRand(999,9999)



=item * Math::Random::MT::rand (perl_code)

Function call template:

 Math::Random::MT::rand()



=item * Math::Random::LogUniform::logirand (perl_code)

Function call template:

 Math::Random::LogUniform::logirand(1000,10000)



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m RandomNumbers

Result formatted as table:

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Data::Entropy::Algorithms::rand    |     40000 |    25     |                 0.00% |            166731.76% | 8.7e-08 |      21 |
 | Math::LogRand::LogRand             |   2250000 |     0.444 |              5597.56% |              2828.13% | 9.8e-11 |      20 |
 | Math::Random::LogUniform::logirand |   3150000 |     0.317 |              7871.53% |              1992.84% | 3.8e-11 |      20 |
 | Math::Random::MT::rand             |   3180000 |     0.315 |              7946.24% |              1973.41% | 5.1e-11 |      20 |
 | CORE::rand                         |  66000000 |     0.015 |            166731.76% |                 0.00% | 8.5e-11 |      21 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

               Rate    DEA:r   ML:L  MRL:l  MRM:r   C:r 
  DEA:r     40000/s       --   -98%   -98%   -98%  -99% 
  ML:L    2250000/s    5530%     --   -28%   -29%  -96% 
  MRL:l   3150000/s    7786%    40%     --     0%  -95% 
  MRM:r   3180000/s    7836%    40%     0%     --  -95% 
  C:r    66000000/s  166566%  2860%  2013%  2000%    -- 
 
 Legends:
   C:r: participant=CORE::rand
   DEA:r: participant=Data::Entropy::Algorithms::rand
   ML:L: participant=Math::LogRand::LogRand
   MRL:l: participant=Math::Random::LogUniform::logirand
   MRM:r: participant=Math::Random::MT::rand

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m RandomNumbers --module-startup

Result formatted as table:

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Entropy::Algorithms |        20 |                14 |                 0.00% |               240.00% | 3.6e-05 |      20 |
 | Math::LogRand             |        18 |                12 |                13.28% |               200.15% | 1.9e-05 |      20 |
 | Math::Random::LogUniform  |        16 |                10 |                23.46% |               175.40% | 1.9e-05 |      20 |
 | Math::Random::MT          |        14 |                 8 |                45.21% |               134.15% | 3.2e-05 |      20 |
 | perl -e1 (baseline)       |         6 |                 0 |               240.00% |                 0.00% | 1.3e-05 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  DE:A   M:L  MR:L  MR:M  perl -e1 (baseline) 
  DE:A                  50.0/s    --   -9%  -19%  -30%                 -70% 
  M:L                   55.6/s   11%    --  -11%  -22%                 -66% 
  MR:L                  62.5/s   25%   12%    --  -12%                 -62% 
  MR:M                  71.4/s   42%   28%   14%    --                 -57% 
  perl -e1 (baseline)  166.7/s  233%  200%  166%  133%                   -- 
 
 Legends:
   DE:A: mod_overhead_time=14 participant=Data::Entropy::Algorithms
   M:L: mod_overhead_time=12 participant=Math::LogRand
   MR:L: mod_overhead_time=10 participant=Math::Random::LogUniform
   MR:M: mod_overhead_time=8 participant=Math::Random::MT
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RandomNumbers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RandomNumbers>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RandomNumbers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
