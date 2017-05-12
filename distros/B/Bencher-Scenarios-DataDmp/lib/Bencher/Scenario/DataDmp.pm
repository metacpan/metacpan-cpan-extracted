package Bencher::Scenario::DataDmp;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Data::Dmp',
    modules => {
        'Data::Dmp' => {version=>'0.21'},
    },
    participants => [
        {name => 'Data::Dmp', fcall_template => 'Data::Dmp::dmp(<data>)'},
        {module => 'Data::Dump', code_template => 'my $dummy = Data::Dump::dump(<data>)'},
    ],
    datasets => [
        {
            name => 'a100-num-various',
            args => { data => [ (0, 1, -1, "+1", 1e100,
                                 -1e-100, "0123", "Inf", "-Inf", "NaN") x 10 ] },
        },
        {
            name => 'a100-num-int',
            args => { data => [ 1..100 ] },
        },
        {
            name => 'a100-str',
            args => { data => [ "a" x 100 ] },
        },
    ],
};

# ABSTRACT: Benchmark Data::Dmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataDmp - Benchmark Data::Dmp

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DataDmp (from Perl distribution Bencher-Scenarios-DataDmp), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataDmp

To run module startup overhead benchmark:

 % bencher --module-startup -m DataDmp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Dmp> 0.22

L<Data::Dump> 1.23

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Dmp (perl_code)

Function call template:

 Data::Dmp::dmp(<data>)



=item * Data::Dump (perl_code)

Code template:

 my $dummy = Data::Dump::dump(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * a100-num-various

=item * a100-num-int

=item * a100-str

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataDmp >>):

 #table1#
 +-------------+------------------+-----------+-----------+------------+---------+---------+
 | participant | dataset          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+------------------+-----------+-----------+------------+---------+---------+
 | Data::Dump  | a100-num-various |      1630 |    615    |        1   | 4.3e-07 |      20 |
 | Data::Dump  | a100-num-int     |      2800 |    350    |        1.7 | 4.8e-07 |      20 |
 | Data::Dmp   | a100-num-various |      4400 |    230    |        2.7 | 2.5e-07 |      22 |
 | Data::Dmp   | a100-num-int     |      9500 |    110    |        5.8 | 2.1e-07 |      20 |
 | Data::Dump  | a100-str         |     55000 |     18    |       34   | 5.3e-08 |      20 |
 | Data::Dmp   | a100-str         |    192000 |      5.21 |      118   | 4.9e-09 |      21 |
 +-------------+------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataDmp --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::Dump          | 0.82                         | 4.1                | 16             |      13   |                    7.6 |        1   | 5.8e-05 |      21 |
 | Data::Dmp           | 1.5                          | 4.8                | 17             |      11   |                    5.6 |        1.2 | 6.9e-05 |      23 |
 | perl -e1 (baseline) | 1.1                          | 4.6                | 18             |       5.4 |                    0   |        2.3 | 3.5e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataDmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataDmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataDmp>

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
