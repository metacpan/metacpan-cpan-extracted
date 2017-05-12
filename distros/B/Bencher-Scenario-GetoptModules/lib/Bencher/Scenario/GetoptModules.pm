package Bencher::Scenario::GetoptModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark some popular Perl Getopt modules',

    modules => {
        # minimum versions
        'Getopt::Long::EvenLess' => {version=>'0.10'},
        'Getopt::Long::Subcommand' => {version=>'0.09'},
    },

    module_startup => 1,

    participants => [

        {module=>'Getopt::Std'},

        # Getopt::Long-compatible interface or wrapper
        {module=>'Getopt::Long', tags=>['getopt-long']},
        {module=>'Getopt::Long::Less', tags=>['getopt-long']},
        {module=>'Getopt::Long::EvenLess', tags=>['getopt-long']},
        {module=>'Getopt::Long::Complete', tags=>['getopt-long']},
        {module=>'Getopt::Long::Descriptive', tags=>['getopt-long']},
        {module=>'Getopt::Long::Subcommand', tags=>['getopt-long']},
        {module=>'Getopt::Long::More', tags=>['getopt-long']},
        {module=>'Getopt::Compact', tags=>['getopt-long']},

        # can't be loaded independently
        # {module=>'MooX::Options', tags=>['moo']},

        {module=>'MooseX::Getopt', tags=>['moose']},

        {module=>'Getopt::ArgvFile'},

        {module=>'Getopt::Lucid'},

        {module=>'Getopt::Panjang'},

        {module=>'Getopt::Std::Strict'},

        {module=>'Getopt::Alt'},

        # nodejs-inspired
        {module=>'Smart::Options'},

        # python-inspired
        {module=>'Getopt::ArgParse'},

    ],
};

1;
# ABSTRACT: Benchmark some popular Perl Getopt modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::GetoptModules - Benchmark some popular Perl Getopt modules

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::GetoptModules (from Perl distribution Bencher-Scenario-GetoptModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m GetoptModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Getopt::Alt> 0.4.2

L<Getopt::ArgParse> 1.0.6

L<Getopt::ArgvFile> 1.11

L<Getopt::Compact> 0.04

L<Getopt::Long> 2.48

L<Getopt::Long::Complete> 0.30

L<Getopt::Long::Descriptive> 0.100

L<Getopt::Long::EvenLess> 0.10

L<Getopt::Long::Less> 0.08

L<Getopt::Long::More> 0.004

L<Getopt::Long::Subcommand> 0.09

L<Getopt::Lucid> 1.07

L<Getopt::Panjang> 0.04

L<Getopt::Std> 1.11

L<Getopt::Std::Strict> 1.01

L<MooseX::Getopt> 0.71

L<Smart::Options> 0.056

=head1 BENCHMARK PARTICIPANTS

=over

=item * Getopt::Std (perl_code)

L<Getopt::Std>



=item * Getopt::Long (perl_code) [getopt-long]

L<Getopt::Long>



=item * Getopt::Long::Less (perl_code) [getopt-long]

L<Getopt::Long::Less>



=item * Getopt::Long::EvenLess (perl_code) [getopt-long]

L<Getopt::Long::EvenLess>



=item * Getopt::Long::Complete (perl_code) [getopt-long]

L<Getopt::Long::Complete>



=item * Getopt::Long::Descriptive (perl_code) [getopt-long]

L<Getopt::Long::Descriptive>



=item * Getopt::Long::Subcommand (perl_code) [getopt-long]

L<Getopt::Long::Subcommand>



=item * Getopt::Long::More (perl_code) [getopt-long]

L<Getopt::Long::More>



=item * Getopt::Compact (perl_code) [getopt-long]

L<Getopt::Compact>



=item * MooseX::Getopt (perl_code) [moose]

L<MooseX::Getopt>



=item * Getopt::ArgvFile (perl_code)

L<Getopt::ArgvFile>



=item * Getopt::Lucid (perl_code)

L<Getopt::Lucid>



=item * Getopt::Panjang (perl_code)

L<Getopt::Panjang>



=item * Getopt::Std::Strict (perl_code)

L<Getopt::Std::Strict>



=item * Getopt::Alt (perl_code)

L<Getopt::Alt>



=item * Smart::Options (perl_code)

L<Smart::Options>



=item * Getopt::ArgParse (perl_code)

L<Getopt::ArgParse>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m GetoptModules >>):

 #table1#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Getopt::Alt               | 5                            | 9                  | 30             |     300   |                  295.6 |        1   |   0.0084  |      21 |
 | MooseX::Getopt            | 2.4                          | 5.7                | 20             |     210   |                  205.6 |        1.4 |   0.00035 |      20 |
 | Getopt::ArgParse          | 0.82                         | 4.1                | 16             |      49   |                   44.6 |        5.9 |   0.00044 |      20 |
 | Smart::Options            | 6                            | 9.7                | 32             |      35   |                   30.6 |        8.2 |   0.00028 |      20 |
 | Getopt::Long::Descriptive | 1.1                          | 4.4                | 16             |      34   |                   29.6 |        8.4 | 7.9e-05   |      20 |
 | Getopt::Lucid             | 0.97                         | 4.4                | 16             |      27   |                   22.6 |       11   |   0.00014 |      20 |
 | Getopt::Compact           | 18                           | 22                 | 58             |      23   |                   18.6 |       13   |   0.00015 |      20 |
 | Getopt::ArgvFile          | 3.5                          | 7                  | 27             |      21   |                   16.6 |       14   | 5.2e-05   |      20 |
 | Getopt::Long              | 1.1                          | 4.4                | 18             |      17   |                   12.6 |       17   | 7.8e-05   |      20 |
 | Getopt::Std::Strict       | 20                           | 30                 | 70             |      10   |                    5.6 |       20   |   0.0005  |      20 |
 | Getopt::Long::Subcommand  | 1.1                          | 4.5                | 16             |       8.3 |                    3.9 |       35   | 4.2e-05   |      20 |
 | Getopt::Long::Complete    | 4.2                          | 7.7                | 25             |       7.7 |                    3.3 |       38   | 3.5e-05   |      21 |
 | Getopt::Long::More        | 2.8                          | 6.3                | 20             |       7.3 |                    2.9 |       40   | 4.5e-05   |      21 |
 | Getopt::Long::Less        | 0.94                         | 4.2                | 16             |       7.2 |                    2.8 |       40   | 4.5e-05   |      20 |
 | Getopt::Panjang           | 0.99                         | 4.3                | 16             |       6.1 |                    1.7 |       47   | 2.7e-05   |      20 |
 | Getopt::Std               | 2                            | 5.4                | 17             |       6   |                    1.6 |       48   | 1.3e-05   |      21 |
 | Getopt::Long::EvenLess    | 0.97                         | 4.3                | 16             |       5.4 |                    1   |       53   | 1.3e-05   |      20 |
 | perl -e1 (baseline)       | 1                            | 4.3                | 16             |       4.4 |                    0   |       66   | 1.4e-05   |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-GetoptModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-StartupGetoptModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-GetoptModules>

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
