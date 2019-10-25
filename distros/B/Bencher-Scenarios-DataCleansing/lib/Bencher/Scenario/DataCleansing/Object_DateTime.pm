package Bencher::Scenario::DataCleansing::Object_DateTime;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use DateTime;

sub _dt { DateTime->from_epoch(epoch => 1503646935) }

our $scenario = {
    summary => 'Benchmark data cleansing (DateTime objects into scalar)',
    modules => {
        # for the Data::Rmap method
        'Acme::Damn' => {},
        'Scalar::Util' => {},
    },

    participants => [
        {
            name => 'Data::Clean-inplace',
            module => 'Data::Clean',
            code_template => 'state $cl = Data::Clean->new(DateTime => ["stringify"]); $cl->clean_in_place(<data>)',
            tags => ['inplace'],
        },
        {
            name => 'Data::Clean-clone',
            module => 'Data::Clean',
            code_template => 'state $cl = Data::Clean->new(DateTime => ["stringify"]); $cl->clone_and_clean(<data>)',
        },
        {
            name => 'Data::Rmap',
            module => 'Data::Rmap',
            code_template => 'my $data = <data>; Data::Rmap::rmap_ref(sub { if (ref $_ eq "DateTime") { "$_" } else { $_ } }, $data); $data',
            tags => ['inplace'],
        },
        {
            name => 'Data::Tersify',
            module => 'Data::Tersify',
            helper_modules => ['Data::Tersify::Plugin::DateTime'],
            code_template => 'Data::Tersify::tersify(<data>)',
        },
    ],

    datasets => [
        {
            name => 'ary1-dt1',
            summary => 'A 1-element array containing 1 DateTime object',
            args => {
                data => [_dt()],
            },
        },
        {
            name => 'ary10-dt10',
            summary => 'A 10-element array containing 10 DateTime objects',
            args => {
                data => [map {_dt()} 1..10],
            },
        },
        {
            name => 'ary100-dt100',
            summary => 'A 100-element array containing 100 DateTime objects',
            args => {
                data => [map {_dt()} 1..100],
            },
        },
        {
            name => 'ary1000-dt1000',
            summary => 'A 1000-element array containing 1000 DateTime objects',
            args => {
                data => [map {_dt()} 1..1000],
            },
        },
        {
            name => 'ary1000-dt1',
            summary => 'A 1000-element array containing 1 DateTime objects',
            args => {
                data => [(map {$_} 1..999), _dt()],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark data cleansing (DateTime objects into scalar)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCleansing::Object_DateTime - Benchmark data cleansing (DateTime objects into scalar)

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::DataCleansing::Object_DateTime (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2019-09-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCleansing::Object_DateTime

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCleansing::Object_DateTime

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Acme::Damn> 0.08

L<Data::Clean> 0.505

L<Data::Rmap> 0.65

L<Data::Tersify> 0.001

L<Scalar::Util> 1.5

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Clean-inplace (perl_code) [inplace]

Code template:

 state $cl = Data::Clean->new(DateTime => ["stringify"]); $cl->clean_in_place(<data>)



=item * Data::Clean-clone (perl_code)

Code template:

 state $cl = Data::Clean->new(DateTime => ["stringify"]); $cl->clone_and_clean(<data>)



=item * Data::Rmap (perl_code) [inplace]

Code template:

 my $data = <data>; Data::Rmap::rmap_ref(sub { if (ref $_ eq "DateTime") { "$_" } else { $_ } }, $data); $data



=item * Data::Tersify (perl_code)

Code template:

 Data::Tersify::tersify(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * ary1-dt1

A 1-element array containing 1 DateTime object

=item * ary10-dt10

A 10-element array containing 10 DateTime objects

=item * ary100-dt100

A 100-element array containing 100 DateTime objects

=item * ary1000-dt1000

A 1000-element array containing 1000 DateTime objects

=item * ary1000-dt1

A 1000-element array containing 1 DateTime objects

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Object_DateTime >>):

 #table1#
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+
 | participant         | dataset        | p_tags  | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+
 | Data::Rmap          | ary1000-dt1000 | inplace |      12.1 |    82.4   |       1    |   4e-05 |      20 |
 | Data::Clean-clone   | ary1000-dt1000 |         |      48.8 |    20.5   |       4.02 | 8.5e-06 |      21 |
 | Data::Tersify       | ary1000-dt1000 |         |      58.6 |    17.1   |       4.83 | 8.7e-06 |      21 |
 | Data::Clean-inplace | ary1000-dt1000 | inplace |      86   |    11.6   |       7.09 | 7.4e-06 |      20 |
 | Data::Rmap          | ary100-dt100   | inplace |     115   |     8.68  |       9.49 | 6.9e-06 |      20 |
 | Data::Rmap          | ary1000-dt1    | inplace |     299   |     3.35  |      24.6  | 2.9e-06 |      20 |
 | Data::Clean-clone   | ary100-dt100   |         |     510   |     2     |      42    | 2.9e-06 |      20 |
 | Data::Tersify       | ary100-dt100   |         |     627   |     1.59  |      51.7  | 1.5e-06 |      20 |
 | Data::Rmap          | ary10-dt10     | inplace |     640   |     1.6   |      53    | 2.2e-06 |      20 |
 | Data::Clean-inplace | ary100-dt100   | inplace |     970   |     1     |      80    | 2.9e-06 |      20 |
 | Data::Rmap          | ary1-dt1       | inplace |    1160   |     0.859 |      96    | 8.5e-07 |      20 |
 | Data::Tersify       | ary1000-dt1    |         |    1200   |     0.81  |     100    | 8.8e-07 |      21 |
 | Data::Clean-clone   | ary1000-dt1    |         |    2170   |     0.461 |     179    | 4.3e-07 |      20 |
 | Data::Clean-clone   | ary10-dt10     |         |    3600   |     0.28  |     300    | 1.2e-06 |      23 |
 | Data::Clean-inplace | ary1000-dt1    | inplace |    3800   |     0.26  |     320    | 2.7e-07 |      20 |
 | Data::Tersify       | ary10-dt10     |         |    4800   |     0.21  |     400    | 6.9e-07 |      20 |
 | Data::Clean-inplace | ary10-dt10     | inplace |    6700   |     0.15  |     550    | 1.1e-06 |      21 |
 | Data::Clean-clone   | ary1-dt1       |         |   10000   |     0.1   |     830    | 2.1e-07 |      21 |
 | Data::Tersify       | ary1-dt1       |         |   15000   |     0.065 |    1300    | 3.2e-07 |      20 |
 | Data::Clean-inplace | ary1-dt1       | inplace |   18000   |     0.056 |    1500    | 1.2e-07 |      26 |
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCleansing::Object_DateTime --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Data::Tersify       |      32   |                   23.3 |        1   | 3.5e-05 |      21 |
 | Data::Rmap          |      17   |                    8.3 |        2   | 4.2e-05 |      20 |
 | Data::Clean         |      14   |                    5.3 |        2.4 | 4.3e-05 |      20 |
 | perl -e1 (baseline) |       8.7 |                    0   |        3.7 |   5e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCleansing>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCleansing>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCleansing>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
