package Bencher::Scenario::DateModules::Overhead;

our $DATE = '2017-08-27'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Overhead of date/duration modules',
    module_startup => 1,
    participants => [
        {module => 'DateTime'},
        {module => 'DateTime::Duration'},
        {module => 'DateTime::Tiny'},
        {module => 'Time::Moment'},
        {module => 'Time::Local'},
        {module => 'Time::Piece'},
    ],
};

1;
# ABSTRACT: Overhead of date/duration modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateModules::Overhead - Overhead of date/duration modules

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DateModules::Overhead (from Perl distribution Bencher-Scenarios-DateModules), released on 2017-08-27.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateModules::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime> 1.36

L<DateTime::Duration> 1.36

L<DateTime::Tiny> 1.06

L<Time::Moment> 0.38

L<Time::Local> 1.2300

L<Time::Piece> 1.31

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime (perl_code)

L<DateTime>



=item * DateTime::Duration (perl_code)

L<DateTime::Duration>



=item * DateTime::Tiny (perl_code)

L<DateTime::Tiny>



=item * Time::Moment (perl_code)

L<Time::Moment>



=item * Time::Local (perl_code)

L<Time::Local>



=item * Time::Piece (perl_code)

L<Time::Piece>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DateModules::Overhead >>):

 #table1#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Duration  | 1                            | 4.5                | 16             |      65   |                   60.7 |        1   |   0.00053 |      20 |
 | DateTime            | 11                           | 15                 | 44             |      60   |                   55.7 |        1.1 |   0.00016 |      20 |
 | Time::Piece         | 0.82                         | 4.1                | 16             |      17   |                   12.7 |        3.8 | 2.1e-05   |      21 |
 | Time::Moment        | 2                            | 5                  | 20             |      10   |                    5.7 |        5   |   0.00016 |      20 |
 | Time::Local         | 2.3                          | 5.9                | 19             |      12   |                    7.7 |        5.3 | 2.7e-05   |      20 |
 | DateTime::Tiny      | 1.4                          | 4.8                | 19             |       8.2 |                    3.9 |        7.9 | 2.5e-05   |      20 |
 | perl -e1 (baseline) | 11                           | 15                 | 44             |       4.3 |                    0   |       15   | 6.2e-06   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

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
