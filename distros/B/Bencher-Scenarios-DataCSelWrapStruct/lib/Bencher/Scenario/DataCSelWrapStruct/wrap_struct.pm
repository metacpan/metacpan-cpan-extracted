package Bencher::Scenario::DataCSelWrapStruct::wrap_struct;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark wrap_struct()',
    participants => [
        {fcall_template => 'Data::CSel::WrapStruct::wrap_struct(<data>)'},
    ],
    datasets => [
        {name => 'scalar', args => {data=>1}},
        {name => 'array1', args => {data=>[1]}},
        {name => 'array100', args => {data=>[1..100]}},
        {name => 'array1000', args => {data=>[1..1000]}},
        {name => 'hash1', args => {data=>{1=>1}}},
        {name => 'hash100', args => {data=>{ map {$_=>$_} 1..100 }}},
        {name => 'hash1000', args => {data=>{ map {$_=>$_} 1..1000 }}},
    ],
};

1;
# ABSTRACT: Benchmark wrap_struct()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataCSelWrapStruct::wrap_struct - Benchmark wrap_struct()

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::DataCSelWrapStruct::wrap_struct (from Perl distribution Bencher-Scenarios-DataCSelWrapStruct), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataCSelWrapStruct::wrap_struct

To run module startup overhead benchmark:

 % bencher --module-startup -m DataCSelWrapStruct::wrap_struct

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::CSel::WrapStruct> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::CSel::WrapStruct::wrap_struct (perl_code)

Function call template:

 Data::CSel::WrapStruct::wrap_struct(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * scalar

=item * array1

=item * array100

=item * array1000

=item * hash1

=item * hash100

=item * hash1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m DataCSelWrapStruct::wrap_struct --with-args-size --with-result-size >>:

 #table1#
 +-----------+-----------+-----------+------------+--------------------+------------------+---------+---------+
 | dataset   | rate (/s) | time (μs) | vs_slowest | arg_data_size (kB) | result_size (kB) |  errors | samples |
 +-----------+-----------+-----------+------------+--------------------+------------------+---------+---------+
 | hash1000  |       726 | 1380      |       1    |           91       |         310      | 6.9e-07 |      20 |
 | array1000 |      1280 |  784      |       1.76 |           31.3     |         211      | 4.8e-07 |      20 |
 | hash100   |      8400 |  120      |      12    |            9.3     |          31      | 4.8e-07 |      20 |
 | array100  |     12000 |   82      |      17    |            3.2     |          21      | 1.3e-07 |      20 |
 | hash1     |    310000 |    3.2    |     430    |            0.25    |           0.81   | 6.7e-09 |      20 |
 | array1    |    440000 |    2.3    |     600    |            0.094   |           0.49   | 3.3e-09 |      20 |
 | scalar    |   1419000 |    0.7047 |    1955    |            0.02344 |           0.1484 | 4.6e-11 |      25 |
 +-----------+-----------+-----------+------------+--------------------+------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DataCSelWrapStruct::wrap_struct --module-startup >>):

 #table2#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant            | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Data::CSel::WrapStruct | 844                          | 4                  | 16             |      10   |                    3.8 |        1   | 2.6e-05 |      20 |
 | perl -e1 (baseline)    | 1028                         | 4.5                | 16             |       6.2 |                    0   |        1.6 | 1.3e-05 |      20 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSelWrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSelWrapStruct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSelWrapStruct>

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
