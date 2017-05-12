package Bencher::Scenario::TimeHiRes::sleep_accuracy;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Demonstrate inaccuracy of doing lots of small sleep',
    modules => {
    },
    participants => [
        {
            name => '1e-1 x1',
            fcall_template => 'Time::HiRes::sleep(1e-1)',
        },
        {
            name => '1e-2 x10',
            fcall_template => 'Time::HiRes::sleep(1e-2) for 1..10',
        },
        {
            name => '1e-3 x100',
            fcall_template => 'Time::HiRes::sleep(1e-3) for 1..100',
        },
        {
            name => '1e-4 x1000',
            fcall_template => 'Time::HiRes::sleep(1e-4) for 1..1000',
        },
        {
            name => '1e-5 x10000',
            fcall_template => 'Time::HiRes::sleep(1e-5) for 1..10000',
        },
        {
            name => '1e-6 x100000',
            fcall_template => 'Time::HiRes::sleep(1e-6) for 1..100_000',
        },
    ],
    precision => 6,
};

1;
# ABSTRACT: Demonstrate inaccuracy of doing lots of small sleep

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::TimeHiRes::sleep_accuracy - Demonstrate inaccuracy of doing lots of small sleep

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::TimeHiRes::sleep_accuracy (from Perl distribution Bencher-Scenarios-TimeHiRes), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m TimeHiRes::sleep_accuracy

To run module startup overhead benchmark:

 % bencher --module-startup -m TimeHiRes::sleep_accuracy

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Time::HiRes> 1.9733

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1e-1 x1 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-1)



=item * 1e-2 x10 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-2) for 1..10



=item * 1e-3 x100 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-3) for 1..100



=item * 1e-4 x1000 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-4) for 1..1000



=item * 1e-5 x10000 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-5) for 1..10000



=item * 1e-6 x100000 (perl_code)

Function call template:

 Time::HiRes::sleep(1e-6) for 1..100_000



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m TimeHiRes::sleep_accuracy >>):

 #table1#
 +--------------+-----------+-------+------------+----------+---------+
 | participant  | rate (/s) |  time | vs_slowest |  errors  | samples |
 +--------------+-----------+-------+------------+----------+---------+
 | 1e-6 x100000 |      0.19 | 5.4   |        1   |   0.0059 |       7 |
 | 1e-5 x10000  |      1.6  | 0.63  |        8.6 |   0.0012 |       9 |
 | 1e-4 x1000   |      6.4  | 0.16  |       35   |   0.0004 |       7 |
 | 1e-3 x100    |      9.08 | 0.11  |       49   | 6.2e-05  |       6 |
 | 1e-2 x10     |      9.89 | 0.101 |       53.4 | 4.4e-05  |       7 |
 | 1e-1 x1      |      9.99 | 0.1   |       53.9 | 1.1e-05  |       7 |
 +--------------+-----------+-------+------------+----------+---------+


Benchmark module startup overhead (C<< bencher -m TimeHiRes::sleep_accuracy --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Time::HiRes         | 1                            | 5                  | 20             |      10   |                    5.5 |        1   | 0.00012 |       7 |
 | perl -e1 (baseline) | 1.3                          | 4.6                | 20             |       4.5 |                    0   |        2.5 | 1e-05   |       6 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-TimeHiRes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-TimeHiRes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-TimeHiRes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
