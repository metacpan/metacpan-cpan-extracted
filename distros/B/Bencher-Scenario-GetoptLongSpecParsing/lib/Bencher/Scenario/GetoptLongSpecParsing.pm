package Bencher::Scenario::GetoptLongSpecParsing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark parsing of Getopt::Long option spec',
    modules => {
        'Getopt::Long::Util' => { version=>0.88 },
    },
    participants => [
        {
            module => 'Getopt::Long::Spec',
            code_template => 'Getopt::Long::Spec->new->parse(<spec>)',
        },
        {
            fcall_template => 'Getopt::Long::Util::parse_getopt_long_opt_spec(<spec>)',
        },
    ],
    datasets => [
        {args=>{spec => 'name=s'}},
        {args=>{spec => 'name|N=s@'}},
    ],
};

1;
# ABSTRACT: Benchmark parsing of Getopt::Long option spec

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::GetoptLongSpecParsing - Benchmark parsing of Getopt::Long option spec

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::GetoptLongSpecParsing (from Perl distribution Bencher-Scenario-GetoptLongSpecParsing), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m GetoptLongSpecParsing

To run module startup overhead benchmark:

 % bencher --module-startup -m GetoptLongSpecParsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Getopt::Long::Spec> 0.002

L<Getopt::Long::Util> 0.88

=head1 BENCHMARK PARTICIPANTS

=over

=item * Getopt::Long::Spec (perl_code)

Code template:

 Getopt::Long::Spec->new->parse(<spec>)



=item * Getopt::Long::Util::parse_getopt_long_opt_spec (perl_code)

Function call template:

 Getopt::Long::Util::parse_getopt_long_opt_spec(<spec>)



=back

=head1 BENCHMARK DATASETS

=over

=item * name=s

=item * name|N=s@

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m GetoptLongSpecParsing >>):

 #table1#
 +------------------------------------------------+-----------+-----------+-----------+------------+---------+---------+
 | participant                                    | dataset   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------------------------------+-----------+-----------+-----------+------------+---------+---------+
 | Getopt::Long::Spec                             | name|N=s@ |     73000 |     14    |       1    | 2.7e-08 |      30 |
 | Getopt::Long::Spec                             | name=s    |     90000 |     11    |       1.2  | 1.3e-08 |      20 |
 | Getopt::Long::Util::parse_getopt_long_opt_spec | name|N=s@ |    108000 |      9.22 |       1.49 | 3.3e-09 |      20 |
 | Getopt::Long::Util::parse_getopt_long_opt_spec | name=s    |    121000 |      8.24 |       1.67 | 3.2e-09 |      22 |
 +------------------------------------------------+-----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m GetoptLongSpecParsing --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Getopt::Long::Spec  | 1.1                          | 4.4                | 18             |     17    |                  12.2  |        1   | 3.3e-05 |      21 |
 | Getopt::Long::Util  | 0.824                        | 4.12               | 16             |      8.94 |                   4.14 |        1.9 | 7.8e-06 |      20 |
 | perl -e1 (baseline) | 2.2                          | 5.7                | 19             |      4.8  |                   0    |        3.5 | 6.7e-06 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-GetoptLongSpecParsing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-GetoptLongSpecParsing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-GetoptLongSpecParsing>

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
