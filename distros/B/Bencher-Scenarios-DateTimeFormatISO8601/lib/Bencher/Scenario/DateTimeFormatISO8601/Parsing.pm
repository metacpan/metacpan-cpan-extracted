package Bencher::Scenario::DateTimeFormatISO8601::Parsing;

our $DATE = '2018-07-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::DateTimeFormatISO8601::Parsing - Benchmark parsing with DateTime::Format::ISO8601

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatISO8601::Parsing (from Perl distribution Bencher-Scenarios-DateTimeFormatISO8601), released on 2018-07-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatISO8601::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeFormatISO8601::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::ISO8601> 0.08

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatISO8601::Parsing >>):

 #table1#
 +---------------------------+-----------+-----------+------------+---------+---------+
 | arg_str                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+-----------+-----------+------------+---------+---------+
 | 2000-12-31T12:34:56+07:00 |     10000 |        99 |        1   | 4.5e-07 |      20 |
 | 2000-12-31T12:34:56Z      |     16000 |        63 |        1.6 | 1.1e-07 |      20 |
 | 2000-12-31T12:34:56       |     16000 |        61 |        1.6 |   2e-07 |      29 |
 | 2000-12-31                |     18000 |        56 |        1.8 | 4.3e-07 |      20 |
 +---------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeFormatISO8601::Parsing --module-startup >>):

 #table2#
 +---------------------------+-----------+------------------------+------------+-----------+---------+
 | participant               | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::ISO8601 |     180   |                  173.7 |          1 |   0.00085 |      20 |
 | perl -e1 (baseline)       |       6.3 |                    0   |         29 | 4.6e-05   |      20 |
 +---------------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatISO8601>

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
