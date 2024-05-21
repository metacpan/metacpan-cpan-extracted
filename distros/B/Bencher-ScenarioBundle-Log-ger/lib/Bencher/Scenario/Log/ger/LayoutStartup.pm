package Bencher::Scenario::Log::ger::LayoutStartup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

our %layout_modules = (
    Pattern => {format=>'[%d] %m'},
    LTSV => {},
    JSON => {},
    YAML => {},
);

our $scenario = {
    modules => {
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        map {
            (
                +{
                    name => "load-$_",
                    module => "Log::ger::Layout::$_",
                    perl_cmdline => ["-mLog::ger::Layout::$_", "-e1"],
                },
            )
        } sort keys %layout_modules,
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::LayoutStartup

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::Log::ger::LayoutStartup (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::LayoutStartup

To run module startup overhead benchmark:

 % bencher --module-startup -m Log::ger::LayoutStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Layout::JSON> 0.002

L<Log::ger::Layout::LTSV> 0.006

L<Log::ger::Layout::Pattern> 0.009

L<Log::ger::Layout::YAML> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * load-JSON (command)

L<Log::ger::Layout::JSON>



=item * load-LTSV (command)

L<Log::ger::Layout::LTSV>



=item * load-Pattern (command)

L<Log::ger::Layout::Pattern>



=item * load-YAML (command)

L<Log::ger::Layout::YAML>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::LayoutStartup

Result formatted as table:

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | load-JSON    |      77.1 |     13    |                 0.00% |               103.63% | 9.1e-06 |      20 |
 | load-YAML    |      77.3 |     12.9  |                 0.33% |               102.96% | 8.2e-06 |      20 |
 | load-Pattern |      79   |     12.7  |                 2.48% |                98.69% | 1.1e-05 |      20 |
 | load-LTSV    |      79.2 |     12.6  |                 2.75% |                98.18% | 1.1e-05 |      20 |
 | baseline     |     157   |      6.37 |               103.63% |                 0.00% | 5.9e-06 |      20 |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                  Rate  load-JSON  load-YAML  load-Pattern  load-LTSV  baseline 
  load-JSON     77.1/s         --         0%           -2%        -3%      -51% 
  load-YAML     77.3/s         0%         --           -1%        -2%      -50% 
  load-Pattern    79/s         2%         1%            --         0%      -49% 
  load-LTSV     79.2/s         3%         2%            0%         --      -49% 
  baseline       157/s       104%       102%           99%        97%        -- 
 
 Legends:
   baseline: participant=baseline
   load-JSON: participant=load-JSON
   load-LTSV: participant=load-LTSV
   load-Pattern: participant=load-Pattern
   load-YAML: participant=load-YAML

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Log::ger::LayoutStartup --module-startup

Result formatted as table:

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Layout::JSON    |     13    |              6.64 |                 0.00% |               104.13% |   9e-06 |      20 |
 | Log::ger::Layout::YAML    |     13    |              6.64 |                 0.18% |               103.77% | 8.2e-06 |      20 |
 | Log::ger::Layout::LTSV    |     12.7  |              6.34 |                 2.50% |                99.15% | 1.2e-05 |      20 |
 | Log::ger::Layout::Pattern |     12.6  |              6.24 |                 2.61% |                98.94% | 9.2e-06 |      20 |
 | perl -e1 (baseline)       |      6.36 |              0    |               104.13% |                 0.00% | 3.4e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  LgL:J  LgL:Y  LgL:L  LgL:P  perl -e1 (baseline) 
  LgL:J                 76.9/s     --     0%    -2%    -3%                 -51% 
  LgL:Y                 76.9/s     0%     --    -2%    -3%                 -51% 
  LgL:L                 78.7/s     2%     2%     --     0%                 -49% 
  LgL:P                 79.4/s     3%     3%     0%     --                 -49% 
  perl -e1 (baseline)  157.2/s   104%   104%    99%    98%                   -- 
 
 Legends:
   LgL:J: mod_overhead_time=6.64 participant=Log::ger::Layout::JSON
   LgL:L: mod_overhead_time=6.34 participant=Log::ger::Layout::LTSV
   LgL:P: mod_overhead_time=6.24 participant=Log::ger::Layout::Pattern
   LgL:Y: mod_overhead_time=6.64 participant=Log::ger::Layout::YAML
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
