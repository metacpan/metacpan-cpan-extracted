package Bencher::Scenario::HashBuilding;

our $DATE = '2016-09-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark building hash by adding one key at a time vs building via array',
    participants => [
        {
            name=>'one-key-at-a-time',
            code_template=>'state $keys=<keys>; my $hash = {}; for my $key (@$keys) { $hash->{$key} = 1 }; $hash',
        },
        {
            name=>'via-array',
            code_template=>'state $keys=<keys>; my $hash = {}; my $ary = []; for my $key (@$keys) { push @$ary, $key, 1 }; $hash = { @$ary }',
        },
    ],
    datasets => [
        {name=>'keys=1'    , args=>{keys=>[1]}},
        {name=>'keys=10'   , args=>{keys=>[1..10]}},
        {name=>'keys=100'  , args=>{keys=>[1..100]}},
        {name=>'keys=1000' , args=>{keys=>[1..1000]}},
        {name=>'keys=10000', args=>{keys=>[1..10000]}},
    ],
};

1;
# ABSTRACT: Benchmark building hash by adding one key at a time vs building via array

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HashBuilding - Benchmark building hash by adding one key at a time vs building via array

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::HashBuilding (from Perl distribution Bencher-Scenario-HashBuilding), released on 2016-09-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HashBuilding

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * one-key-at-a-time (perl_code)

Code template:

 state $keys=<keys>; my $hash = {}; for my $key (@$keys) { $hash->{$key} = 1 }; $hash



=item * via-array (perl_code)

Code template:

 state $keys=<keys>; my $hash = {}; my $ary = []; for my $key (@$keys) { push @$ary, $key, 1 }; $hash = { @$ary }



=back

=head1 BENCHMARK DATASETS

=over

=item * keys=1

=item * keys=10

=item * keys=100

=item * keys=1000

=item * keys=10000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m HashBuilding >>):

 #table1#
 +-------------------+------------+-----------+-------------+------------+---------+---------+
 | participant       | dataset    | rate (/s) |   time (ms) | vs_slowest |  errors | samples |
 +-------------------+------------+-----------+-------------+------------+---------+---------+
 | via-array         | keys=10000 |       285 | 3.51        |      1     | 1.6e-06 |      21 |
 | one-key-at-a-time | keys=10000 |       500 | 2           |      1.7   | 2.5e-06 |      20 |
 | via-array         | keys=1000  |      3020 | 0.332       |     10.6   | 2.7e-07 |      20 |
 | one-key-at-a-time | keys=1000  |      5800 | 0.17        |     21     | 2.1e-07 |      20 |
 | via-array         | keys=100   |     30000 | 0.033       |    110     | 5.3e-08 |      20 |
 | one-key-at-a-time | keys=100   |     68500 | 0.0146      |    240     | 6.7e-09 |      20 |
 | via-array         | keys=10    |    276692 | 0.00361412  |    970.282 |   0     |      22 |
 | one-key-at-a-time | keys=10    |    628200 | 0.001592    |   2203     | 3.4e-11 |      20 |
 | via-array         | keys=1     |   1215950 | 0.000822402 |   4264     |   0     |      20 |
 | one-key-at-a-time | keys=1     |   2484000 | 0.0004027   |   8709     | 9.6e-12 |      20 |
 +-------------------+------------+-----------+-------------+------------+---------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-HashBuilding>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-HashBuilding>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-HashBuilding>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
