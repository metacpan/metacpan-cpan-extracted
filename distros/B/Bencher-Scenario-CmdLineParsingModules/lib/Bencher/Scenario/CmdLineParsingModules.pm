package Bencher::Scenario::CmdLineParsingModules;

our $DATE = '2019-02-10'; # DATE
our $VERSION = '0.080'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark command-line parsing modules',
    modules => {
        'Complete::Bash' => {version=>0.27},
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

This document describes version 0.080 of Bencher::Scenario::CmdLineParsingModules (from Perl distribution Bencher-Scenario-CmdLineParsingModules), released on 2019-02-10.

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

L<Complete::Bash> 0.320

L<Parse::CommandLine> 0.02

L<Parse::CommandLine::Regexp> 0.001

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m CmdLineParsingModules >>):

 #table1#
 +------------------------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | participant                                    | dataset      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | Parse::CommandLine::parse_command_line         | 4args        |     31800 |   31.4    |     1      | 1.1e-08 |      27 |
 | Complete::Bash::parse_cmdline                  | 4args        |     33500 |   29.8    |     1.05   | 1.3e-08 |      21 |
 | Text::ParseWords::shellwords                   | 4args        |     37046 |   26.993  |     1.1637 | 9.1e-11 |      20 |
 | Parse::CommandLine::Regexp::parse_command_line | 4args        |     54000 |   18      |     1.7    | 2.6e-08 |      21 |
 | Complete::Bash::parse_cmdline                  | 2args-simple |     84000 |   12      |     2.6    | 1.3e-08 |      21 |
 | Text::ParseWords::shellwords                   | 2args-simple |     95000 |   11      |     3      | 1.3e-08 |      20 |
 | Parse::CommandLine::parse_command_line         | 2args-simple |    130000 |    7.7    |     4.1    |   1e-08 |      20 |
 | Parse::CommandLine::Regexp::parse_command_line | 2args-simple |    136000 |    7.33   |     4.29   | 3.3e-09 |      20 |
 | Complete::Bash::parse_cmdline                  | cmd-only     |    200000 |    5      |     6      |   1e-07 |      29 |
 | Text::ParseWords::shellwords                   | cmd-only     |    236000 |    4.24   |     7.41   | 1.7e-09 |      20 |
 | Parse::CommandLine::parse_command_line         | cmd-only     |    334760 |    2.9872 |    10.515  | 1.1e-11 |      27 |
 | Parse::CommandLine::Regexp::parse_command_line | cmd-only     |    340000 |    2.9    |    11      | 3.1e-09 |      23 |
 | Complete::Bash::parse_cmdline                  | empty        |   1030000 |    0.967  |    32.5    | 4.1e-10 |      31 |
 | Text::ParseWords::shellwords                   | empty        |   1300000 |    0.78   |    40      | 1.6e-09 |      23 |
 | Parse::CommandLine::parse_command_line         | empty        |   2600000 |    0.39   |    81      | 9.3e-10 |      25 |
 | Parse::CommandLine::Regexp::parse_command_line | empty        |   5848000 |    0.171  |   183.7    | 1.2e-11 |      22 |
 +------------------------------------------------+--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m CmdLineParsingModules --module-startup >>):

 #table2#
 +----------------------------+-----------+------------------------+------------+---------+---------+
 | participant                | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------------+-----------+------------------------+------------+---------+---------+
 | Complete::Bash             |       8.7 |                    4.2 |        1   | 2.8e-05 |      20 |
 | Parse::CommandLine         |       7.7 |                    3.2 |        1.1 | 2.1e-05 |      20 |
 | Text::ParseWords           |       7.5 |                    3   |        1.2 | 2.2e-05 |      22 |
 | Parse::CommandLine::Regexp |       7.2 |                    2.7 |        1.2 | 3.5e-05 |      20 |
 | perl -e1 (baseline)        |       4.5 |                    0   |        1.9 | 1.9e-05 |      20 |
 +----------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CmdLineParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CmdLineParsingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CmdLineParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
