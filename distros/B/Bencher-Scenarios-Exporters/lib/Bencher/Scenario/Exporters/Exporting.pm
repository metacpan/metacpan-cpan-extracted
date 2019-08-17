package Bencher::Scenario::Exporters::Exporting;

our $DATE = '2019-08-16'; # DATE
our $VERSION = '0.091'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Slurper qw(write_text);

my $tempdir = tempdir(CLEANUP => 1);
write_text("$tempdir/ExampleExporter.pm",              'package ExampleExporter;              use Exporter qw(import);                  our @EXPORT = qw(e1 e2 e3); sub e1{} sub e2{} sub e3{} 1;');
write_text("$tempdir/ExampleExporterLite.pm",          'package ExampleExporterLite;          use Exporter::Lite qw(import);            our @EXPORT = qw(e1 e2 e3); sub e1{} sub e2{} sub e3{} 1;');
write_text("$tempdir/ExamplePERLANCARExporterLite.pm", 'package ExamplePERLANCARExporterLite; use PERLANCAR::Exporter::Lite qw(import); our @EXPORT = qw(e1 e2 e3); sub e1{} sub e2{} sub e3{} 1;');
write_text("$tempdir/ExampleExporterRinci.pm",         'package ExampleExporterRinci;         use Exporter::Rinci qw(import);           our @EXPORT = qw(e1 e2); our %SPEC; sub e1{} sub e2{} $SPEC{e3}={v=>1.1, tags=>[q/export:default/]}; sub e3{} 1;');
write_text("$tempdir/ExamplePerinciExporter.pm",       'package ExamplePerinciExporter;       use Perinci::Exporter;                    our @EXPORT = qw(e1 e2); our %SPEC; sub e1{} sub e2{} $SPEC{e3}={v=>1.1, tags=>[q/export:default/]}; sub e3{} 1;');

our $scenario = {
    summary => 'Benchmark overhead of exporting',

    modules => {
        'PERLANCAR::Exporter::Lite' => {version=>0.02},
    },

    participants => [
        {name=>"Exporter", cmdline => [$^X, "-I$tempdir", "-MExampleExporter", "-e1"]},
        {name=>"Exporter::Lite", cmdline => [$^X, "-I$tempdir", "-MExampleExporterLite", "-e1"]},
        {name=>"Exporter::Rinci", cmdline => [$^X, "-I$tempdir", "-MExampleExporterRinci", "-e1"]},
        {name=>"Perinci::Exporter", cmdline => [$^X, "-I$tempdir", "-MExamplePerinciExporter", "-e1"]},
        {name=>"PERLANCAR::Exporter::Lite", cmdline => [$^X, "-I$tempdir", "-MExamplePERLANCARExporterLite", "-e1"]},
        {name=>"perl -e1 (baseline)", cmdline => [$^X, "-e1"]},
    ],
};

1;
# ABSTRACT: Benchmark overhead of exporting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Exporters::Exporting - Benchmark overhead of exporting

=head1 VERSION

This document describes version 0.091 of Bencher::Scenario::Exporters::Exporting (from Perl distribution Bencher-Scenarios-Exporters), released on 2019-08-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Exporters::Exporting

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Exporter::Lite> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Exporter (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -I/tmp/MRtNGjMKnA -MExampleExporter -e1



=item * Exporter::Lite (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -I/tmp/MRtNGjMKnA -MExampleExporterLite -e1



=item * Exporter::Rinci (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -I/tmp/MRtNGjMKnA -MExampleExporterRinci -e1



=item * Perinci::Exporter (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -I/tmp/MRtNGjMKnA -MExamplePerinciExporter -e1



=item * PERLANCAR::Exporter::Lite (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -I/tmp/MRtNGjMKnA -MExamplePERLANCARExporterLite -e1



=item * perl -e1 (baseline) (command)

Command line:

 /zpool_host_mnt/mnt/home/u1/perl5/perlbrew/perls/perl-5.26.1/bin/perl -e1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m Exporters::Exporting >>):

 #table1#
 +---------------------------+-----------+-----------+------------+---------+---------+
 | participant               | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------+-----------+-----------+------------+---------+---------+
 | Exporter::Lite            |       120 |       8.1 |        1   | 2.8e-05 |      20 |
 | Perinci::Exporter         |       130 |       7.5 |        1.1 | 3.6e-05 |      20 |
 | Exporter::Rinci           |       150 |       6.7 |        1.2 |   3e-05 |      20 |
 | Exporter                  |       160 |       6.4 |        1.3 | 2.4e-05 |      20 |
 | PERLANCAR::Exporter::Lite |       160 |       6.1 |        1.3 |   1e-05 |      20 |
 | perl -e1 (baseline)       |       180 |       5.7 |        1.4 | 1.2e-05 |      20 |
 +---------------------------+-----------+-----------+------------+---------+---------+


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
