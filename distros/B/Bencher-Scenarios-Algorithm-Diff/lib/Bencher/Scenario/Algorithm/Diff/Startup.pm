package Bencher::Scenario::Algorithm::Diff::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-18'; # DATE
our $DIST = 'Bencher-Scenarios-Algorithm-Diff'; # DIST
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of Bencher::Scenario::Algorithm::Diff::Startup (from Perl distribution Bencher-Scenarios-Algorithm-Diff), released on 2023-01-18.

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Algorithm::Diff::Startup >>):

 #table1#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Algorithm::Diff::XS |      15   |               8.8 |                 0.00% |               137.44% | 4.1e-05 |      20 |
 | Algorithm::LCSS     |      12   |               5.8 |                21.02% |                96.20% | 6.1e-05 |      20 |
 | Algorithm::Diff     |      12   |               5.8 |                27.38% |                86.40% | 4.6e-05 |      20 |
 | perl -e1 (baseline) |       6.2 |               0   |               137.44% |                 0.00% | 1.3e-05 |      21 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  AD:X   A:L   A:D  perl -e1 (baseline) 
  AD:X                  66.7/s    --  -19%  -19%                 -58% 
  A:L                   83.3/s   25%    --    0%                 -48% 
  A:D                   83.3/s   25%    0%    --                 -48% 
  perl -e1 (baseline)  161.3/s  141%   93%   93%                   -- 
 
 Legends:
   A:D: mod_overhead_time=5.8 participant=Algorithm::Diff
   A:L: mod_overhead_time=5.8 participant=Algorithm::LCSS
   AD:X: mod_overhead_time=8.8 participant=Algorithm::Diff::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Algorithm-Diff>.

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

This software is copyright (c) 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Algorithm-Diff>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
