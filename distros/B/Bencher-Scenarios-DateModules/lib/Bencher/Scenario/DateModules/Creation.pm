package Bencher::Scenario::DateModules::Creation;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark date creation',
    participants => [
        {
            name => 'DateTime->new(ymd)',
            fcall_template => 'DateTime->new(year=>2016, month=>4, day=>19)',
        },
        {
            name => 'DateTime->now',
            fcall_template => 'DateTime->now',
        },

        {
            name => 'Time::Moment->new(ymd)',
            fcall_template => 'Time::Moment->new(year=>2016, month=>4, day=>19)',
        },
        {
            name => 'Time::Moment->now',
            fcall_template => 'Time::Moment->now',
        },

        {
            name => 'Time::Local::timelocal',
            fcall_template => 'Time::Local::timelocal(0, 0, 0, 19, 4-1, 2016-1900)',
        },

        {
            name => 'Time::Piece::localtime',
            fcall_template => 'Time::Piece::localtime()',
        },
    ],
    include_result_size => 1,
};

1;
# ABSTRACT: Benchmark date creation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateModules::Creation - Benchmark date creation

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DateModules::Creation (from Perl distribution Bencher-Scenarios-DateModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateModules::Creation

To run module startup overhead benchmark:

 % bencher --module-startup -m DateModules::Creation

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime> 1.36

L<Time::Moment> 0.38

L<Time::Local> 1.2300

L<Time::Piece> 1.31

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime->new(ymd) (perl_code)

Function call template:

 DateTime->new(year=>2016, month=>4, day=>19)



=item * DateTime->now (perl_code)

Function call template:

 DateTime->now



=item * Time::Moment->new(ymd) (perl_code)

Function call template:

 Time::Moment->new(year=>2016, month=>4, day=>19)



=item * Time::Moment->now (perl_code)

Function call template:

 Time::Moment->now



=item * Time::Local::timelocal (perl_code)

Function call template:

 Time::Local::timelocal(0, 0, 0, 19, 4-1, 2016-1900)



=item * Time::Piece::localtime (perl_code)

Function call template:

 Time::Piece::localtime()



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DateModules::Creation >>):

 #table1#
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | DateTime->new(ymd)     |     27000 |     37    |        1   | 5.3e-08 |      20 |
 | DateTime->now          |     27000 |     36    |        1   | 5.3e-08 |      20 |
 | Time::Local::timelocal |     97000 |     10    |        3.6 |   7e-08 |      26 |
 | Time::Piece::localtime |    190000 |      5.1  |        7.2 | 6.5e-09 |      21 |
 | Time::Moment->now      |    670000 |      1.5  |       25   | 1.7e-09 |      20 |
 | Time::Moment->new(ymd) |   2900000 |      0.34 |      110   | 4.3e-10 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateModules::Creation --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime            | 11                           | 15                 | 44             |      61   |                   56.1 |        1   |   0.00015 |      20 |
 | Time::Piece         | 1.5                          | 5.1                | 17             |      18   |                   13.1 |        3.4 | 4.4e-05   |      26 |
 | Time::Local         | 1.4                          | 4.7                | 19             |      13   |                    8.1 |        4.7 | 8.4e-05   |      20 |
 | Time::Moment        | 1.4                          | 4.7                | 19             |      11   |                    6.1 |        5.6 | 3.7e-05   |      21 |
 | perl -e1 (baseline) | 11                           | 15                 | 44             |       4.9 |                    0   |       12   | 1.5e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Time::Moment is the fastest. It also produces a very compact object (second only
to Time::Local, which produces ints). In comparison, DateTime is relatively
crazy big.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateModules>

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
