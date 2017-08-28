package Bencher::Scenario::DataCleansing::Object_DateTime;

our $DATE = '2017-08-25'; # DATE
our $VERSION = '0.004'; # VERSION

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
        # specify minimum version
        'Data::Clean' => {version=>'0.48'},
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

This document describes version 0.004 of Bencher::Scenario::DataCleansing::Object_DateTime (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2017-08-25.

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

L<Data::Clean> 0.49

L<Data::Rmap> 0.64

L<Data::Tersify> 0.001

L<Scalar::Util> 1.45

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Object_DateTime >>):

 #table1#
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+
 | participant         | dataset        | p_tags  | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+
 | Data::Rmap          | ary1000-dt1000 | inplace |      12.2 |    82     |       1    | 7.7e-05 |      20 |
 | Data::Tersify       | ary1000-dt1000 |         |      60   |    17     |       4.9  | 6.6e-05 |      20 |
 | Data::Clean-clone   | ary1000-dt1000 |         |      67   |    15     |       5.5  | 3.8e-05 |      20 |
 | Data::Clean-inplace | ary1000-dt1000 | inplace |      92.3 |    10.8   |       7.57 | 7.4e-06 |      20 |
 | Data::Rmap          | ary100-dt100   | inplace |     120   |     8.7   |       9.4  | 2.5e-05 |      30 |
 | Data::Rmap          | ary1000-dt1    | inplace |     270   |     3.7   |      22    | 9.9e-06 |      20 |
 | Data::Tersify       | ary100-dt100   |         |     628   |     1.59  |      51.5  | 1.4e-06 |      20 |
 | Data::Rmap          | ary10-dt10     | inplace |     636   |     1.57  |      52.2  | 9.1e-07 |      20 |
 | Data::Clean-clone   | ary100-dt100   |         |     802   |     1.25  |      65.8  | 6.9e-07 |      20 |
 | Data::Clean-inplace | ary100-dt100   | inplace |    1050   |     0.956 |      85.8  | 4.3e-07 |      20 |
 | Data::Rmap          | ary1-dt1       | inplace |    1160   |     0.863 |      95    | 4.3e-07 |      20 |
 | Data::Tersify       | ary1000-dt1    |         |    1250   |     0.803 |     102    | 4.3e-07 |      20 |
 | Data::Clean-clone   | ary1000-dt1    |         |    3160   |     0.316 |     259    | 2.1e-07 |      20 |
 | Data::Clean-inplace | ary1000-dt1    | inplace |    3780   |     0.265 |     310    | 2.1e-07 |      21 |
 | Data::Tersify       | ary10-dt10     |         |    4500   |     0.22  |     370    | 7.3e-07 |      31 |
 | Data::Clean-clone   | ary10-dt10     |         |    5900   |     0.17  |     480    |   2e-07 |      22 |
 | Data::Clean-inplace | ary10-dt10     | inplace |    6800   |     0.15  |     560    |   2e-07 |      23 |
 | Data::Tersify       | ary1-dt1       |         |   14000   |     0.07  |    1200    |   2e-07 |      22 |
 | Data::Clean-clone   | ary1-dt1       |         |   17000   |     0.059 |    1400    | 1.1e-07 |      20 |
 | Data::Clean-inplace | ary1-dt1       | inplace |   18000   |     0.056 |    1500    | 5.5e-07 |      21 |
 +---------------------+----------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCleansing::Object_DateTime --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::Tersify       | 12                           | 16                 | 46             |      33   |                   25.6 |        1   | 3.7e-05 |      20 |
 | Data::Rmap          | 1.4                          | 4.9                | 19             |      16   |                    8.6 |        2   | 6.3e-05 |      20 |
 | Data::Clean         | 1.1                          | 4.6                | 16             |      13   |                    5.6 |        2.5 | 7.5e-05 |      20 |
 | perl -e1 (baseline) | 1.1                          | 4.6                | 16             |       7.4 |                    0   |        4.4 | 2.2e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
