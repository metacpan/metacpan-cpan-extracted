package Bencher::Scenario::PackageMoreUtil::package_exists;

our $DATE = '2018-10-07'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark package_exists()',
    participants => [
        {name=>'Bencher', fcall_template=>'Package::MoreUtil::package_exists("Bencher")'},
        {name=>'Bencher::Scenario', fcall_template=>'Package::MoreUtil::package_exists("Bencher::Scenario")'},
        {name=>'Bencher::Scenario::PackageMoreUtil', fcall_template=>'Package::MoreUtil::package_exists("Bencher::Scenario::PackageMoreUtil")'},
        {name=>'Bencher::Scenario::PackageMoreUtil::package_exists', fcall_template=>'Package::MoreUtil::package_exists("Bencher::Scenario::PackageMoreUtil::package_exists")'},
    ],
};

1;
# ABSTRACT: Benchmark package_exists()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PackageMoreUtil::package_exists - Benchmark package_exists()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::PackageMoreUtil::package_exists (from Perl distribution Bencher-Scenarios-PackageMoreUtil), released on 2018-10-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PackageMoreUtil::package_exists

To run module startup overhead benchmark:

 % bencher --module-startup -m PackageMoreUtil::package_exists

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Package::MoreUtil> 0.590

=head1 BENCHMARK PARTICIPANTS

=over

=item * Bencher (perl_code)

Function call template:

 Package::MoreUtil::package_exists("Bencher")



=item * Bencher::Scenario (perl_code)

Function call template:

 Package::MoreUtil::package_exists("Bencher::Scenario")



=item * Bencher::Scenario::PackageMoreUtil (perl_code)

Function call template:

 Package::MoreUtil::package_exists("Bencher::Scenario::PackageMoreUtil")



=item * Bencher::Scenario::PackageMoreUtil::package_exists (perl_code)

Function call template:

 Package::MoreUtil::package_exists("Bencher::Scenario::PackageMoreUtil::package_exists")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m PackageMoreUtil::package_exists >>):

 #table1#
 +----------------------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                                        | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------------------------+-----------+-----------+------------+---------+---------+
 | Bencher::Scenario::PackageMoreUtil::package_exists |    600000 |  1.7      |    1       | 2.3e-09 |      23 |
 | Bencher::Scenario::PackageMoreUtil                 |    810000 |  1.2      |    1.3     | 1.7e-09 |      20 |
 | Bencher::Scenario                                  |   1250000 |  0.802    |    2.07    | 4.1e-10 |      21 |
 | Bencher                                            |   3200420 |  0.312459 |    5.30824 |   0     |      20 |
 +----------------------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PackageMoreUtil::package_exists --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Package::MoreUtil   |       7.8 |                      3 |        1   | 4.5e-05 |      20 |
 | perl -e1 (baseline) |       4.8 |                      0 |        1.6 | 2.9e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PackageMoreUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PackageMoreUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PackageMoreUtil>

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
