package Bencher::Scenario::DateTimeFormatDurationISO8601::Formatting;

our $DATE = '2018-07-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use DateTime::Duration;

my $dur1 = DateTime::Duration->new(years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6, nanoseconds => 700_000_000);

our $scenario = {
    summary => 'Benchmark formatting with DateTime::Format::Duration::ISO8601',
    participants => [
        {
            name => 'format_duration',
            fcall_template => 'DateTime::Format::Duration::ISO8601->new->format_duration(<dur>)',
        },
    ],
    datasets => [
        {args => {'dur@' => [$dur1]}},
    ],
};

1;
# ABSTRACT: Benchmark formatting with DateTime::Format::Duration::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatDurationISO8601::Formatting - Benchmark formatting with DateTime::Format::Duration::ISO8601

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatDurationISO8601::Formatting (from Perl distribution Bencher-Scenarios-DateTimeFormatDurationISO8601), released on 2018-07-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatDurationISO8601::Formatting

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeFormatDurationISO8601::Formatting

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Duration::ISO8601> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * format_duration (perl_code)

Function call template:

 DateTime::Format::Duration::ISO8601->new->format_duration(<dur>)



=back

=head1 BENCHMARK DATASETS

=over

=item * [bless({days=>3,end_of_month=>"wrap",minutes=>245,months=>14,nanoseconds=>700000000,seconds=>6},"DateTime::Duration")]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatDurationISO8601::Formatting >>):

 #table1#
 +-----------------+------------------------------------------------------------------------------------------------------------------------+------------------------------------+---------+--------+------+-----------+-----------+------------+---------+---------+
 | participant     | dataset                                                                                                                | arg_dur                            | ds_tags | p_tags | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------+------------------------------------------------------------------------------------------------------------------------+------------------------------------+---------+--------+------+-----------+-----------+------------+---------+---------+
 | format_duration | [bless({days=>3,end_of_month=>"wrap",minutes=>245,months=>14,nanoseconds=>700000000,seconds=>6},"DateTime::Duration")] | DateTime::Duration=HASH(0x7dc58a8) |         |        | perl |     43318 |    23.085 |          1 | 5.3e-11 |      20 |
 +-----------------+------------------------------------------------------------------------------------------------------------------------+------------------------------------+---------+--------+------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeFormatDurationISO8601::Formatting --module-startup >>):

 #table2#
 +-------------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------------+-----------+------------------------+------------+---------+---------+
 | DateTime::Format::Duration::ISO8601 |       8.2 |                    2.9 |        1   | 8.7e-06 |      20 |
 | perl -e1 (baseline)                 |       5.3 |                    0   |        1.6 | 2.9e-05 |      21 |
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
