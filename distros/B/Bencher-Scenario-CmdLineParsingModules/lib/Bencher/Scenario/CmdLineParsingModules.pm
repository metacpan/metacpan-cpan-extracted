package Bencher::Scenario::CmdLineParsingModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

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

This document describes version 0.06 of Bencher::Scenario::CmdLineParsingModules (from Perl distribution Bencher-Scenario-CmdLineParsingModules), released on 2017-01-25.

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

L<Complete::Bash> 0.31

L<Parse::CommandLine> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Parse::CommandLine::parse_command_line (perl_code)

Function call template:

 Parse::CommandLine::parse_command_line(<cmdline>)



=item * Complete::Bash::parse_cmdline (perl_code)

Function call template:

 Complete::Bash::parse_cmdline(<cmdline>, 0)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * cmd-only

=item * 2args-simple

=item * 4args

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m CmdLineParsingModules >>):

 #table1#
 +----------------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | participant                            | dataset      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | Parse::CommandLine::parse_command_line | 4args        |     34000 | 29.4      |     1      | 1.2e-08 |      24 |
 | Complete::Bash::parse_cmdline          | 4args        |     38100 | 26.2      |     1.12   | 1.3e-08 |      20 |
 | Complete::Bash::parse_cmdline          | 2args-simple |     93000 | 11        |     2.7    | 1.3e-08 |      20 |
 | Parse::CommandLine::parse_command_line | 2args-simple |    137000 |  7.29     |     4.03   | 3.3e-09 |      20 |
 | Complete::Bash::parse_cmdline          | cmd-only     |    220000 |  4.5      |     6.5    | 6.5e-09 |      21 |
 | Parse::CommandLine::parse_command_line | cmd-only     |    354000 |  2.82     |    10.4    | 6.7e-10 |      31 |
 | Complete::Bash::parse_cmdline          | empty        |   1300000 |  0.8      |    37      | 1.7e-09 |      20 |
 | Parse::CommandLine::parse_command_line | empty        |   2949820 |  0.339004 |    86.6955 |   0     |      20 |
 +----------------------------------------+--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m CmdLineParsingModules --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Parse::CommandLine  | 1.1                          | 4.4                | 16             |       9.5 |                    4   |        1   | 3.9e-05 |      20 |
 | Complete::Bash      | 0.82                         | 4.1                | 16             |       9.4 |                    3.9 |        1   | 1.8e-05 |      20 |
 | perl -e1 (baseline) | 1                            | 4.5                | 16             |       5.5 |                    0   |        1.7 | 1.5e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
