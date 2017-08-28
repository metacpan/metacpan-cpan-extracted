package Bencher::Scenario::DateModules::Storage;

our $DATE = '2017-08-27'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure memory storage usage of 1k date/duration objects/structures',
    precision => 1,
    participants => [
        {
            name => 'DateTime',
            module => 'DateTime',
            code_template => '[map {DateTime->new(year=>2016, month=>4, day=>19)} 1..1_000]',
        },
        {
            name => 'DateTime::Tiny',
            module => 'DateTime::Tiny',
            code_template => '[map {DateTime::Tiny->new(year=>2016, month=>4, day=>19)} 1..1_000]',
        },
        {
            name => 'Time::Moment',
            module => 'Time::Moment',
            code_template => '[map {Time::Moment->new(year=>2016, month=>4, day=>19)} 1..1_000]',
        },
        {
            name => 'Time::Local',
            module => 'Time::Local',
            code_template => '[map {Time::Local::timelocal(0, 0, 0, 19, 4-1, 2016-1900)} 1..1_000]',
        },
        {
            name => 'Time::Piece',
            module => 'Time::Piece',
            code_template => '[map {Time::Piece::localtime()} 1..1_000]',
        },

        {
            name => 'DateTime::Duration',
            module => 'DateTime::Duration',
            code_template => '[map {DateTime::Duration->new(months=>1, days=>2, minutes=>3, seconds=>4, nanoseconds=>5)} 1..1_000]',
        },

    ],

    with_result_size => 1,
};

1;
# ABSTRACT: Measure memory storage usage of 1k date/duration objects/structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateModules::Storage - Measure memory storage usage of 1k date/duration objects/structures

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DateModules::Storage (from Perl distribution Bencher-Scenarios-DateModules), released on 2017-08-27.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateModules::Storage

To run module startup overhead benchmark:

 % bencher --module-startup -m DateModules::Storage

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime> 1.36

L<DateTime::Tiny> 1.06

L<Time::Moment> 0.38

L<Time::Local> 1.2300

L<Time::Piece> 1.31

L<DateTime::Duration> 1.36

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime (perl_code)

Code template:

 [map {DateTime->new(year=>2016, month=>4, day=>19)} 1..1_000]



=item * DateTime::Tiny (perl_code)

Code template:

 [map {DateTime::Tiny->new(year=>2016, month=>4, day=>19)} 1..1_000]



=item * Time::Moment (perl_code)

Code template:

 [map {Time::Moment->new(year=>2016, month=>4, day=>19)} 1..1_000]



=item * Time::Local (perl_code)

Code template:

 [map {Time::Local::timelocal(0, 0, 0, 19, 4-1, 2016-1900)} 1..1_000]



=item * Time::Piece (perl_code)

Code template:

 [map {Time::Piece::localtime()} 1..1_000]



=item * DateTime::Duration (perl_code)

Code template:

 [map {DateTime::Duration->new(months=>1, days=>2, minutes=>3, seconds=>4, nanoseconds=>5)} 1..1_000]



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DateModules::Storage >>):

 #table1#
 +--------------------+-------------+-----------+-------------+------------------+---------+---------+
 | participant        | rate (/s)   | time (ms) | vs_slowest  | result_size (MB) |  errors | samples |
 +--------------------+-------------+-----------+-------------+------------------+---------+---------+
 | DateTime           |   27.126052 | 36.86493  |   1         |       1.4849157  | 5.2e-11 |       1 |
 | DateTime::Duration |   54.215377 | 18.444952 |   1.9986461 |       0.50765514 | 4.8e-11 |       1 |
 | Time::Local        |  109.661    |  9.11897  |   4.04266   |       0.0610962  |   0     |       1 |
 | Time::Piece        |  218.912    |  4.56804  |   8.07018   |       0.274719   |   0     |       1 |
 | DateTime::Tiny     | 1508.35     |  0.662976 |  55.6052    |       0.282457   |   0     |       1 |
 | Time::Moment       | 2724.06     |  0.367099 | 100.422     |       0.116409   |   0     |       1 |
 +--------------------+-------------+-----------+-------------+------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateModules::Storage --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+------------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms)  | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+------------+------------------------+------------+---------+---------+
 | DateTime::Duration  | 0.820312                     | 4.09375            | 16.0039        | 91.7918    |             86.862794  |  1         |   0     |       1 |
 | DateTime            | 1.04688                      | 4.40625            | 16.1367        | 72.2122    |             67.283194  |  1.27114   |   0     |       1 |
 | Time::Piece         | 11.0039                      | 14.875             | 44.3125        | 16.9727    |             12.043694  |  5.4082    |   0     |       1 |
 | Time::Local         | 2.28125                      | 5.886719           | 19.44922       | 12.02887   |              7.099864  |  7.630959  | 1.1e-09 |       1 |
 | Time::Moment        | 1.5234375                    | 5.1289062          | 16.652344      | 10.576904  |              5.647898  |  8.6785138 | 5.2e-11 |       1 |
 | DateTime::Tiny      | 1.3554688                    | 4.75               | 18.601562      |  8.7360744 |              3.8070684 | 10.507215  | 5.2e-11 |       1 |
 | perl -e1 (baseline) | 11.09375                     | 14.95312           | 44.46875       |  4.929006  |              0         | 18.62278   | 5.2e-11 |       1 |
 +---------------------+------------------------------+--------------------+----------------+------------+------------------------+------------+---------+---------+


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
