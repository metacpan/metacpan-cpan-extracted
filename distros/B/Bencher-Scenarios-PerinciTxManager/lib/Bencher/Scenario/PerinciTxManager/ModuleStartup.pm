package Bencher::Scenario::PerinciTxManager::ModuleStartup;

our $DATE = '2018-11-11'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark module startup',
    module_startup => 1,
    participants => [
        {module=>'Perinci::Tx::Manager'},
    ],
};

1;
# ABSTRACT: Benchmark module startup

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciTxManager::ModuleStartup - Benchmark module startup

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciTxManager::ModuleStartup (from Perl distribution Bencher-Scenarios-PerinciTxManager), released on 2018-11-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciTxManager::ModuleStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Tx::Manager> 0.57

=head1 BENCHMARK PARTICIPANTS

=over

=item * Perinci::Tx::Manager (perl_code)

L<Perinci::Tx::Manager>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m PerinciTxManager::ModuleStartup >>):

 #table1#
 +----------------------+-----------+------------------------+------------+----------+---------+
 | participant          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +----------------------+-----------+------------------------+------------+----------+---------+
 | Perinci::Tx::Manager |      70   |                   63.6 |          1 |   0.0007 |      20 |
 | perl -e1 (baseline)  |       6.4 |                    0   |         11 | 1.6e-05  |      21 |
 +----------------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciTxManager>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciTxManager>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciTxManager>

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
