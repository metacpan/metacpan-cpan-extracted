package Bencher::Scenario::Log::Any::Startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-Any'; # DIST
our $VERSION = '0.100'; # VERSION

our $scenario = {
    module_startup => 1,
    modules => {
    },
    participants => [
        {module => 'Log::Any'},
        {module => 'Log::Any::Adapter::Null'},
        {module => 'Log::Any::Adapter::Screen'},
        {module => 'Log::Any::Adapter::Stdout'},
        {module => 'Log::Any::Proxy'},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::Any::Startup

=head1 VERSION

This document describes version 0.100 of Bencher::Scenario::Log::Any::Startup (from Perl distribution Bencher-Scenarios-Log-Any), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::Any::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.717

L<Log::Any::Adapter::Null> 1.717

L<Log::Any::Adapter::Screen> 0.140

L<Log::Any::Adapter::Stdout> 1.717

L<Log::Any::Proxy> 1.717

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::Any (perl_code)

L<Log::Any>



=item * Log::Any::Adapter::Null (perl_code)

L<Log::Any::Adapter::Null>



=item * Log::Any::Adapter::Screen (perl_code)

L<Log::Any::Adapter::Screen>



=item * Log::Any::Adapter::Stdout (perl_code)

L<Log::Any::Adapter::Stdout>



=item * Log::Any::Proxy (perl_code)

L<Log::Any::Proxy>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::Any::Startup

Result formatted as table:

 #table1#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::Any::Adapter::Screen |     14.6  |              8.53 |                 0.00% |               141.10% | 6.3e-06 |      20 |
 | Log::Any::Adapter::Stdout |     14.2  |              8.13 |                 3.34% |               133.32% | 3.2e-06 |      20 |
 | Log::Any::Adapter::Null   |     14    |              7.93 |                 4.32% |               131.11% | 4.2e-06 |      20 |
 | Log::Any::Proxy           |     13.6  |              7.53 |                 7.98% |               123.28% |   4e-06 |      20 |
 | Log::Any                  |     13.6  |              7.53 |                 7.99% |               123.26% | 4.4e-06 |      20 |
 | perl -e1 (baseline)       |      6.07 |              0    |               141.10% |                 0.00% | 2.4e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                Rate  Log::Any::Adapter::Screen  Log::Any::Adapter::Stdout  Log::Any::Adapter::Null  Log::Any::Proxy  Log::Any  perl -e1 (baseline) 
  Log::Any::Adapter::Screen   68.5/s                         --                        -2%                      -4%              -6%       -6%                 -58% 
  Log::Any::Adapter::Stdout   70.4/s                         2%                         --                      -1%              -4%       -4%                 -57% 
  Log::Any::Adapter::Null     71.4/s                         4%                         1%                       --              -2%       -2%                 -56% 
  Log::Any::Proxy             73.5/s                         7%                         4%                       2%               --        0%                 -55% 
  Log::Any                    73.5/s                         7%                         4%                       2%               0%        --                 -55% 
  perl -e1 (baseline)        164.7/s                       140%                       133%                     130%             124%      124%                   -- 
 
 Legends:
   Log::Any: mod_overhead_time=7.53 participant=Log::Any
   Log::Any::Adapter::Null: mod_overhead_time=7.93 participant=Log::Any::Adapter::Null
   Log::Any::Adapter::Screen: mod_overhead_time=8.53 participant=Log::Any::Adapter::Screen
   Log::Any::Adapter::Stdout: mod_overhead_time=8.13 participant=Log::Any::Adapter::Stdout
   Log::Any::Proxy: mod_overhead_time=7.53 participant=Log::Any::Proxy
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-Any>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
