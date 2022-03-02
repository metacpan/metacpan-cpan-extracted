package Bencher::Scenario::CmdLineParsingModules;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-01'; # DATE
our $DIST = 'Bencher-Scenario-CmdLineParsingModules'; # DIST
our $VERSION = '0.081'; # VERSION

our $scenario = {
    summary => 'Benchmark command-line parsing modules',
    modules => {
        'Complete::Bash' => {version=>0.333},
    },
    participants => [
        {
            fcall_template => 'Parse::CommandLine::parse_command_line(<cmdline>)',
            result_is_list => 1,
        },
        {
            fcall_template => 'Complete::Bash::parse_cmdline(<cmdline>, 0)',
        },
        {
            fcall_template => 'Text::ParseWords::shellwords(<cmdline>)',
            result_is_list => 1,
        },
        {
            fcall_template => 'Parse::CommandLine::Regexp::parse_command_line(<cmdline>)',
            result_is_list => 1,
        },
    ],

    datasets => [
        {
            name => 'empty',
            args => {
                cmdline => q[],
            },
        },
        {
            name => 'cmd-only',
            args => {
                cmdline => q[somecmd],
            },
        },
        {
            name => '2args-simple',
            args => {
                cmdline => q[somecmd arg1 arg-two],
            },
        },
        {
            name => '4args',
            args => {
                cmdline => q[command '' arg1 "arg2 in quotes" arg3\\ with\\ spaces "arg4 with \\"quotes\\" and \\\\backslash"],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark command-line parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CmdLineParsingModules - Benchmark command-line parsing modules

=head1 VERSION

This document describes version 0.081 of Bencher::Scenario::CmdLineParsingModules (from Perl distribution Bencher-Scenario-CmdLineParsingModules), released on 2021-10-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CmdLineParsingModules

To run module startup overhead benchmark:

 % bencher --module-startup -m CmdLineParsingModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Complete::Bash> 0.335

L<Parse::CommandLine> 0.02

L<Parse::CommandLine::Regexp> 0.002

L<Text::ParseWords> 3.30

=head1 BENCHMARK PARTICIPANTS

=over

=item * Parse::CommandLine::parse_command_line (perl_code)

Function call template:

 Parse::CommandLine::parse_command_line(<cmdline>)



=item * Complete::Bash::parse_cmdline (perl_code)

Function call template:

 Complete::Bash::parse_cmdline(<cmdline>, 0)



=item * Text::ParseWords::shellwords (perl_code)

Function call template:

 Text::ParseWords::shellwords(<cmdline>)



=item * Parse::CommandLine::Regexp::parse_command_line (perl_code)

Function call template:

 Parse::CommandLine::Regexp::parse_command_line(<cmdline>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * cmd-only

=item * 2args-simple

=item * 4args

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m CmdLineParsingModules >>):

 #table1#
 +------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                    | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Parse::CommandLine::parse_command_line         | 4args        |     35600 |  28.1     |                 0.00% |             19390.93% | 1.1e-08 |      30 |
 | Complete::Bash::parse_cmdline                  | 4args        |     41400 |  24.2     |                16.16% |             16678.73% |   2e-08 |      20 |
 | Text::ParseWords::shellwords                   | 4args        |     42300 |  23.6     |                18.79% |             16307.41% |   2e-08 |      20 |
 | Parse::CommandLine::Regexp::parse_command_line | 4args        |     66000 |  15       |                85.74% |             10393.45% | 2.7e-08 |      20 |
 | Complete::Bash::parse_cmdline                  | 2args-simple |    102000 |   9.82    |               185.82% |              6719.24% | 3.3e-09 |      20 |
 | Text::ParseWords::shellwords                   | 2args-simple |    106000 |   9.4     |               198.64% |              6426.60% | 3.1e-09 |      23 |
 | Parse::CommandLine::parse_command_line         | 2args-simple |    139000 |   7.21    |               289.29% |              4906.80% | 3.2e-09 |      22 |
 | Parse::CommandLine::Regexp::parse_command_line | 2args-simple |    161000 |   6.22    |               351.42% |              4217.69% | 1.6e-09 |      21 |
 | Complete::Bash::parse_cmdline                  | cmd-only     |    230000 |   4.3     |               558.81% |              2858.51% | 6.7e-09 |      20 |
 | Text::ParseWords::shellwords                   | cmd-only     |    277000 |   3.61    |               678.61% |              2403.29% | 1.4e-09 |      27 |
 | Parse::CommandLine::parse_command_line         | cmd-only     |    373880 |   2.6747  |               949.90% |              1756.46% | 5.8e-12 |      34 |
 | Parse::CommandLine::Regexp::parse_command_line | cmd-only     |    402000 |   2.49    |              1027.91% |              1628.06% | 7.9e-10 |      22 |
 | Complete::Bash::parse_cmdline                  | empty        |   1134500 |   0.88142 |              3085.92% |               511.78% | 5.7e-12 |      20 |
 | Text::ParseWords::shellwords                   | empty        |   1700000 |   0.588   |              4676.81% |               308.03% | 2.1e-10 |      20 |
 | Parse::CommandLine::parse_command_line         | empty        |   3190000 |   0.313   |              8860.96% |               117.51% |   1e-10 |      20 |
 | Parse::CommandLine::Regexp::parse_command_line | empty        |   6900000 |   0.14    |             19390.93% |                 0.00% | 2.1e-10 |      20 |
 +------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  PC:p_c_l 4args  CB:p_c 4args  TP:s 4args  PCR:p_c_l 4args  CB:p_c 2args-simple  TP:s 2args-simple  PC:p_c_l 2args-simple  PCR:p_c_l 2args-simple  CB:p_c cmd-only  TP:s cmd-only  PC:p_c_l cmd-only  PCR:p_c_l cmd-only  CB:p_c empty  TP:s empty  PC:p_c_l empty  PCR:p_c_l empty 
  PC:p_c_l 4args            35600/s              --          -13%        -16%             -46%                 -65%               -66%                   -74%                    -77%             -84%           -87%               -90%                -91%          -96%        -97%            -98%             -99% 
  CB:p_c 4args              41400/s             16%            --         -2%             -38%                 -59%               -61%                   -70%                    -74%             -82%           -85%               -88%                -89%          -96%        -97%            -98%             -99% 
  TP:s 4args                42300/s             19%            2%          --             -36%                 -58%               -60%                   -69%                    -73%             -81%           -84%               -88%                -89%          -96%        -97%            -98%             -99% 
  PCR:p_c_l 4args           66000/s             87%           61%         57%               --                 -34%               -37%                   -51%                    -58%             -71%           -75%               -82%                -83%          -94%        -96%            -97%             -99% 
  CB:p_c 2args-simple      102000/s            186%          146%        140%              52%                   --                -4%                   -26%                    -36%             -56%           -63%               -72%                -74%          -91%        -94%            -96%             -98% 
  TP:s 2args-simple        106000/s            198%          157%        151%              59%                   4%                 --                   -23%                    -33%             -54%           -61%               -71%                -73%          -90%        -93%            -96%             -98% 
  PC:p_c_l 2args-simple    139000/s            289%          235%        227%             108%                  36%                30%                     --                    -13%             -40%           -49%               -62%                -65%          -87%        -91%            -95%             -98% 
  PCR:p_c_l 2args-simple   161000/s            351%          289%        279%             141%                  57%                51%                    15%                      --             -30%           -41%               -56%                -59%          -85%        -90%            -94%             -97% 
  CB:p_c cmd-only          230000/s            553%          462%        448%             248%                 128%               118%                    67%                     44%               --           -16%               -37%                -42%          -79%        -86%            -92%             -96% 
  TP:s cmd-only            277000/s            678%          570%        553%             315%                 172%               160%                    99%                     72%              19%             --               -25%                -31%          -75%        -83%            -91%             -96% 
  PC:p_c_l cmd-only        373880/s            950%          804%        782%             460%                 267%               251%                   169%                    132%              60%            34%                 --                 -6%          -67%        -78%            -88%             -94% 
  PCR:p_c_l cmd-only       402000/s           1028%          871%        847%             502%                 294%               277%                   189%                    149%              72%            44%                 7%                  --          -64%        -76%            -87%             -94% 
  CB:p_c empty            1134500/s           3088%         2645%       2577%            1601%                1014%               966%                   717%                    605%             387%           309%               203%                182%            --        -33%            -64%             -84% 
  TP:s empty              1700000/s           4678%         4015%       3913%            2451%                1570%              1498%                  1126%                    957%             631%           513%               354%                323%           49%          --            -46%             -76% 
  PC:p_c_l empty          3190000/s           8877%         7631%       7439%            4692%                3037%              2903%                  2203%                   1887%            1273%          1053%               754%                695%          181%         87%              --             -55% 
  PCR:p_c_l empty         6900000/s          19971%        17185%      16757%           10614%                6914%              6614%                  5049%                   4342%            2971%          2478%              1810%               1678%          529%        319%            123%               -- 
 
 Legends:
   CB:p_c 2args-simple: dataset=2args-simple participant=Complete::Bash::parse_cmdline
   CB:p_c 4args: dataset=4args participant=Complete::Bash::parse_cmdline
   CB:p_c cmd-only: dataset=cmd-only participant=Complete::Bash::parse_cmdline
   CB:p_c empty: dataset=empty participant=Complete::Bash::parse_cmdline
   PC:p_c_l 2args-simple: dataset=2args-simple participant=Parse::CommandLine::parse_command_line
   PC:p_c_l 4args: dataset=4args participant=Parse::CommandLine::parse_command_line
   PC:p_c_l cmd-only: dataset=cmd-only participant=Parse::CommandLine::parse_command_line
   PC:p_c_l empty: dataset=empty participant=Parse::CommandLine::parse_command_line
   PCR:p_c_l 2args-simple: dataset=2args-simple participant=Parse::CommandLine::Regexp::parse_command_line
   PCR:p_c_l 4args: dataset=4args participant=Parse::CommandLine::Regexp::parse_command_line
   PCR:p_c_l cmd-only: dataset=cmd-only participant=Parse::CommandLine::Regexp::parse_command_line
   PCR:p_c_l empty: dataset=empty participant=Parse::CommandLine::Regexp::parse_command_line
   TP:s 2args-simple: dataset=2args-simple participant=Text::ParseWords::shellwords
   TP:s 4args: dataset=4args participant=Text::ParseWords::shellwords
   TP:s cmd-only: dataset=cmd-only participant=Text::ParseWords::shellwords
   TP:s empty: dataset=empty participant=Text::ParseWords::shellwords

Benchmark module startup overhead (C<< bencher -m CmdLineParsingModules --module-startup >>):

 #table2#
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Complete::Bash             |     11    |              4.9  |                 0.00% |                81.06% | 1.8e-05 |      20 |
 | Text::ParseWords           |      9.27 |              3.17 |                19.62% |                51.36% | 8.3e-06 |      20 |
 | Parse::CommandLine         |      8.9  |              2.8  |                24.02% |                45.99% | 9.1e-06 |      20 |
 | Parse::CommandLine::Regexp |      8.8  |              2.7  |                25.37% |                44.43% | 9.2e-06 |      20 |
 | perl -e1 (baseline)        |      6.1  |              0    |                81.06% |                 0.00% | 3.3e-05 |      20 |
 +----------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  C:B   T:P   P:C  PC:R  perl -e1 (baseline) 
  C:B                   90.9/s   --  -15%  -19%  -19%                 -44% 
  T:P                  107.9/s  18%    --   -3%   -5%                 -34% 
  P:C                  112.4/s  23%    4%    --   -1%                 -31% 
  PC:R                 113.6/s  25%    5%    1%    --                 -30% 
  perl -e1 (baseline)  163.9/s  80%   51%   45%   44%                   -- 
 
 Legends:
   C:B: mod_overhead_time=4.9 participant=Complete::Bash
   P:C: mod_overhead_time=2.8 participant=Parse::CommandLine
   PC:R: mod_overhead_time=2.7 participant=Parse::CommandLine::Regexp
   T:P: mod_overhead_time=3.17 participant=Text::ParseWords
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CmdLineParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CmdLineParsingModules>.

=head1 SEE ALSO

L<Acme::CPANModules::Parse::UnixShellCommandLine>

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

This software is copyright (c) 2021, 2019, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CmdLineParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
