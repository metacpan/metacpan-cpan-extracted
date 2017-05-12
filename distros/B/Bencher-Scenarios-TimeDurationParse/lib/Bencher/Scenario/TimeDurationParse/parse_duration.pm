package Bencher::Scenario::TimeDurationParse::parse_duration;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark parse_duration()',
    participants => [
        {name => 'TDP' , fcall_template => 'Time::Duration::Parse::parse_duration(<str>)'},
        {name => 'TDPA', fcall_template => 'Time::Duration::Parse::AsHash::parse_duration(<str>)'},
    ],
    datasets => [
        {args => {'str@' => ['3h', '3 hours 4 minutes']}},
    ],
};

1;
# ABSTRACT: Benchmark parse_duration()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TimeDurationParse::parse_duration - Benchmark parse_duration()

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::TimeDurationParse::parse_duration (from Perl distribution Bencher-Scenarios-TimeDurationParse), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TimeDurationParse::parse_duration

To run module startup overhead benchmark:

 % bencher --module-startup -m TimeDurationParse::parse_duration

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Time::Duration::Parse> 0.13

L<Time::Duration::Parse::AsHash> 0.10.6

=head1 BENCHMARK PARTICIPANTS

=over

=item * TDP (perl_code)

Function call template:

 Time::Duration::Parse::parse_duration(<str>)



=item * TDPA (perl_code)

Function call template:

 Time::Duration::Parse::AsHash::parse_duration(<str>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ["3h","3 hours 4 minutes"]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TimeDurationParse::parse_duration >>):

 #table1#
 +-------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant | arg_str           | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-------------------+-----------+-----------+------------+---------+---------+
 | TDPA        | 3 hours 4 minutes |    210000 |      4.9  |       1    | 6.7e-09 |      20 |
 | TDP         | 3 hours 4 minutes |    261000 |      3.84 |       1.27 | 1.7e-09 |      20 |
 | TDPA        | 3h                |    377000 |      2.65 |       1.83 | 8.3e-10 |      20 |
 | TDP         | 3h                |    470000 |      2.1  |       2.3  | 2.5e-09 |      20 |
 +-------------+-------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m TimeDurationParse::parse_duration --module-startup >>):

 #table2#
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                   | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Time::Duration::Parse         | 0.98                         | 4.4                | 16             |      10   |                    5.7 |        1   | 8.1e-05 |      21 |
 | Time::Duration::Parse::AsHash | 0.82                         | 4.1                | 16             |       5.8 |                    1.5 |        1.8 | 3.6e-05 |      21 |
 | perl -e1 (baseline)           | 1.3                          | 4.7                | 16             |       4.3 |                    0   |        2.4 |   8e-06 |      20 |
 +-------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<Time::Duration::Parse::AsHash> is expected to be slightly slower since it
needs to build and return a hashref instead of a single number.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TimeDurationParse>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TimeDurationParse>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TimeDurationParse>

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
