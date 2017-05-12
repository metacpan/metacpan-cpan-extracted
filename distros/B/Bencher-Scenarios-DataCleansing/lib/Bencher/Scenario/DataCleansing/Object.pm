package Bencher::Scenario::DataCleansing::Object;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark data cleansing (unblessing object)',
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

This document describes version 0.003 of Bencher::Scenario::DataCleansing::Object (from Perl distribution Bencher-Scenarios-DataCleansing), released on 2017-01-25.

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

L<Data::Clean> 0.48

L<Data::Rmap> 0.64

L<JSON::PP> 2.27300

L<Scalar::Util> 1.45

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m DataCleansing::Object >>):

 #table1#
 +---------------------+-----------------+-----------+-----------+------------+---------+---------+
 | participant         | dataset         | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------------+-----------+-----------+------------+---------+---------+
 | JSON::PP            | ary10k-u1-obj   |     220   | 4.5       |     1      | 9.4e-06 |      20 |
 | Data::Rmap          | ary10k-u10k-obj |     310   | 3.2       |     1.4    | 8.5e-06 |      20 |
 | JSON::PP            | ary10k-u10k-obj |     323   | 3.1       |     1.46   | 2.7e-06 |      20 |
 | Data::Rmap          | ary10k-u1-obj   |     620   | 1.6       |     2.8    | 6.1e-06 |      20 |
 | Data::Clean-clone   | ary10k-u10k-obj |    1130   | 0.884     |     5.12   | 4.8e-07 |      20 |
 | Data::Clean-inplace | ary10k-u10k-obj |    1450   | 0.688     |     6.58   | 2.7e-07 |      20 |
 | JSON::PP            | ary100-u1-obj   |    2300   | 0.43      |    11      | 4.5e-07 |      23 |
 | JSON::PP            | ary100-u100-obj |    3100   | 0.32      |    14      | 6.2e-07 |      21 |
 | Data::Rmap          | ary100-u100-obj |    3100   | 0.32      |    14      | 4.3e-07 |      20 |
 | Data::Clean-clone   | ary10k-u1-obj   |    4800   | 0.21      |    22      | 4.2e-07 |      21 |
 | Data::Clean-inplace | ary10k-u1-obj   |    5700   | 0.18      |    26      | 4.3e-07 |      20 |
 | Data::Rmap          | ary100-u1-obj   |    6100   | 0.16      |    28      | 4.8e-07 |      20 |
 | Data::Clean-clone   | ary100-u100-obj |   10893.1 | 0.0918013 |    49.3177 |   0     |      27 |
 | Data::Clean-inplace | ary100-u100-obj |   13100   | 0.0763    |    59.3    | 2.7e-08 |      20 |
 | Data::Clean-clone   | ary100-u1-obj   |   42000   | 0.024     |   190      | 3.3e-08 |      20 |
 | Data::Clean-inplace | ary100-u1-obj   |   53000   | 0.019     |   240      | 3.3e-08 |      20 |
 +---------------------+-----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCleansing::Object --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | JSON::PP            | 3.1                          | 6.6                | 22             |      23   |                   17.2 |        1   | 7.2e-05 |      20 |
 | Data::Rmap          | 1.4                          | 4.8                | 19             |      13   |                    7.2 |        1.8 | 5.9e-05 |      20 |
 | Data::Clean         | 1.1                          | 4.5                | 16             |      10   |                    4.2 |        2.3 | 8.2e-05 |      20 |
 | perl -e1 (baseline) | 1.1                          | 4.5                | 16             |       5.8 |                    0   |        4   | 1.4e-05 |      20 |
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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
