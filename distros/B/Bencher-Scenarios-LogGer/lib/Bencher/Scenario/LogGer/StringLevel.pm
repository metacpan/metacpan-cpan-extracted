package Bencher::Scenario::LogGer::StringLevel;

our $DATE = '2017-08-04'; # DATE
our $VERSION = '0.012'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::LogGer::StringLevel - Benchmark string_level()

=head1 VERSION

This document describes version 0.012 of Bencher::Scenario::LogGer::StringLevel (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-08-04.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::StringLevel

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::StringLevel

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Util> 0.023

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m LogGer::StringLevel >>):

 #table1#
 +---------+-----------+-----------+------------+---------+---------+
 | dataset | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +---------+-----------+-----------+------------+---------+---------+
 | 10      |   1000000 |       980 |        1   | 1.9e-09 |      24 |
 | warn    |   3800000 |       260 |        3.8 | 1.5e-09 |      25 |
 +---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::StringLevel --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Util      | 0.56                         | 4                  | 20             |        13 |                      7 |        1   | 4.5e-05 |      20 |
 | perl -e1 (baseline) | 1.3                          | 4.8                | 20             |         6 |                      0 |        2.2 | 1.8e-05 |      21 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

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
