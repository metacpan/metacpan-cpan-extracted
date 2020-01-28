package Bencher::Scenario::strftimeq;

our $DATE = '2019-11-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

my @localtime = (30, 9, 11, 19, 10, 119, 2, 322, 0); #"Tue Nov 19 11:09:30 2019"

our $scenario = {
    summary => 'Benchmark strftimeq() routines',
    extra_modules => [
        'DateTime',
        'Date::DayOfWeek',
    ],
    participants => [
        {
            fcall_template => 'Date::strftimeq::strftimeq(<format>, @{<time>})',
            tags => ['Date_strftimeq'],
        },
        {
            fcall_template => 'DateTimeX::strftimeq::strftimeq(<format>, @{<time>})',
            tags => ['DateTimeX_strftimeq'],
        },
        {
            name => 'strftime',
            fcall_template => 'POSIX::strftime(<format>, @{<time>})',
            tags => ['strftime'],
        },
    ],
    datasets => [
        {
            args => {format => '%Y-%m-%d', time => \@localtime},
        },
        {
            args => {format => '%Y-%m-%d%( Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 2 ? "tue":"" )q', time => \@localtime},
            include_participant_tags => ['Date_strftimeq'],
        },
        {
            args => {format => '%Y-%m-%d%( $_->day_of_week == 2 ? "tue":"" )q', time => \@localtime},
            include_participant_tags => ['DateTimeX_strftimeq'],
        },
    ],
};

1;
# ABSTRACT: Benchmark strftimeq() routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::strftimeq - Benchmark strftimeq() routines

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::strftimeq (from Perl distribution Bencher-Scenario-strftimeq), released on 2019-11-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m strftimeq

To run module startup overhead benchmark:

 % bencher --module-startup -m strftimeq

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::strftimeq> 0.001

L<DateTimeX::strftimeq> 0.004

L<POSIX> 1.65

=head1 BENCHMARK PARTICIPANTS

=over

=item * Date::strftimeq::strftimeq (perl_code) [Date_strftimeq]

Function call template:

 Date::strftimeq::strftimeq(<format>, @{<time>})



=item * DateTimeX::strftimeq::strftimeq (perl_code) [DateTimeX_strftimeq]

Function call template:

 DateTimeX::strftimeq::strftimeq(<format>, @{<time>})



=item * strftime (perl_code) [strftime]

Function call template:

 POSIX::strftime(<format>, @{<time>})



=back

=head1 BENCHMARK DATASETS

=over

=item * %Y-%m-%d

=item * %Y-%m-%d%( Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 2 ? "tue":"" )q

=item * %Y-%m-%d%( $_->day_of_week == 2 ? "tue":"" )q

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m strftimeq >>):

 #table1#
 +---------------------------------+--------------------------------------------------------------------------------------+---------------------+-----------+-----------+------------+---------+---------+
 | participant                     | dataset                                                                              | p_tags              | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+--------------------------------------------------------------------------------------+---------------------+-----------+-----------+------------+---------+---------+
 | DateTimeX::strftimeq::strftimeq | %Y-%m-%d%( $_->day_of_week == 2 ? "tue":"" )q                                        | DateTimeX_strftimeq |      9900 |     100   |       1    | 4.5e-07 |      20 |
 | Date::strftimeq::strftimeq      | %Y-%m-%d%( Date::DayOfWeek::dayofweek($_[3], $_[4]+1, $_[5]+1900) == 2 ? "tue":"" )q | Date_strftimeq      |     15000 |      68   |       1.5  | 1.3e-07 |      20 |
 | DateTimeX::strftimeq::strftimeq | %Y-%m-%d                                                                             | DateTimeX_strftimeq |     65600 |      15.2 |       6.61 | 6.2e-09 |      23 |
 | Date::strftimeq::strftimeq      | %Y-%m-%d                                                                             | Date_strftimeq      |     66000 |      15   |       6.6  |   2e-08 |      20 |
 | strftime                        | %Y-%m-%d                                                                             | strftime            |    540000 |       1.8 |      55    | 3.3e-09 |      20 |
 +---------------------------------+--------------------------------------------------------------------------------------+---------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m strftimeq --module-startup >>):

 #table2#
 +----------------------+-----------+------------------------+------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------+-----------+------------------------+------------+---------+---------+
 | POSIX                |        11 |                      8 |          1 | 3.3e-05 |      20 |
 | Date::strftimeq      |        11 |                      8 |          1 | 5.9e-05 |      21 |
 | DateTimeX::strftimeq |        11 |                      8 |          1 | 2.3e-05 |      20 |
 | perl -e1 (baseline)  |         3 |                      0 |          4 | 3.9e-05 |      21 |
 +----------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-strftimeq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-strftimeq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-strftimeq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
