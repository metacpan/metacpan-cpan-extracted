package Bencher::Scenario::DateTime::Format::ISO8601::Parsing;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-DateTime-Format-ISO8601'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark parsing with DateTime::Format::ISO8601',
    participants => [
        {
            name => 'parse_datetime',
            module => 'DateTime::Format::ISO8601',
            code_template => 'DateTime::Format::ISO8601->parse_datetime(<str>)',
            tags => ['parse_datetime'],
        },
        {
            name => 'parse_time',
            module => 'DateTime::Format::ISO8601',
            code_template => 'DateTime::Format::ISO8601->parse_time(<str>)',
            tags => ['parse_time'],
        },
    ],
    datasets => [
        {include_participant_tags => ['parse_datetime'], args => {'str@' => ['2000-12-31', '2000-12-31T12:34:56', '2000-12-31T12:34:56Z', '2000-12-31T12:34:56+07:00']}},
        #{include_participant_tags => ['parse_time'    ], args => {'str@' => [
            #'12:34:56',
            #'12:34:56Z',
            #'12:34:56+07:00',
        #]}},
    ],
};

1;
# ABSTRACT: Benchmark parsing with DateTime::Format::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTime::Format::ISO8601::Parsing - Benchmark parsing with DateTime::Format::ISO8601

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DateTime::Format::ISO8601::Parsing (from Perl distribution Bencher-Scenarios-DateTime-Format-ISO8601), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTime::Format::ISO8601::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTime::Format::ISO8601::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::ISO8601> 0.16

=head1 BENCHMARK PARTICIPANTS

=over

=item * parse_datetime (perl_code) [parse_datetime]

Code template:

 DateTime::Format::ISO8601->parse_datetime(<str>)



=item * parse_time (perl_code) [parse_time]

Code template:

 DateTime::Format::ISO8601->parse_time(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ["2000-12-31","2000-12-31T12:34:56","2000-12-31T12:34:56Z","2000-12-31T12:34:56+07:00"]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m DateTime::Format::ISO8601::Parsing >>):

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | arg_str                   | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | 2000-12-31T12:34:56+07:00 |     13000 |        78 |                 0.00% |                90.22% | 1.3e-07 |      20 |
 | 2000-12-31T12:34:56Z      |     22000 |        46 |                67.52% |                13.55% | 5.2e-08 |      21 |
 | 2000-12-31T12:34:56       |     22000 |        45 |                72.81% |                10.08% |   5e-08 |      23 |
 | 2000-12-31                |     24000 |        41 |                90.22% |                 0.00% | 8.9e-08 |      29 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                Rate  2000-12-31T12:34:56+07:00  2000-12-31T12:34:56Z  2000-12-31T12:34:56  2000-12-31 
  2000-12-31T12:34:56+07:00  13000/s                         --                  -41%                 -42%        -47% 
  2000-12-31T12:34:56Z       22000/s                        69%                    --                  -2%        -10% 
  2000-12-31T12:34:56        22000/s                        73%                    2%                   --         -8% 
  2000-12-31                 24000/s                        90%                   12%                   9%          -- 
 
 Legends:
   2000-12-31: arg_str=2000-12-31
   2000-12-31T12:34:56: arg_str=2000-12-31T12:34:56
   2000-12-31T12:34:56+07:00: arg_str=2000-12-31T12:34:56+07:00
   2000-12-31T12:34:56Z: arg_str=2000-12-31T12:34:56Z

Benchmark module startup overhead (C<< bencher -m DateTime::Format::ISO8601::Parsing --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | DateTime::Format::ISO8601 |     170   |             163.7 |                 0.00% |              2569.12% |   0.00023 |      20 |
 | perl -e1 (baseline)       |       6.3 |               0   |              2569.12% |                 0.00% | 2.3e-05   |      22 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate   DF:I  perl -e1 (baseline) 
  DF:I                   5.9/s     --                 -96% 
  perl -e1 (baseline)  158.7/s  2598%                   -- 
 
 Legends:
   DF:I: mod_overhead_time=163.7 participant=DateTime::Format::ISO8601
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTime-Format-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTime-Format-ISO8601>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTime-Format-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
