package Bencher::Scenario::ListingModules::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-21'; # DATE
our $DIST = 'Bencher-Scenarios-ListingModules'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark module startup',
    module_startup => 1,
    participants => [
        {
            module => 'Module::List',
        },
        {
            module => 'Module::List::More',
        },
        {
            module => 'Module::List::Tiny',
        },
        {
            module => 'Module::List::Wildcard',
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

This document describes version 0.002 of Bencher::Scenario::ListingModules::Startup (from Perl distribution Bencher-Scenarios-ListingModules), released on 2020-09-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListingModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Module::List> 0.004

L<Module::List::More> 0.004008

L<Module::List::Tiny> 0.004003

L<Module::List::Wildcard> 0.004006

=head1 BENCHMARK PARTICIPANTS

=over

=item * Module::List (perl_code)

L<Module::List>



=item * Module::List::More (perl_code)

L<Module::List::More>



=item * Module::List::Tiny (perl_code)

L<Module::List::Tiny>



=item * Module::List::Wildcard (perl_code)

L<Module::List::Wildcard>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m ListingModules::Startup >>):

 #table1#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Module::List           |      20   |              15   |                 0.00% |               332.72% |   0.00017 |      20 |
 | Module::List::Wildcard |       7.1 |               2.1 |               190.33% |                49.04% | 3.9e-05   |      20 |
 | Module::List::More     |       7   |               2   |               199.23% |                44.61% |   0.0002  |      20 |
 | Module::List::Tiny     |       6.1 |               1.1 |               238.22% |                27.94% |   7e-06   |      20 |
 | perl -e1 (baseline)    |       5   |               0   |               332.72% |                 0.00% |   0.0001  |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
