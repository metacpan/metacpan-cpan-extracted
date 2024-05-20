package Bencher::Scenario::Log::Any::Startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-Any'; # DIST
our $VERSION = '0.101'; # VERSION

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
        {module => 'Log::Any::Simple'},
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

This document describes version 0.101 of Bencher::Scenario::Log::Any::Startup (from Perl distribution Bencher-ScenarioBundle-Log-Any), released on 2024-05-12.

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

L<Log::Any::Adapter::Screen> 0.141

L<Log::Any::Adapter::Stdout> 1.717

L<Log::Any::Proxy> 1.717

L<Log::Any::Simple> 0.04

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



=item * Log::Any::Simple (perl_code)

L<Log::Any::Simple>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::Any::Startup

Result formatted as table:

 #table1#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Log::Any::Simple          |      40   |              33.7 |                 0.00% |               475.56% |   0.00072 |      20 |
 | Log::Any::Adapter::Stdout |      16   |               9.7 |               122.89% |               158.22% |   0.00012 |      23 |
 | Log::Any                  |      20   |              13.7 |               132.58% |               147.46% |   0.00038 |      20 |
 | Log::Any::Proxy           |      20   |              13.7 |               136.49% |               143.37% |   0.00024 |      20 |
 | Log::Any::Adapter::Screen |      15   |               8.7 |               142.42% |               137.43% | 1.7e-05   |      22 |
 | Log::Any::Adapter::Null   |      14.1 |               7.8 |               158.22% |               122.89% | 8.9e-06   |      20 |
 | perl -e1 (baseline)       |       6.3 |               0   |               475.56% |                 0.00% | 2.8e-05   |      21 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                Rate  Log::Any::Simple  Log::Any  Log::Any::Proxy  Log::Any::Adapter::Stdout  Log::Any::Adapter::Screen  Log::Any::Adapter::Null  perl -e1 (baseline) 
  Log::Any::Simple            25.0/s                --      -50%             -50%                       -60%                       -62%                     -64%                 -84% 
  Log::Any                    50.0/s              100%        --               0%                       -19%                       -25%                     -29%                 -68% 
  Log::Any::Proxy             50.0/s              100%        0%               --                       -19%                       -25%                     -29%                 -68% 
  Log::Any::Adapter::Stdout   62.5/s              150%       25%              25%                         --                        -6%                     -11%                 -60% 
  Log::Any::Adapter::Screen   66.7/s              166%       33%              33%                         6%                         --                      -6%                 -58% 
  Log::Any::Adapter::Null     70.9/s              183%       41%              41%                        13%                         6%                       --                 -55% 
  perl -e1 (baseline)        158.7/s              534%      217%             217%                       153%                       138%                     123%                   -- 
 
 Legends:
   Log::Any: mod_overhead_time=13.7 participant=Log::Any
   Log::Any::Adapter::Null: mod_overhead_time=7.8 participant=Log::Any::Adapter::Null
   Log::Any::Adapter::Screen: mod_overhead_time=8.7 participant=Log::Any::Adapter::Screen
   Log::Any::Adapter::Stdout: mod_overhead_time=9.7 participant=Log::Any::Adapter::Stdout
   Log::Any::Proxy: mod_overhead_time=13.7 participant=Log::Any::Proxy
   Log::Any::Simple: mod_overhead_time=33.7 participant=Log::Any::Simple
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Log-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Log-Any>.

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

This software is copyright (c) 2024, 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Log-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
