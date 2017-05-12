package Bencher::Scenario::Exporters::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.08'; # VERSION

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

This document describes version 0.08 of Bencher::Scenario::Exporters::Startup (from Perl distribution Bencher-Scenarios-Exporters), released on 2017-01-25.

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

L<Exporter::Rinci> 0.02

L<Exporter::Tidy> 0.08

L<Exporter::Tiny> 0.042

L<PERLANCAR::Exporter::Lite> 0.02

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



=item * PERLANCAR::Exporter::Lite (perl_code)

L<PERLANCAR::Exporter::Lite>



=item * Sub::Exporter (perl_code)

L<Sub::Exporter>



=item * Xporter (perl_code)

L<Xporter>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Exporters::Startup >>):

 #table1#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | Sub::Exporter             | 0.96                         | 4.3                | 16             |      21   |     15.2               |        1   |   0.0001 |      20 |
 | Exporter::Tiny            | 0.87                         | 4.1                | 16             |       9.7 |      3.9               |        2.1 | 2.7e-05  |      20 |
 | Xporter                   | 0.82                         | 4.1                | 16             |       9.3 |      3.5               |        2.2 | 2.8e-05  |      20 |
 | Exporter::Lite            | 1.1                          | 4.4                | 16             |       8.7 |      2.9               |        2.4 | 3.4e-05  |      20 |
 | Exporter::Rinci           | 0.89                         | 4.2                | 16             |       7   |      1.2               |        2.9 |   2e-05  |      20 |
 | Exporter                  | 0.88                         | 4.2                | 16             |       6.8 |      1                 |        3   | 2.9e-05  |      20 |
 | Exporter::Tidy            | 0.94                         | 4.3                | 16             |       6.5 |      0.7               |        3.2 | 2.3e-05  |      20 |
 | PERLANCAR::Exporter::Lite | 2.3                          | 5.9                | 21             |       6.4 |      0.600000000000001 |        3.2 | 1.1e-05  |      20 |
 | perl -e1 (baseline)       | 0.9                          | 4.3                | 16             |       5.8 |      0                 |        3.5 | 1.7e-05  |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
