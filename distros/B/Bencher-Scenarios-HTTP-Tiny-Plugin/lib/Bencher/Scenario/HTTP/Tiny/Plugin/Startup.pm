package Bencher::Scenario::HTTP::Tiny::Plugin::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-HTTP-Tiny-Plugin'; # DIST
our $VERSION = '0.002'; # VERSION

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

Bencher::Scenario::HTTP::Tiny::Plugin::Startup - Benchmark startup overhead

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::HTTP::Tiny::Plugin::Startup (from Perl distribution Bencher-Scenarios-HTTP-Tiny-Plugin), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HTTP::Tiny::Plugin::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<HTTP::Tiny> 0.076

L<HTTP::Tiny::Plugin> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * HTTP::Tiny (perl_code)

L<HTTP::Tiny>



=item * HTTP::Tiny::Plugin (perl_code)

L<HTTP::Tiny::Plugin>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m HTTP::Tiny::Plugin::Startup >>):

 #table1#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | HTTP::Tiny::Plugin  |     37.3  |             31.49 |                 0.00% |               542.26% | 2.8e-05 |      20 |
 | HTTP::Tiny          |     36    |             30.19 |                 4.05% |               517.28% | 4.5e-05 |      20 |
 | perl -e1 (baseline) |      5.81 |              0    |               542.26% |                 0.00% | 3.8e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  HT:P   H:T  perl -e1 (baseline) 
  HT:P                  26.8/s    --   -3%                 -84% 
  H:T                   27.8/s    3%    --                 -83% 
  perl -e1 (baseline)  172.1/s  541%  519%                   -- 
 
 Legends:
   H:T: mod_overhead_time=30.19 participant=HTTP::Tiny
   HT:P: mod_overhead_time=31.49 participant=HTTP::Tiny::Plugin
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTP-Tiny-Plugin>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTP-Tiny-Plugin>.

=head1 SEE ALSO

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTP-Tiny-Plugin>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
