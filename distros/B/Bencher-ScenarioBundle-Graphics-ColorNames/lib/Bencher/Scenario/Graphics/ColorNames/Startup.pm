package Bencher::Scenario::Graphics::ColorNames::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Graphics-ColorNames'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of Graphics::ColorNames vs its lite version',
    module_startup => 1,
    participants => [
        {module => 'Graphics::ColorNames'},
        {module => 'Graphics::ColorNames::WWW'},
        {module => 'Graphics::ColorNamesLite'},
        {module => 'Graphics::ColorNamesLite::WWW'},
        {module => 'Graphics::ColorNamesLite::All'},
        {module => 'Graphics::ColorNamesCMYK'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Graphics::ColorNames vs its lite version

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Graphics::ColorNames::Startup - Benchmark startup of Graphics::ColorNames vs its lite version

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Graphics::ColorNames::Startup (from Perl distribution Bencher-ScenarioBundle-Graphics-ColorNames), released on 2024-05-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Graphics::ColorNames::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Graphics::ColorNames> v3.5.0

L<Graphics::ColorNames::WWW> 1.14

L<Graphics::ColorNamesLite> 0.002

L<Graphics::ColorNamesLite::WWW> 1.14.000

L<Graphics::ColorNamesLite::All> 0.006

L<Graphics::ColorNamesCMYK> 0.002

=head1 BENCHMARK PARTICIPANTS

=over

=item * Graphics::ColorNames (perl_code)

L<Graphics::ColorNames>



=item * Graphics::ColorNames::WWW (perl_code)

L<Graphics::ColorNames::WWW>



=item * Graphics::ColorNamesLite (perl_code)

L<Graphics::ColorNamesLite>



=item * Graphics::ColorNamesLite::WWW (perl_code)

L<Graphics::ColorNamesLite::WWW>



=item * Graphics::ColorNamesLite::All (perl_code)

L<Graphics::ColorNamesLite::All>



=item * Graphics::ColorNamesCMYK (perl_code)

L<Graphics::ColorNamesCMYK>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Graphics::ColorNames::Startup

Result formatted as table:

 #table1#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Graphics::ColorNames          |     20.2  |             14.2  |                 0.00% |               238.44% | 1.3e-05 |      20 |
 | Graphics::ColorNamesLite::All |     11.7  |              5.7  |                72.87% |                95.78% | 5.1e-06 |      20 |
 | Graphics::ColorNames::WWW     |      8.78 |              2.78 |               129.58% |                47.42% | 5.8e-06 |      20 |
 | Graphics::ColorNamesLite      |      6.45 |              0.45 |               212.43% |                 8.33% | 3.9e-06 |      20 |
 | Graphics::ColorNamesCMYK      |      6.43 |              0.43 |               213.68% |                 7.89% | 4.7e-06 |      20 |
 | Graphics::ColorNamesLite::WWW |      6.28 |              0.28 |               221.20% |                 5.37% | 4.3e-06 |      20 |
 | perl -e1 (baseline)           |      6    |              0    |               238.44% |                 0.00% | 7.6e-06 |      20 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                    Rate  Graphics::ColorNames  Graphics::ColorNamesLite::All  Graphics::ColorNames::WWW  Graphics::ColorNamesLite  Graphics::ColorNamesCMYK  Graphics::ColorNamesLite::WWW  perl -e1 (baseline) 
  Graphics::ColorNames            49.5/s                    --                           -42%                       -56%                      -68%                      -68%                           -68%                 -70% 
  Graphics::ColorNamesLite::All   85.5/s                   72%                             --                       -24%                      -44%                      -45%                           -46%                 -48% 
  Graphics::ColorNames::WWW      113.9/s                  130%                            33%                         --                      -26%                      -26%                           -28%                 -31% 
  Graphics::ColorNamesLite       155.0/s                  213%                            81%                        36%                        --                        0%                            -2%                  -6% 
  Graphics::ColorNamesCMYK       155.5/s                  214%                            81%                        36%                        0%                        --                            -2%                  -6% 
  Graphics::ColorNamesLite::WWW  159.2/s                  221%                            86%                        39%                        2%                        2%                             --                  -4% 
  perl -e1 (baseline)            166.7/s                  236%                            95%                        46%                        7%                        7%                             4%                   -- 
 
 Legends:
   Graphics::ColorNames: mod_overhead_time=14.2 participant=Graphics::ColorNames
   Graphics::ColorNames::WWW: mod_overhead_time=2.78 participant=Graphics::ColorNames::WWW
   Graphics::ColorNamesCMYK: mod_overhead_time=0.43 participant=Graphics::ColorNamesCMYK
   Graphics::ColorNamesLite: mod_overhead_time=0.45 participant=Graphics::ColorNamesLite
   Graphics::ColorNamesLite::All: mod_overhead_time=5.7 participant=Graphics::ColorNamesLite::All
   Graphics::ColorNamesLite::WWW: mod_overhead_time=0.28 participant=Graphics::ColorNamesLite::WWW
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Graphics-ColorNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Graphics-ColorNames>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Graphics-ColorNames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
