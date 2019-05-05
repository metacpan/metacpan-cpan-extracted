package Bencher::Scenario::HTTPTinyPlugin::Startup;

our $DATE = '2019-05-04'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark startup overhead",
    module_startup => 1,
    participants => [
        {module=>'HTTP::Tiny'},
        {module=>'HTTP::Tiny::Plugin'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HTTPTinyPlugin::Startup - Benchmark startup overhead

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::HTTPTinyPlugin::Startup (from Perl distribution Bencher-Scenarios-HTTPTinyPlugin), released on 2019-05-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HTTPTinyPlugin::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<HTTP::Tiny> 0.070

L<HTTP::Tiny::Plugin> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * HTTP::Tiny (perl_code)

L<HTTP::Tiny>



=item * HTTP::Tiny::Plugin (perl_code)

L<HTTP::Tiny::Plugin>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m HTTPTinyPlugin::Startup >>):

 #table1#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | HTTP::Tiny          |        38 |                     18 |          1 | 0.0002  |      21 |
 | HTTP::Tiny::Plugin  |        37 |                     17 |          1 | 0.00014 |      20 |
 | perl -e1 (baseline) |        20 |                      0 |          2 | 0.00022 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTPTinyPlugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTPTinyPlugin>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTPTinyPlugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
