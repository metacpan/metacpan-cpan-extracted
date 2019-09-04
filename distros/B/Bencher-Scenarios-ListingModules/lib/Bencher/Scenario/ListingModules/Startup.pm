package Bencher::Scenario::ListingModules::Startup;

our $DATE = '2019-09-02'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark module startup',
    module_startup => 1,
    participants => [
        {
            module => 'PERLANCAR::Module::List',
        },
        {
            module => 'Module::List',
        },
        {
            module => 'Module::List::Tiny',
        },
    ],
};

1;
# ABSTRACT: Benchmark module startup

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListingModules::Startup - Benchmark module startup

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ListingModules::Startup (from Perl distribution Bencher-Scenarios-ListingModules), released on 2019-09-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListingModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Module::List> 0.004004

L<Module::List> 0.004

L<Module::List::Tiny> 0.004001

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Module::List (perl_code)

L<PERLANCAR::Module::List>



=item * Module::List (perl_code)

L<Module::List>



=item * Module::List::Tiny (perl_code)

L<Module::List::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.28.2 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m ListingModules::Startup >>):

 #table1#
 +-------------------------+-----------+------------------------+------------+-----------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+-----------+------------------------+------------+-----------+---------+
 | Module::List            |      34   |                   28   |        1   |   0.00011 |      22 |
 | PERLANCAR::Module::List |       7.8 |                    1.8 |        4.3 | 5.3e-05   |      20 |
 | Module::List::Tiny      |       6   |                    0   |        5   | 9.2e-05   |      21 |
 | perl -e1 (baseline)     |       6   |                    0   |        6   | 9.7e-05   |      20 |
 +-------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ListingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ListingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ListingModules>

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
