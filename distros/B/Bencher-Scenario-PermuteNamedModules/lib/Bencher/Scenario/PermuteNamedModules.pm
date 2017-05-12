package Bencher::Scenario::PermuteNamedModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various modules doing permutation of multiple-valued key-value pairs',
    participants => [
        {
            module => "PERLANCAR::Permute::Named",
            code => sub {
                my @res = PERLANCAR::Permute::Named::permute_named(@_);
            },
        },
        {
            module => "Permute::Named",
            code => sub {
                my @res = Permute::Named::permute_named(@_);
            },
        },
        {
            module => "Permute::Named::Iter",
            code => sub {
                my $iter = Permute::Named::Iter::permute_named_iter(@_);
                my @res;
                while (my $h = $iter->()) { push @res, $h }
            },
        },
    ],
    datasets => [
        {argv=>[a=>[1,2], b=>[1,2,3]], name=>'small (2x3=6)'},
        {argv=>[a=>[1,2], b=>[1..50]], name=>'long (2x50=100)'},
        {argv=>[a=>[1,2], a=>[1,2], c=>[1,2], d=>[1,2], e=>[1,2], f=>[1,2], g=>[1,2], h=>[1,2], i=>[1,2], j=>[1,2]], name=>'wide (2**10=1k)'},
        {argv=>[a=>[1..10], b=>[1..10], c=>[1..10], d=>[1..2], e=>[1..2], f=>[1..3]], name=>'large (10x10x10x2x2x3=12ki)'},
    ],
};

1;
# ABSTRACT: Benchmark various modules doing permutation of multiple-valued key-value pairs

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PermuteNamedModules - Benchmark various modules doing permutation of multiple-valued key-value pairs

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::PermuteNamedModules (from Perl distribution Bencher-Scenario-PermuteNamedModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PermuteNamedModules

To run module startup overhead benchmark:

 % bencher --module-startup -m PermuteNamedModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Permute::Named> 0.03

L<Permute::Named> 1.100980

L<Permute::Named::Iter> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Permute::Named (perl_code)

L<PERLANCAR::Permute::Named>



=item * Permute::Named (perl_code)

L<Permute::Named>



=item * Permute::Named::Iter (perl_code)

L<Permute::Named::Iter>



=back

=head1 BENCHMARK DATASETS

=over

=item * small (2x3=6)

=item * long (2x50=100)

=item * wide (2**10=1k)

=item * large (10x10x10x2x2x3=12ki)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PermuteNamedModules >>):

 #table1#
 +---------------------------+-----------------------------+-----------+-----------+------------+-----------+---------+
 | participant               | dataset                     | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+-----------------------------+-----------+-----------+------------+-----------+---------+
 | Permute::Named            | large (10x10x10x2x2x3=12ki) |      8.89 |   112     |        1   |   0.00011 |      20 |
 | PERLANCAR::Permute::Named | large (10x10x10x2x2x3=12ki) |     28    |    36     |        3.2 |   0.00019 |      20 |
 | Permute::Named::Iter      | large (10x10x10x2x2x3=12ki) |     31    |    32     |        3.5 | 8.8e-05   |      20 |
 | Permute::Named            | wide (2**10=1k)             |     67    |    15     |        7.5 |   0.00014 |      20 |
 | PERLANCAR::Permute::Named | wide (2**10=1k)             |    210    |     4.7   |       24   | 3.4e-05   |      21 |
 | Permute::Named::Iter      | wide (2**10=1k)             |    240    |     4.18  |       26.9 | 2.9e-06   |      20 |
 | Permute::Named            | long (2x50=100)             |   2910    |     0.344 |      327   | 2.5e-07   |      22 |
 | PERLANCAR::Permute::Named | long (2x50=100)             |   5600    |     0.18  |      630   | 4.1e-07   |      27 |
 | Permute::Named::Iter      | long (2x50=100)             |   7800    |     0.13  |      880   | 2.1e-07   |      20 |
 | PERLANCAR::Permute::Named | small (2x3=6)               |  20000    |     0.05  |     2000   | 7.7e-07   |      20 |
 | Permute::Named            | small (2x3=6)               |  20000    |     0.051 |     2200   | 9.7e-08   |      24 |
 | Permute::Named::Iter      | small (2x3=6)               |  73000    |     0.014 |     8200   | 5.1e-08   |      22 |
 +---------------------------+-----------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m PermuteNamedModules --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Permute::Named            | 0.93                         | 4.3                | 16             |        21 |                     10 |        1   | 4.7e-05 |      21 |
 | PERLANCAR::Permute::Named | 1.8                          | 5.2                | 21             |        15 |                      4 |        1.4 | 9.4e-05 |      20 |
 | Permute::Named::Iter      | 0.82                         | 4.1                | 16             |        14 |                      3 |        1.4 |   7e-05 |      20 |
 | perl -e1 (baseline)       | 0.93                         | 4.3                | 16             |        11 |                      0 |        1.9 | 1.8e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-PermuteNamedModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-PermuteNamedModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-PermuteNamedModules>

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
