package Bencher::Scenario::DateTimeFormatDurationISO8601::Parsing;

our $DATE = '2018-07-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark parsing with DateTime::Format::Duration::ISO8601',
    participants => [
        {
            name => 'parse_duration',
            fcall_template => 'DateTime::Format::Duration::ISO8601->parse_duration(<str>)',
        },
    ],
    datasets => [
        {args => {'str@' => ['P1Y', 'PT1S', 'P1Y2M3DT4H5M6.7S']}},
    ],
};

1;
# ABSTRACT: Benchmark parsing with DateTime::Format::Duration::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatDurationISO8601::Parsing - Benchmark parsing with DateTime::Format::Duration::ISO8601

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatDurationISO8601::Parsing (from Perl distribution Bencher-Scenarios-DateTimeFormatDurationISO8601), released on 2018-07-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatDurationISO8601::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeFormatDurationISO8601::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Duration::ISO8601> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * parse_duration (perl_code)

Function call template:

 DateTime::Format::Duration::ISO8601->parse_duration(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ["P1Y","PT1S","P1Y2M3DT4H5M6.7S"]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatDurationISO8601::Parsing >>):

 #table1#
 +------------------+-----------+-----------+------------+---------+---------+
 | arg_str          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------+-----------+-----------+------------+---------+---------+
 | P1Y2M3DT4H5M6.7S |     26000 |        38 |        1   | 6.2e-08 |      23 |
 | P1Y              |     40000 |        20 |        2   | 1.1e-06 |      27 |
 | PT1S             |     55000 |        18 |        2.1 | 5.3e-08 |      20 |
 +------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeFormatDurationISO8601::Parsing --module-startup >>):

 #table2#
 +-------------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------------+-----------+------------------------+------------+---------+---------+
 | DateTime::Format::Duration::ISO8601 |       8.3 |                      3 |        1   | 2.4e-05 |      20 |
 | perl -e1 (baseline)                 |       5.3 |                      0 |        1.6 | 1.5e-05 |      20 |
 +-------------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatDurationISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatDurationISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatDurationISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
