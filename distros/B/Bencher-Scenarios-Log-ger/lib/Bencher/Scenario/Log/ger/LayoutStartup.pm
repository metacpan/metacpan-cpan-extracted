package Bencher::Scenario::Log::ger::LayoutStartup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-ger'; # DIST
our $VERSION = '0.019'; # VERSION

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

This document describes version 0.019 of Bencher::Scenario::Log::ger::LayoutStartup (from Perl distribution Bencher-Scenarios-Log-ger), released on 2023-10-29.

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

L<Log::ger::Layout::Pattern> 0.008

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

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::LayoutStartup

Result formatted as table:

 #table1#
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant  | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | load-JSON    |      76.6 |     13    |                 0.00% |               102.08% | 7.5e-06 |      20 |
 | load-YAML    |      76.8 |     13    |                 0.16% |               101.76% | 4.9e-06 |      20 |
 | load-Pattern |      78.7 |     12.7  |                 2.74% |                96.68% | 3.3e-06 |      20 |
 | load-LTSV    |      78.8 |     12.7  |                 2.80% |                96.57% | 7.6e-06 |      20 |
 | baseline     |     155   |      6.46 |               102.08% |                 0.00% | 2.9e-06 |      21 |
 +--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                  Rate  load-JSON  load-YAML  load-Pattern  load-LTSV  baseline 
  load-JSON     76.6/s         --         0%           -2%        -2%      -50% 
  load-YAML     76.8/s         0%         --           -2%        -2%      -50% 
  load-Pattern  78.7/s         2%         2%            --         0%      -49% 
  load-LTSV     78.8/s         2%         2%            0%         --      -49% 
  baseline       155/s       101%       101%           96%        96%        -- 
 
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
 | Log::ger::Layout::JSON    |     13    |              6.54 |                 0.00% |               101.76% | 4.9e-06 |      20 |
 | Log::ger::Layout::YAML    |     13    |              6.54 |                 0.01% |               101.74% | 4.9e-06 |      20 |
 | Log::ger::Layout::Pattern |     12.7  |              6.24 |                 2.46% |                96.92% | 7.2e-06 |      20 |
 | Log::ger::Layout::LTSV    |     12.7  |              6.24 |                 2.51% |                96.82% | 7.4e-06 |      20 |
 | perl -e1 (baseline)       |      6.46 |              0    |               101.76% |                 0.00% |   5e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  LgL:J  LgL:Y  LgL:P  LgL:L  perl -e1 (baseline) 
  LgL:J                 76.9/s     --     0%    -2%    -2%                 -50% 
  LgL:Y                 76.9/s     0%     --    -2%    -2%                 -50% 
  LgL:P                 78.7/s     2%     2%     --     0%                 -49% 
  LgL:L                 78.7/s     2%     2%     0%     --                 -49% 
  perl -e1 (baseline)  154.8/s   101%   101%    96%    96%                   -- 
 
 Legends:
   LgL:J: mod_overhead_time=6.54 participant=Log::ger::Layout::JSON
   LgL:L: mod_overhead_time=6.24 participant=Log::ger::Layout::LTSV
   LgL:P: mod_overhead_time=6.24 participant=Log::ger::Layout::Pattern
   LgL:Y: mod_overhead_time=6.54 participant=Log::ger::Layout::YAML
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-ger>.

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

This software is copyright (c) 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
