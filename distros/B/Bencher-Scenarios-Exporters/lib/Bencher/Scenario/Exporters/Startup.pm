package Bencher::Scenario::Exporters::Startup;

our $DATE = '2019-08-16'; # DATE
our $VERSION = '0.091'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark the startup overhead of some exporter modules',

    modules => {
        'PERLANCAR::Exporter::Lite' => {version=>0.02},
    },

    module_startup => 1,

    participants => [
        {module=>'Exporter'},
        {module=>'Exporter::Lite'},
        {module=>'Exporter::Tiny'},
        {module=>'Exporter::Tidy'},
        {module=>'Exporter::Rinci'},
        {module=>'Perinci::Exporter'},
        {module=>'PERLANCAR::Exporter::Lite'},
        {module=>'Sub::Exporter'},
        {module=>'Xporter'},
    ],
};

1;
# ABSTRACT: Benchmark the startup overhead of some exporter modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Exporters::Startup - Benchmark the startup overhead of some exporter modules

=head1 VERSION

This document describes version 0.091 of Bencher::Scenario::Exporters::Startup (from Perl distribution Bencher-Scenarios-Exporters), released on 2019-08-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Exporters::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Some notes:

=over

=item * L<Exporter::Lite> not so lite

Despite the C<::Lite> in its name and having less features than L<Exporter>, the
startup overhead is worse than Exporter (mostly due to the use of L<warnings>).

Also, this module is no longer necessary since Exporter 5.57 (2004), since
Exporter can be used without subclassing, all you have to do is:

 use Exporter qw(import);

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Exporter> 5.72

L<Exporter::Lite> 0.08

L<Exporter::Rinci> 0.030

L<Exporter::Tidy> 0.08

L<Exporter::Tiny> 1.000000

L<PERLANCAR::Exporter::Lite> 0.02

L<Perinci::Exporter> 0.081

L<Sub::Exporter> 0.987

L<Xporter> 0.1.2

=head1 BENCHMARK PARTICIPANTS

=over

=item * Exporter (perl_code)

L<Exporter>



=item * Exporter::Lite (perl_code)

L<Exporter::Lite>



=item * Exporter::Tiny (perl_code)

L<Exporter::Tiny>



=item * Exporter::Tidy (perl_code)

L<Exporter::Tidy>



=item * Exporter::Rinci (perl_code)

L<Exporter::Rinci>



=item * Perinci::Exporter (perl_code)

L<Perinci::Exporter>



=item * PERLANCAR::Exporter::Lite (perl_code)

L<PERLANCAR::Exporter::Lite>



=item * Sub::Exporter (perl_code)

L<Sub::Exporter>



=item * Xporter (perl_code)

L<Xporter>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m Exporters::Startup >>):

 #table1#
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+-----------+------------------------+------------+---------+---------+
 | Sub::Exporter             |      18   |     12.1               |        1   | 3.5e-05 |      20 |
 | Exporter::Tiny            |       9.2 |      3.3               |        2   | 1.5e-05 |      21 |
 | Xporter                   |       8.7 |      2.8               |        2   |   2e-05 |      20 |
 | Exporter::Lite            |       8.2 |      2.3               |        2.2 | 3.9e-05 |      20 |
 | Perinci::Exporter         |       7.2 |      1.3               |        2.5 | 2.1e-05 |      20 |
 | Exporter::Rinci           |       6.6 |      0.699999999999999 |        2.7 | 1.8e-05 |      20 |
 | Exporter                  |       6.3 |      0.399999999999999 |        2.8 | 2.5e-05 |      20 |
 | Exporter::Tidy            |       6.2 |      0.3               |        2.9 | 2.4e-05 |      23 |
 | PERLANCAR::Exporter::Lite |       6.1 |      0.199999999999999 |        2.9 | 1.1e-05 |      20 |
 | perl -e1 (baseline)       |       5.9 |      0                 |        3   | 3.7e-05 |      20 |
 +---------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Exporters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StartupExporters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Exporters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
