package Bencher::Scenario::Data::ModeMerge::Startup;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-ModeMerge'; # DIST
our $VERSION = '0.004'; # VERSION

our $scenario = {
    summary => 'Benchmark module startup overhead of Data::ModeMerge',

    module_startup => 1,

    participants => [
        {module=>'Data::ModeMerge'},
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of Data::ModeMerge

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::ModeMerge::Startup - Benchmark module startup overhead of Data::ModeMerge

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::Data::ModeMerge::Startup (from Perl distribution Bencher-Scenarios-Data-ModeMerge), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::ModeMerge::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::ModeMerge> 0.35

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::ModeMerge (perl_code)

L<Data::ModeMerge>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m Data::ModeMerge::Startup --include-path archive/0.22/lib --include-path archive/0.23/lib --include-path archive/0.26/lib --include-path archive/0.31/lib --include-path archive/0.32/lib --include-path archive/0.33/lib --include-path archive/0.34/lib --module-startup --multimodver Data::ModeMerge >>:

 #table1#
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | modver | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Data::ModeMerge     | 0.22   |     170   |             167   |                 0.00% |              8514.97% |   0.00044 |      20 |
 | Data::ModeMerge     | 0.23   |      33   |              30   |               407.07% |              1598.97% | 8.6e-05   |      21 |
 | Data::ModeMerge     | 0.26   |      32   |              29   |               416.15% |              1569.08% |   0.00015 |      20 |
 | Data::ModeMerge     | 0.31   |      16   |              13   |               947.96% |               722.07% |   0.00011 |      20 |
 | Data::ModeMerge     | 0.33   |       9.2 |               6.2 |              1710.60% |               375.81% | 5.6e-05   |      20 |
 | Data::ModeMerge     | 0.35   |       7.5 |               4.5 |              2115.45% |               288.86% | 3.2e-05   |      20 |
 | Data::ModeMerge     | 0.34   |       7.2 |               4.2 |              2214.22% |               272.26% |   5e-05   |      20 |
 | Data::ModeMerge     | 0.32   |       7   |               4   |              2285.85% |               261.09% | 4.2e-05   |      20 |
 | perl -e1 (baseline) | 0.22   |       3   |               0   |              6176.69% |                37.25% | 3.5e-05   |      20 |
 | perl -e1 (baseline) | 0.35   |       2   |              -1   |              7363.98% |                15.42% |   4e-05   |      20 |
 | perl -e1 (baseline) | 0.26   |       2.1 |              -0.9 |              7647.73% |                11.19% | 1.7e-05   |      21 |
 | perl -e1 (baseline) | 0.23   |       2.1 |              -0.9 |              7817.66% |                 8.81% |   2e-05   |      20 |
 | perl -e1 (baseline) | 0.34   |       2.1 |              -0.9 |              7878.53% |                 7.98% | 1.4e-05   |      20 |
 | perl -e1 (baseline) | 0.31   |       2   |              -1   |              8212.17% |                 3.64% | 9.4e-06   |      20 |
 | perl -e1 (baseline) | 0.32   |       2   |              -1   |              8377.83% |                 1.62% | 1.1e-05   |      20 |
 | perl -e1 (baseline) | 0.33   |       1.9 |              -1.1 |              8514.97% |                 0.00% | 1.5e-05   |      20 |
 +---------------------+--------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  Data::ModeMerge  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline)  perl -e1 (baseline) 
  Data::ModeMerge        5.9/s               --             -80%             -81%             -90%             -94%             -95%             -95%             -95%                 -98%                 -98%                 -98%                 -98%                 -98%                 -98%                 -98%                 -98% 
  Data::ModeMerge       30.3/s             415%               --              -3%             -51%             -72%             -77%             -78%             -78%                 -90%                 -93%                 -93%                 -93%                 -93%                 -93%                 -93%                 -94% 
  Data::ModeMerge       31.2/s             431%               3%               --             -50%             -71%             -76%             -77%             -78%                 -90%                 -93%                 -93%                 -93%                 -93%                 -93%                 -93%                 -94% 
  Data::ModeMerge       62.5/s             962%             106%             100%               --             -42%             -53%             -55%             -56%                 -81%                 -86%                 -86%                 -86%                 -87%                 -87%                 -87%                 -88% 
  Data::ModeMerge      108.7/s            1747%             258%             247%              73%               --             -18%             -21%             -23%                 -67%                 -77%                 -77%                 -77%                 -78%                 -78%                 -78%                 -79% 
  Data::ModeMerge      133.3/s            2166%             340%             326%             113%              22%               --              -3%              -6%                 -60%                 -72%                 -72%                 -72%                 -73%                 -73%                 -73%                 -74% 
  Data::ModeMerge      138.9/s            2261%             358%             344%             122%              27%               4%               --              -2%                 -58%                 -70%                 -70%                 -70%                 -72%                 -72%                 -72%                 -73% 
  Data::ModeMerge      142.9/s            2328%             371%             357%             128%              31%               7%               2%               --                 -57%                 -70%                 -70%                 -70%                 -71%                 -71%                 -71%                 -72% 
  perl -e1 (baseline)  333.3/s            5566%            1000%             966%             433%             206%             150%             140%             133%                   --                 -29%                 -29%                 -29%                 -33%                 -33%                 -33%                 -36% 
  perl -e1 (baseline)  476.2/s            7995%            1471%            1423%             661%             338%             257%             242%             233%                  42%                   --                   0%                   0%                  -4%                  -4%                  -4%                  -9% 
  perl -e1 (baseline)  476.2/s            7995%            1471%            1423%             661%             338%             257%             242%             233%                  42%                   0%                   --                   0%                  -4%                  -4%                  -4%                  -9% 
  perl -e1 (baseline)  476.2/s            7995%            1471%            1423%             661%             338%             257%             242%             233%                  42%                   0%                   0%                   --                  -4%                  -4%                  -4%                  -9% 
  perl -e1 (baseline)  500.0/s            8400%            1550%            1500%             700%             359%             275%             260%             250%                  50%                   5%                   5%                   5%                   --                   0%                   0%                  -5% 
  perl -e1 (baseline)  500.0/s            8400%            1550%            1500%             700%             359%             275%             260%             250%                  50%                   5%                   5%                   5%                   0%                   --                   0%                  -5% 
  perl -e1 (baseline)  500.0/s            8400%            1550%            1500%             700%             359%             275%             260%             250%                  50%                   5%                   5%                   5%                   0%                   0%                   --                  -5% 
  perl -e1 (baseline)  526.3/s            8847%            1636%            1584%             742%             384%             294%             278%             268%                  57%                  10%                  10%                  10%                   5%                   5%                   5%                   -- 
 
 Legends:
   Data::ModeMerge: mod_overhead_time=4 modver=0.32 participant=Data::ModeMerge
   perl -e1 (baseline): mod_overhead_time=-1.1 modver=0.33 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-ModeMerge>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-ModeMerge>.

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-ModeMerge>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
