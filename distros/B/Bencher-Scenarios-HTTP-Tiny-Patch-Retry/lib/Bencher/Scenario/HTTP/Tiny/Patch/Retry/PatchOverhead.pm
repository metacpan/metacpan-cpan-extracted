package Bencher::Scenario::HTTP::Tiny::Patch::Retry::PatchOverhead;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-HTTP-Tiny-Patch-Retry'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark patching overhead',
    participants => [
        {
            name => 'import+unimport',
            module => 'HTTP::Tiny::Patch::Retry',
            code_template => 'HTTP::Tiny::Patch::Retry->import; HTTP::Tiny::Patch::Retry->unimport',
        },
    ],
};

1;
# ABSTRACT: Benchmark patching overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HTTP::Tiny::Patch::Retry::PatchOverhead - Benchmark patching overhead

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::HTTP::Tiny::Patch::Retry::PatchOverhead (from Perl distribution Bencher-Scenarios-HTTP-Tiny-Patch-Retry), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HTTP::Tiny::Patch::Retry::PatchOverhead

To run module startup overhead benchmark:

 % bencher --module-startup -m HTTP::Tiny::Patch::Retry::PatchOverhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<HTTP::Tiny::Patch::Retry> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * import+unimport (perl_code)

Code template:

 HTTP::Tiny::Patch::Retry->import; HTTP::Tiny::Patch::Retry->unimport



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m HTTP::Tiny::Patch::Retry::PatchOverhead >>):

 #table1#
 +-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | import+unimport |         |        | perl |     35000 |        29 |                 0.00% |                 0.00% | 5.1e-08 |      22 |
 +-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

       Rate     
    35000/s  -- 
 
 Legends:
   : ds_tags= p_tags= participant=import+unimport perl=perl

Benchmark module startup overhead (C<< bencher -m HTTP::Tiny::Patch::Retry::PatchOverhead --module-startup >>):

 #table2#
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant              | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | HTTP::Tiny::Patch::Retry |      43.6 |              37.6 |                 0.00% |               622.74% |   1e-05 |      21 |
 | perl -e1 (baseline)      |       6   |               0   |               622.74% |                 0.00% | 2.7e-05 |      20 |
 +--------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  HTP:R  perl -e1 (baseline) 
  HTP:R                 22.9/s     --                 -86% 
  perl -e1 (baseline)  166.7/s   626%                   -- 
 
 Legends:
   HTP:R: mod_overhead_time=37.6 participant=HTTP::Tiny::Patch::Retry
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTP-Tiny-Patch-Retry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTP-Tiny-Patch-Retry>.

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

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTP-Tiny-Patch-Retry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
