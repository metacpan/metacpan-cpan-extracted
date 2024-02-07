package Bencher::Scenario::Log::Dispatch::Startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-Dispatch'; # DIST
our $VERSION = '0.030'; # VERSION

#our @modules = grep {!/\ALog::Dispatch::(XXX)\z/} do { require App::lcpan::Call; @{ App::lcpan::Call::call_lcpan_script(argv=>["modules", "--namespace", "Regexp::Common"])->[2] } }; # PRECOMPUTE
our @modules = qw(
    Log::Dispatch::Base
    Log::Dispatch::Dir
    Log::Dispatch::File
    Log::Dispatch::FileWriteRotate
    Log::Dispatch::Null
    Log::Dispatch::Perl
    Log::Dispatch::Screen
    Log::Dispatch::Screen::Color
);

our $scenario = {
    summary => 'Benchmark module startup overhead of some Log::Dispatch modules',
    # minimum versions
    modules => {
        'Log::Dispatch::FileWriteRotate' => {version=>'0.04'},
    },
    module_startup => 1,

    participants => [
        map { +{module=>$_} } @modules,
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of some Log::Dispatch modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::Dispatch::Startup - Benchmark module startup overhead of some Log::Dispatch modules

=head1 VERSION

This document describes version 0.030 of Bencher::Scenario::Log::Dispatch::Startup (from Perl distribution Bencher-Scenarios-Log-Dispatch), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::Dispatch::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Dispatch::Base> 2.71

L<Log::Dispatch::Dir> 0.160

L<Log::Dispatch::File> 2.71

L<Log::Dispatch::FileWriteRotate> 0.062

L<Log::Dispatch::Null> 2.71

L<Log::Dispatch::Perl> 0.05

L<Log::Dispatch::Screen> 2.71

L<Log::Dispatch::Screen::Color> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::Dispatch::Base (perl_code)

L<Log::Dispatch::Base>



=item * Log::Dispatch::Dir (perl_code)

L<Log::Dispatch::Dir>



=item * Log::Dispatch::File (perl_code)

L<Log::Dispatch::File>



=item * Log::Dispatch::FileWriteRotate (perl_code)

L<Log::Dispatch::FileWriteRotate>



=item * Log::Dispatch::Null (perl_code)

L<Log::Dispatch::Null>



=item * Log::Dispatch::Perl (perl_code)

L<Log::Dispatch::Perl>



=item * Log::Dispatch::Screen (perl_code)

L<Log::Dispatch::Screen>



=item * Log::Dispatch::Screen::Color (perl_code)

L<Log::Dispatch::Screen::Color>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::Dispatch::Startup

Result formatted as table:

 #table1#
 +--------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                    | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::Dispatch::FileWriteRotate |     98.3  |             92.28 |                 0.00% |              1531.50% | 4.1e-05 |      23 |
 | Log::Dispatch::Screen::Color   |     93.2  |             87.18 |                 5.51% |              1446.34% | 2.9e-05 |      20 |
 | Log::Dispatch::Dir             |     89.9  |             83.88 |                 9.32% |              1392.34% |   5e-05 |      20 |
 | Log::Dispatch::Screen          |     88.6  |             82.58 |                10.94% |              1370.60% | 7.4e-05 |      21 |
 | Log::Dispatch::File            |     85.7  |             79.68 |                14.76% |              1321.64% | 4.1e-05 |      20 |
 | Log::Dispatch::Perl            |     79.9  |             73.88 |                23.09% |              1225.46% | 3.7e-05 |      23 |
 | Log::Dispatch::Null            |     79.3  |             73.28 |                23.96% |              1216.12% | 1.6e-05 |      20 |
 | Log::Dispatch::Base            |     14.1  |              8.08 |               596.89% |               134.11% | 7.8e-06 |      20 |
 | perl -e1 (baseline)            |      6.02 |              0    |              1531.50% |                 0.00% | 3.1e-06 |      20 |
 +--------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                     Rate  Log::Dispatch::FileWriteRotate  Log::Dispatch::Screen::Color  Log::Dispatch::Dir  Log::Dispatch::Screen  Log::Dispatch::File  Log::Dispatch::Perl  Log::Dispatch::Null  Log::Dispatch::Base  perl -e1 (baseline) 
  Log::Dispatch::FileWriteRotate   10.2/s                              --                           -5%                 -8%                    -9%                 -12%                 -18%                 -19%                 -85%                 -93% 
  Log::Dispatch::Screen::Color     10.7/s                              5%                            --                 -3%                    -4%                  -8%                 -14%                 -14%                 -84%                 -93% 
  Log::Dispatch::Dir               11.1/s                              9%                            3%                  --                    -1%                  -4%                 -11%                 -11%                 -84%                 -93% 
  Log::Dispatch::Screen            11.3/s                             10%                            5%                  1%                     --                  -3%                  -9%                 -10%                 -84%                 -93% 
  Log::Dispatch::File              11.7/s                             14%                            8%                  4%                     3%                   --                  -6%                  -7%                 -83%                 -92% 
  Log::Dispatch::Perl              12.5/s                             23%                           16%                 12%                    10%                   7%                   --                   0%                 -82%                 -92% 
  Log::Dispatch::Null              12.6/s                             23%                           17%                 13%                    11%                   8%                   0%                   --                 -82%                 -92% 
  Log::Dispatch::Base              70.9/s                            597%                          560%                537%                   528%                 507%                 466%                 462%                   --                 -57% 
  perl -e1 (baseline)             166.1/s                           1532%                         1448%               1393%                  1371%                1323%                1227%                1217%                 134%                   -- 
 
 Legends:
   Log::Dispatch::Base: mod_overhead_time=8.08 participant=Log::Dispatch::Base
   Log::Dispatch::Dir: mod_overhead_time=83.88 participant=Log::Dispatch::Dir
   Log::Dispatch::File: mod_overhead_time=79.68 participant=Log::Dispatch::File
   Log::Dispatch::FileWriteRotate: mod_overhead_time=92.28 participant=Log::Dispatch::FileWriteRotate
   Log::Dispatch::Null: mod_overhead_time=73.28 participant=Log::Dispatch::Null
   Log::Dispatch::Perl: mod_overhead_time=73.88 participant=Log::Dispatch::Perl
   Log::Dispatch::Screen: mod_overhead_time=82.58 participant=Log::Dispatch::Screen
   Log::Dispatch::Screen::Color: mod_overhead_time=87.18 participant=Log::Dispatch::Screen::Color
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-Dispatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-Dispatch>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-Dispatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
