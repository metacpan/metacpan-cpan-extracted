package Bencher::Scenario::LocaleTextDomainIfEnv::Startup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Bencher-Scenarios-LocaleTextDomainIfEnv'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of Locale::TextDomain::IfEnv',

    modules => {
        # minimum versions
        #'Getopt::Long::EvenLess' => {version=>'0.10'},
    },

    module_startup => 1,

    participants => [
        {module=>'Locale::TextDomain::IfEnv'},
        {module=>'Locale::TextDomain::UTF8::IfEnv'},
        {module=>'Locale::TextDomain::UTF8'},
        {module=>'Locale::TextDomain'},

        {module=>'Locale::Messages'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Locale::TextDomain::IfEnv

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LocaleTextDomainIfEnv::Startup - Benchmark startup of Locale::TextDomain::IfEnv

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::LocaleTextDomainIfEnv::Startup (from Perl distribution Bencher-Scenarios-LocaleTextDomainIfEnv), released on 2019-12-26.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LocaleTextDomainIfEnv::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Locale::Messages> 1.31

L<Locale::TextDomain> 1.31

L<Locale::TextDomain::IfEnv> 0.002

L<Locale::TextDomain::UTF8> 0.020

L<Locale::TextDomain::UTF8::IfEnv> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * Locale::TextDomain::IfEnv (perl_code)

L<Locale::TextDomain::IfEnv>



=item * Locale::TextDomain::UTF8::IfEnv (perl_code)

L<Locale::TextDomain::UTF8::IfEnv>



=item * Locale::TextDomain::UTF8 (perl_code)

L<Locale::TextDomain::UTF8>



=item * Locale::TextDomain (perl_code)

L<Locale::TextDomain>



=item * Locale::Messages (perl_code)

L<Locale::Messages>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LocaleTextDomainIfEnv::Startup >>):

 #table1#
 +---------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                     | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------------+-----------+------------------------+------------+---------+---------+
 | Locale::TextDomain::UTF8        |     52    |     44.14              |       1    | 2.5e-05 |      20 |
 | Locale::TextDomain              |     51.8  |     43.94              |       1    | 1.4e-05 |      20 |
 | Locale::Messages                |     34.9  |     27.04              |       1.49 | 2.7e-05 |      20 |
 | Locale::TextDomain::IfEnv       |      8.6  |      0.739999999999999 |       6.04 | 5.9e-06 |      20 |
 | Locale::TextDomain::UTF8::IfEnv |      8.6  |      0.739999999999999 |       6.04 | 5.6e-06 |      20 |
 | perl -e1 (baseline)             |      7.86 |      0                 |       6.61 | 7.4e-06 |      20 |
 +---------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LocaleTextDomainIfEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LocaleTextDomainIfEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LocaleTextDomainIfEnv>

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
