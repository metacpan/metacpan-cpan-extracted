package Bencher::Scenario::PERLANCARModuleList::Startup;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark the startup overhead of PERLANCAR::Module::List',
    module_startup => 1,
    participants => [
        {
            module => 'PERLANCAR::Module::List',
        },
        {
            module => 'Module::List',
        },
    ],
};

1;
# ABSTRACT: Benchmark the startup overhead of PERLANCAR::Module::List

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCARModuleList::Startup - Benchmark the startup overhead of PERLANCAR::Module::List

=head1 VERSION

This document describes version 0.030 of Bencher::Scenario::PERLANCARModuleList::Startup (from Perl distribution Bencher-Scenarios-PERLANCARModuleList), released on 2019-07-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCARModuleList::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Module::List> 0.003005

L<Module::List> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Module::List (perl_code)

L<PERLANCAR::Module::List>



=item * Module::List (perl_code)

L<Module::List>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.28.2 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m PERLANCARModuleList::Startup >>):

 #table1#
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+-----------+------------------------+------------+---------+---------+
 | Module::List            |      31   |                   26.8 |        1   | 5.2e-05 |      21 |
 | PERLANCAR::Module::List |       5.2 |                    1   |        5.9 | 3.7e-05 |      20 |
 | perl -e1 (baseline)     |       4.2 |                    0   |        7.3 | 2.7e-05 |      20 |
 +-------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCARModuleList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCARModuleList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCARModuleList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
