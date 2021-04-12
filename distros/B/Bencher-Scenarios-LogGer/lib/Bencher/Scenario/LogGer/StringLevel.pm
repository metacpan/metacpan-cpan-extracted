package Bencher::Scenario::LogGer::StringLevel;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.018'; # VERSION

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

This document describes version 0.018 of Bencher::Scenario::LogGer::StringLevel (from Perl distribution Bencher-Scenarios-LogGer), released on 2021-04-09.

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

L<Log::ger::Util> 0.038

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

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LogGer::StringLevel >>):

 #table1#
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 10      |    888700 |      1125 |                 0.00% |               624.43% | 2.3e-11 |      20 |
 | warn    |   6440000 |       155 |               624.43% |                 0.00% | 2.3e-11 |      20 |
 +---------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::StringLevel --module-startup >>):

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Util      |      11.9 |               4.1 |                 0.00% |                52.46% | 1.1e-05 |      20 |
 | perl -e1 (baseline) |       7.8 |               0   |                52.46% |                 0.00% | 2.1e-05 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
