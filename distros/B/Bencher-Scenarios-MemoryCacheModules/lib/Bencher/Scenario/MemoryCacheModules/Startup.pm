package Bencher::Scenario::MemoryCacheModules::Startup;

our $DATE = '2018-06-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of memory cache modules',
    participants => [
        {
            module => 'Cache::Memory::Simple',
            code_template => 'Cache::Memory::Simple->new',
        },
        {
            module => 'CHI',
            code_template => 'CHI->new(driver=>"Memory", global=>1)',
        },
        {
            module => 'Tie::Cache',
            code_template => 'tie %cache, "Tie::Cache", 100',
        },
    ],
    code_startup => 1,
};

1;
# ABSTRACT: Benchmark startup overhead of memory cache modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MemoryCacheModules::Startup - Benchmark startup overhead of memory cache modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::MemoryCacheModules::Startup (from Perl distribution Bencher-Scenarios-MemoryCacheModules), released on 2018-06-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MemoryCacheModules::Startup

To run module startup overhead benchmark:

 % bencher --module-startup -m MemoryCacheModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Cache::Memory::Simple> 1.03

L<CHI> 0.60

L<Tie::Cache> 0.21

=head1 BENCHMARK PARTICIPANTS

=over

=item * Cache::Memory::Simple (perl_code)

Code template:

 Cache::Memory::Simple->new



=item * CHI (perl_code)

Code template:

 CHI->new(driver=>"Memory", global=>1)



=item * Tie::Cache (perl_code)

Code template:

 tie %cache, "Tie::Cache", 100



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m MemoryCacheModules::Startup >>):

 #table1#
 +-----------------------+-----------+-------------------------+------------+-----------+---------+
 | participant           | time (ms) | code_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------+-----------+-------------------------+------------+-----------+---------+
 | CHI                   |      87.4 |                    80.8 |        1   | 7.5e-05   |      20 |
 | Cache::Memory::Simple |      13   |                     6.4 |        6.5 |   0.00012 |      24 |
 | Tie::Cache            |       9.4 |                     2.8 |        9.3 | 1.1e-05   |      20 |
 | perl -e1 (baseline)   |       6.6 |                     0   |       13   | 3.6e-05   |      23 |
 +-----------------------+-----------+-------------------------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m MemoryCacheModules::Startup --module-startup >>):

 #table2#
 +-----------------------+-----------+-------------------------+------------------------+------------+---------+---------+
 | participant           | time (ms) | code_overhead_time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+-----------+-------------------------+------------------------+------------+---------+---------+
 | CHI                   |      53.4 |                    47.6 |                   47.6 |        1   | 3.5e-05 |      20 |
 | Cache::Memory::Simple |      12   |                     6.2 |                    6.2 |        4.6 | 1.5e-05 |      20 |
 | Tie::Cache            |       9.3 |                     3.5 |                    3.5 |        5.7 | 1.1e-05 |      20 |
 | perl -e1 (baseline)   |       5.8 |                     0   |                    0   |        9.2 | 1.1e-05 |      20 |
 +-----------------------+-----------+-------------------------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-MemoryCacheModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-MemoryCacheModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-MemoryCacheModules>

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
