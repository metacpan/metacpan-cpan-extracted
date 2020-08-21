package Bencher::Scenario::FormattingISO8601DateTime;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-21'; # DATE
our $DIST = 'Bencher-Scenario-FormattingISO8601DateTime'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Modules that format DateTime as ISO8601',
    participants => [
        {
            name => 'DFI:format_datetime',
            helper_modules => ['DateTime'],
            fcall_template => 'DateTime::Format::ISO8601->format_datetime(DateTime->now)',
        },
        {
            name => 'DFIF:format_datetime',
            module => 'DateTime::Format::ISO8601::Format',
            helper_modules => ['DateTime'],
            code_template => 'DateTime::Format::ISO8601::Format->new->format_datetime(DateTime->now)',
        },
        {
            name => 'DFIF:format_date',
            module => 'DateTime::Format::ISO8601::Format',
            helper_modules => ['DateTime'],
            code_template => 'DateTime::Format::ISO8601::Format->new->format_date(DateTime->now)',
        },
        {
            name => 'DFIF:format_time',
            module => 'DateTime::Format::ISO8601::Format',
            helper_modules => ['DateTime'],
            code_template => 'DateTime::Format::ISO8601::Format->new->format_time(DateTime->now)',
        },
    ],
};

1;
# ABSTRACT: Modules that format DateTime as ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FormattingISO8601DateTime - Modules that format DateTime as ISO8601

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::FormattingISO8601DateTime (from Perl distribution Bencher-Scenario-FormattingISO8601DateTime), released on 2020-08-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FormattingISO8601DateTime

To run module startup overhead benchmark:

 % bencher --module-startup -m FormattingISO8601DateTime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::ISO8601> 0.14

L<DateTime::Format::ISO8601::Format> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * DFI:format_datetime (perl_code)

Function call template:

 DateTime::Format::ISO8601->format_datetime(DateTime->now)



=item * DFIF:format_datetime (perl_code)

Code template:

 DateTime::Format::ISO8601::Format->new->format_datetime(DateTime->now)



=item * DFIF:format_date (perl_code)

Code template:

 DateTime::Format::ISO8601::Format->new->format_date(DateTime->now)



=item * DFIF:format_time (perl_code)

Code template:

 DateTime::Format::ISO8601::Format->new->format_time(DateTime->now)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with default options (C<< bencher -m FormattingISO8601DateTime >>):

 #table1#
 {dataset=>undef}
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | DFI:format_datetime  |      9600 |     100   |                 0.00% |               350.41% | 2.1e-07 |      20 |
 | DFIF:format_datetime |     37000 |      27   |               286.21% |                16.62% | 9.6e-08 |      31 |
 | DFIF:format_time     |     40700 |      24.6 |               323.35% |                 6.39% | 6.5e-09 |      21 |
 | DFIF:format_date     |     43000 |      23   |               350.41% |                 0.00% | 2.7e-08 |      20 |
 +----------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m FormattingISO8601DateTime --module-startup >>):

 #table2#
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | DateTime::Format::ISO8601         |     130   |             126.9 |                 0.00% |              4024.46% |   0.00031 |      20 |
 | DateTime::Format::ISO8601::Format |       7   |               3.9 |              1590.35% |               144.00% |   0.00011 |      21 |
 | perl -e1 (baseline)               |       3.1 |               0   |              4024.46% |                 0.00% | 2.3e-05   |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-FormattingISO8601DateTime>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-FormattingISO8601DateTime>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-FormattingISO8601DateTime>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
