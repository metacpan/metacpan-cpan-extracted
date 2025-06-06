package Bencher::Scenario::DateTime::Format::Duration::ISO8601::Parsing;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-DateTime-Format-Duration-ISO8601'; # DIST
our $VERSION = '0.002'; # VERSION

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

Bencher::Scenario::DateTime::Format::Duration::ISO8601::Parsing - Benchmark parsing with DateTime::Format::Duration::ISO8601

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DateTime::Format::Duration::ISO8601::Parsing (from Perl distribution Bencher-Scenarios-DateTime-Format-Duration-ISO8601), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTime::Format::Duration::ISO8601::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTime::Format::Duration::ISO8601::Parsing

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m DateTime::Format::Duration::ISO8601::Parsing >>):

 #table1#
 +------------------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | arg_str          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest | errors | samples |
 +------------------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | P1Y2M3DT4H5M6.7S |   32292.8 |   30.9667 |                 0.00% |               155.86% |  0     |      20 |
 | PT1S             |   74143.6 |   13.4873 |               129.60% |                11.44% |  0     |      21 |
 | P1Y              |   82600   |   12.1    |               155.86% |                 0.00% |  3e-09 |      25 |
 +------------------+-----------+-----------+-----------------------+-----------------------+--------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                         Rate  P1Y2M3DT4H5M6.7S  PT1S   P1Y 
  P1Y2M3DT4H5M6.7S  32292.8/s                --  -56%  -60% 
  PT1S              74143.6/s              129%    --  -10% 
  P1Y                 82600/s              155%   11%    -- 
 
 Legends:
   P1Y: arg_str=P1Y
   P1Y2M3DT4H5M6.7S: arg_str=P1Y2M3DT4H5M6.7S
   PT1S: arg_str=PT1S

Benchmark module startup overhead (C<< bencher -m DateTime::Format::Duration::ISO8601::Parsing --module-startup >>):

 #table2#
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | DateTime::Format::Duration::ISO8601 |       8.8 |               2.5 |                 0.00% |                39.09% |   1e-05 |      20 |
 | perl -e1 (baseline)                 |       6.3 |               0   |                39.09% |                 0.00% | 2.2e-05 |      20 |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DFD:I  perl -e1 (baseline) 
  DFD:I                113.6/s     --                 -28% 
  perl -e1 (baseline)  158.7/s    39%                   -- 
 
 Legends:
   DFD:I: mod_overhead_time=2.5 participant=DateTime::Format::Duration::ISO8601
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTime-Format-Duration-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTime-Format-Duration-ISO8601>.

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

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTime-Format-Duration-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
