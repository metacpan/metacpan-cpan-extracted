package Bencher::Scenario::NormalRandom;

our $DATE = '2018-09-03'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark generating normally distributed random numbers',
    description => <<'_',

Each participant generates 1000 random numbers that are normally distributed. If
a module accepts a range, we use [0, 1]. If a module accepts distribution
parameters mean and standard deviation, we use 0.5 and 0.25 respectively.

_
    participants => [
        {
            module => 'Math::Random::GaussianRange',
            code_template => 'Math::Random::GaussianRange::generate_normal_range({min=>0, max=>1, n=>1000, round=>0})',
        },
        {
            module => 'Math::Random::NormalDistribution',
            code_template => 'my $gen = Math::Random::NormalDistribution::rand_nd_generator(0.5, 0.25); [map {$gen->()} 1..1000]',
        },
        {
            module => 'Math::Random::OO::Normal',
            code_template => 'my $oo = Math::Random::OO::Normal->new(0.5, 0.25); [map {$oo->next} 1..1000]',
        },
    ],
};

1;
# ABSTRACT: Benchmark generating normally distributed random numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::NormalRandom - Benchmark generating normally distributed random numbers

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::NormalRandom (from Perl distribution Bencher-Scenario-NormalRandom), released on 2018-09-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m NormalRandom

To run module startup overhead benchmark:

 % bencher --module-startup -m NormalRandom

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each participant generates 1000 random numbers that are normally distributed. If
a module accepts a range, we use [0, 1]. If a module accepts distribution
parameters mean and standard deviation, we use 0.5 and 0.25 respectively.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Math::Random::GaussianRange>

L<Math::Random::NormalDistribution> 0.01

L<Math::Random::OO::Normal> 0.22

=head1 BENCHMARK PARTICIPANTS

=over

=item * Math::Random::GaussianRange (perl_code)

Code template:

 Math::Random::GaussianRange::generate_normal_range({min=>0, max=>1, n=>1000, round=>0})



=item * Math::Random::NormalDistribution (perl_code)

Code template:

 my $gen = Math::Random::NormalDistribution::rand_nd_generator(0.5, 0.25); [map {$gen->()} 1..1000]



=item * Math::Random::OO::Normal (perl_code)

Code template:

 my $oo = Math::Random::OO::Normal->new(0.5, 0.25); [map {$oo->next} 1..1000]



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m NormalRandom >>):

 #table1#
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | participant                      | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------------------+-----------+-----------+------------+---------+---------+
 | Math::Random::OO::Normal         |       345 |     2.9   |       1    | 1.8e-06 |      20 |
 | Math::Random::GaussianRange      |      1300 |     0.77  |       3.8  | 9.1e-07 |      20 |
 | Math::Random::NormalDistribution |      2260 |     0.442 |       6.56 | 2.1e-07 |      20 |
 +----------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m NormalRandom --module-startup >>):

 #table2#
 +----------------------------------+-----------+------------------------+------------+-----------+---------+
 | participant                      | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +----------------------------------+-----------+------------------------+------------+-----------+---------+
 | Math::Random::GaussianRange      |      34   |                   27.9 |        1   | 7.2e-05   |      20 |
 | Math::Random::OO::Normal         |      22   |                   15.9 |        1.5 | 9.4e-05   |      20 |
 | Math::Random::NormalDistribution |      10   |                    3.9 |        3   |   0.00012 |      20 |
 | perl -e1 (baseline)              |       6.1 |                    0   |        5.5 | 5.6e-05   |      20 |
 +----------------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-NormalRandom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-NormalRandom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-NormalRandom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
