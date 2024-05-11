package Bencher::Scenario::Algorithm::Diff::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Algorithm-Diff'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of Algorithm::Diff',
    module_startup => 1,
    participants => [
        {module => 'Algorithm::Diff'},
        {module => 'Algorithm::Diff::XS'},
        {module => 'Algorithm::LCSS'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Algorithm::Diff

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Algorithm::Diff::Startup - Benchmark startup of Algorithm::Diff

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Algorithm::Diff::Startup (from Perl distribution Bencher-ScenarioBundle-Algorithm-Diff), released on 2024-05-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Algorithm::Diff::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Algorithm::Diff> 1.201

L<Algorithm::Diff::XS> 1.201

L<Algorithm::LCSS> 0.01

=head1 BENCHMARK PARTICIPANTS

=over

=item * Algorithm::Diff (perl_code)

L<Algorithm::Diff>



=item * Algorithm::Diff::XS (perl_code)

L<Algorithm::Diff::XS>



=item * Algorithm::LCSS (perl_code)

L<Algorithm::LCSS>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Algorithm::Diff::Startup

Result formatted as table:

 #table1#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Algorithm::Diff::XS |     20    |             13.84 |                 0.00% |               162.45% |   0.00027 |      20 |
 | Algorithm::LCSS     |     13    |              6.84 |                22.51% |               114.23% |   8e-05   |      20 |
 | Algorithm::Diff     |     11.5  |              5.34 |                40.65% |                86.59% | 6.6e-06   |      20 |
 | perl -e1 (baseline) |      6.16 |              0    |               162.45% |                 0.00% | 5.1e-06   |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  AD:X   A:L   A:D  perl -e1 (baseline) 
  AD:X                  50.0/s    --  -35%  -42%                 -69% 
  A:L                   76.9/s   53%    --  -11%                 -52% 
  A:D                   87.0/s   73%   13%    --                 -46% 
  perl -e1 (baseline)  162.3/s  224%  111%   86%                   -- 
 
 Legends:
   A:D: mod_overhead_time=5.34 participant=Algorithm::Diff
   A:L: mod_overhead_time=6.84 participant=Algorithm::LCSS
   AD:X: mod_overhead_time=13.84 participant=Algorithm::Diff::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Algorithm-Diff>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Algorithm-Diff>.

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

This software is copyright (c) 2024, 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Algorithm-Diff>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
