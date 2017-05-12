package Bencher::Scenario::Example::NameAndSeq;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Participant/dataset with name that is also a sequence number',
    participants => [
        {name => 1, fcall_template => 'Time::HiRes::usleep(1*<delay>)'},
        {name => 3, fcall_template => 'Time::HiRes::usleep(3*<delay>)'},
    ],
    datasets => [
        {name => 1, args => {delay=>1}},
        {name => 3, args => {delay=>3}},
    ],
};

1;
# ABSTRACT: Participant/dataset with name that is also a sequence number

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::NameAndSeq - Participant/dataset with name that is also a sequence number

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Example::NameAndSeq (from Perl distribution Bencher-Scenarios-Examples), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Example::NameAndSeq

To run module startup overhead benchmark:

 % bencher --module-startup -m Example::NameAndSeq

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Time::HiRes> 1.9733

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1 (perl_code)

Function call template:

 Time::HiRes::usleep(1*<delay>)



=item * 3 (perl_code)

Function call template:

 Time::HiRes::usleep(3*<delay>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 3

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Example::NameAndSeq >>):

 #table1#
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | participant | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+---------+-----------+-----------+------------+---------+---------+
 | 3           | 3       |   16093.5 |   62.1368 |    1       | 1.1e-11 |      20 |
 | 1           | 3       |   17861.8 |   55.9854 |    1.10987 | 3.4e-11 |      20 |
 | 3           | 1       |   17873.1 |   55.95   |    1.11058 |   0     |      20 |
 | 1           | 1       |   18000   |   54      |    1.1     | 1.1e-07 |      20 |
 +-------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m Example::NameAndSeq --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors  | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+
 | Time::HiRes         | 1.3                          | 4.6                | 20             |        23 |                      3 |          1 | 9.7e-05  |      21 |
 | perl -e1 (baseline) | 1                            | 5                  | 20             |        20 |                      0 |          1 |   0.0002 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Examples>

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
