package Bencher::Scenario::File::Which::Cached;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenario-File-Which-Cached'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark File::Which::Cached',

    participants => [
        {fcall_template=>'File::Which::which("ls")'},
        {fcall_template=>'File::Which::Cached::which("ls")'},
    ],
};

1;
# ABSTRACT: Benchmark File::Which::Cached

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::File::Which::Cached - Benchmark File::Which::Cached

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::File::Which::Cached (from Perl distribution Bencher-Scenario-File-Which-Cached), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m File::Which::Cached

To run module startup overhead benchmark:

 % bencher --module-startup -m File::Which::Cached

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Which> 1.27

L<File::Which::Cached> 1.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Which::which (perl_code)

Function call template:

 File::Which::which("ls")



=item * File::Which::Cached::which (perl_code)

Function call template:

 File::Which::Cached::which("ls")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m File::Which::Cached >>):

 #table1#
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | File::Which::which         |     25000 |     39    |                 0.00% |             35707.24% | 6.5e-08 |      21 |
 | File::Which::Cached::which |   9100000 |      0.11 |             35707.24% |                 0.00% | 2.1e-10 |      20 |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

              Rate    FW:w  FWC:w 
  FW:w     25000/s      --   -99% 
  FWC:w  9100000/s  35354%     -- 
 
 Legends:
   FW:w: participant=File::Which::which
   FWC:w: participant=File::Which::Cached::which

Benchmark module startup overhead (C<< bencher -m File::Which::Cached --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | File::Which::Cached |      15   |               8.9 |                 0.00% |               145.11% | 5.8e-06 |      23 |
 | File::Which         |      14.5 |               8.4 |                 3.23% |               137.44% | 8.1e-06 |      21 |
 | perl -e1 (baseline) |       6.1 |               0   |               145.11% |                 0.00% | 1.5e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  FW:C   F:W  perl -e1 (baseline) 
  FW:C                  66.7/s    --   -3%                 -59% 
  F:W                   69.0/s    3%    --                 -57% 
  perl -e1 (baseline)  163.9/s  145%  137%                   -- 
 
 Legends:
   F:W: mod_overhead_time=8.4 participant=File::Which
   FW:C: mod_overhead_time=8.9 participant=File::Which::Cached
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-File-Which-Cached>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-File-Which-Cached>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-File-Which-Cached>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
