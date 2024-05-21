package Bencher::Scenario::Log::ger::StringLevel;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

our $scenario = {
    summary => 'Benchmark string_level()',
    modules => {
        'Log::ger::Util' => {version=>'0.008'},
    },
    participants => [
        {
            fcall_template => 'Log::ger::Util::string_level(<level>)',
        },
    ],
    datasets => [
        {args=>{level=>10}},
        {args=>{level=>'warn'}},
    ],
};

1;
# ABSTRACT: Benchmark string_level()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::StringLevel - Benchmark string_level()

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::Log::ger::StringLevel (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::StringLevel

To run module startup overhead benchmark:

 % bencher --module-startup -m Log::ger::StringLevel

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Util> 0.042

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::ger::Util::string_level (perl_code)

Function call template:

 Log::ger::Util::string_level(<level>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 10

=item * warn

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::StringLevel

Result formatted as table:

 #table1#
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 10      |    878000 |      1140 |                 0.00% |               613.01% | 7.9e-10 |      20 |
 | warn    |   6260000 |       160 |               613.01% |                 0.00% | 8.1e-11 |      20 |
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

             Rate    10  warn 
  10     878000/s    --  -85% 
  warn  6260000/s  612%    -- 
 
 Legends:
   10: dataset=10
   warn: dataset=warn

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Log::ger::StringLevel --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Util      |     11.9  |              5.02 |                 0.00% |                73.43% | 2.6e-06 |      20 |
 | perl -e1 (baseline) |      6.88 |              0    |                73.43% |                 0.00% | 4.2e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  Lg:U  perl -e1 (baseline) 
  Lg:U                  84.0/s    --                 -42% 
  perl -e1 (baseline)  145.3/s   72%                   -- 
 
 Legends:
   Lg:U: mod_overhead_time=5.02 participant=Log::ger::Util
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Log-ger>.

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

This software is copyright (c) 2024, 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
