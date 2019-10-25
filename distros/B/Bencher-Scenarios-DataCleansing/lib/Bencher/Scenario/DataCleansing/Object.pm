package Bencher::Scenario::DataCleansing::Object;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark data cleansing (unblessing object)',
    modules => {
        # for the Data::Rmap method
        'Acme::Damn' => {},
        'Scalar::Util' => {},
    },
    participants => [
        {
            name => 'Data::Clean-inplace',
            module => 'Data::Clean',
            code_template => 'state $cl = Data::Clean->new(-obj => ["unbless"]); $cl->clean_in_place(<data>)',
            tags => ['inplace'],
        },
        {
            name => 'Data::Clean-clone',
            module => 'Data::Clean',
            code_template => 'state $cl = Data::Clean->new(-obj => ["unbless"]); $cl->clone_and_clean(<data>)',
        },
        {
            name => 'JSON::PP',
            module => 'JSON::PP',
            code_template => 'state $json = JSON::PP->new->allow_blessed(1)->convert_blessed(1); $json->decode($json->encode(<data>))',
        },
        {
            name => 'Data::Rmap',
            module => 'Data::Rmap',
            code_template => 'my $data = <data>; Data::Rmap::rmap_ref(sub { Acme::Damn::damn($_) if Scalar::Util::blessed($_) }, $data); $data',
            tags => ['inplace'],
        },
    ],
    datasets => [
        {
            name => 'ary100-u1-obj',
            summary => 'A 100-element array containing 1 "unclean" data: object',
            args => {
                data => do {
                    my $data = [0..99];
                    $data->[49] = bless [], "Foo";
                    $data;
                },
            },
        },
        {
            name => 'ary100-u100-obj',
            summary => 'A 100-element array containing 100 "unclean" data: object',
            args => {
                data => do {
                    my $data = [map {bless [], "Foo"} 0..99];
                    $data;
                },
            },
        },
        {
            name => 'ary10k-u1-obj',
            summary => 'A 10k-element array containing 1 "unclean" data: object',
            args => {
                data => do {
                    my $data = [0..999];
                    $data->[499] = bless [], "Foo";
                    $data;
                },
            },
        },
        {
            name => 'ary10k-u10k-obj',
            summary => 'A 10k-element array containing 10k "unclean" data: object',
            args => {
                data => do {
                    my $data = [map {bless [], "Foo"} 0..999];
                    $data;
                },
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark data cleansing (unblessing object)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCleansing::Object - Benchmark data cleansing (unblessing object)

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::DataCleansing::Object (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2019-09-11.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCleansing::Object

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCleansing::Object

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Acme::Damn> 0.08

L<Data::Clean> 0.505

L<Data::Rmap> 0.65

L<JSON::PP> 2.27400_02

L<Scalar::Util> 1.5

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Clean-inplace (perl_code) [inplace]

Code template:

 state $cl = Data::Clean->new(-obj => ["unbless"]); $cl->clean_in_place(<data>)



=item * Data::Clean-clone (perl_code)

Code template:

 state $cl = Data::Clean->new(-obj => ["unbless"]); $cl->clone_and_clean(<data>)



=item * JSON::PP (perl_code)

Code template:

 state $json = JSON::PP->new->allow_blessed(1)->convert_blessed(1); $json->decode($json->encode(<data>))



=item * Data::Rmap (perl_code) [inplace]

Code template:

 my $data = <data>; Data::Rmap::rmap_ref(sub { Acme::Damn::damn($_) if Scalar::Util::blessed($_) }, $data); $data



=back

=head1 BENCHMARK DATASETS

=over

=item * ary100-u1-obj

A 100-element array containing 1 "unclean" data: object

=item * ary100-u100-obj

A 100-element array containing 100 "unclean" data: object

=item * ary10k-u1-obj

A 10k-element array containing 1 "unclean" data: object

=item * ary10k-u10k-obj

A 10k-element array containing 10k "unclean" data: object

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Object >>):

 #table1#
 +---------------------+-----------------+---------+-----------+-----------+------------+---------+---------+
 | participant         | dataset         | p_tags  | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------------+---------+-----------+-----------+------------+---------+---------+
 | JSON::PP            | ary10k-u1-obj   |         |       156 |     6.39  |       1    | 2.5e-06 |      23 |
 | Data::Clean-clone   | ary10k-u10k-obj |         |       200 |     5     |       1    | 5.8e-05 |      20 |
 | Data::Rmap          | ary10k-u10k-obj | inplace |       216 |     4.62  |       1.38 | 4.4e-06 |      20 |
 | JSON::PP            | ary10k-u10k-obj |         |       227 |     4.41  |       1.45 | 1.3e-06 |      22 |
 | Data::Rmap          | ary10k-u1-obj   | inplace |       419 |     2.39  |       2.68 | 2.3e-06 |      20 |
 | Data::Clean-inplace | ary10k-u10k-obj | inplace |       976 |     1.02  |       6.24 | 2.7e-07 |      20 |
 | JSON::PP            | ary100-u1-obj   |         |      1500 |     0.67  |       9.5  | 1.3e-06 |      20 |
 | Data::Clean-clone   | ary100-u100-obj |         |      1900 |     0.52  |      12    | 6.1e-07 |      22 |
 | JSON::PP            | ary100-u100-obj |         |      2000 |     0.51  |      12    | 6.4e-07 |      20 |
 | Data::Rmap          | ary100-u100-obj | inplace |      2150 |     0.465 |      13.8  | 4.3e-07 |      20 |
 | Data::Clean-clone   | ary10k-u1-obj   |         |      2470 |     0.405 |      15.8  | 3.7e-07 |      26 |
 | Data::Rmap          | ary100-u1-obj   | inplace |      3990 |     0.25  |      25.5  | 1.9e-07 |      24 |
 | Data::Clean-inplace | ary10k-u1-obj   | inplace |      4080 |     0.245 |      26.1  | 4.6e-08 |      27 |
 | Data::Clean-inplace | ary100-u100-obj | inplace |      9700 |     0.1   |      62    | 2.2e-07 |      23 |
 | Data::Clean-clone   | ary100-u1-obj   |         |     15000 |     0.067 |      95    | 1.1e-07 |      20 |
 | Data::Clean-inplace | ary100-u1-obj   | inplace |     39000 |     0.026 |     250    |   1e-07 |      25 |
 +---------------------+-----------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCleansing::Object --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | JSON::PP            |      27   |                   20   |       1    | 4.6e-05 |      22 |
 | Data::Rmap          |      14.9 |                    7.9 |       1.82 | 1.3e-05 |      20 |
 | Data::Clean         |      11   |                    4   |       2.4  | 1.4e-05 |      20 |
 | perl -e1 (baseline) |       7   |                    0   |       3.9  | 2.7e-05 |      20 |
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
