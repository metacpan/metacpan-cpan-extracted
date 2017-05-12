package Bencher::Scenario::SortSub::naturally;

our $DATE = '2017-02-02'; # DATE
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use List::Util qw(shuffle);
use Sort::Sub qw($naturally);

our $scenario = {
    summary => 'Benchmark natural sorting',
    modules => {
        'Sort::Sub' => {version=>'0.05'},
    },
    participants => [
        {
            name => 'Sort::Sub::naturally',
            module => 'Sort::Sub',
            code_template => 'sort $Bencher::Scenario::SortSub::naturally::naturally @{<data>}',
            result_is_list => 1,
        },
        {
            fcall_template => 'Sort::Naturally::nsort(@{<data>})',
            result_is_list => 1,
        },
        {
            name => 'Sort::Naturally::ncmp',
            module => 'Sort::Naturally',
            code_template => 'sort {Sort::Naturally::ncmp($a, $b)} @{<data>}',
            result_is_list => 1,
        },
        {
            fcall_template => 'Sort::Naturally::XS::nsort(@{<data>})',
            result_is_list => 1,
        },
        {
            name => 'Sort::Naturally::XS::ncmp',
            module => 'Sort::Naturally::XS',
            code_template => 'sort {Sort::Naturally::XS::ncmp($a, $b)} @{<data>}',
            result_is_list => 1,
        },
        {
            fcall_template => 'Sort::Key::Natural::natsort(@{<data>})',
            result_is_list => 1,
        },
    ],
    datasets => [
        { name=>'10items' , args=>{data=>[shuffle map { "track$_.mp3" } 1..10 ]} , result=>[map { "track$_.mp3" } 1..10 ]},
        { name=>'100items', args=>{data=>[shuffle map { "track$_.mp3" } 1..100]} , result=>[map { "track$_.mp3" } 1..100]},
    ],
};

1;
# ABSTRACT: Benchmark natural sorting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SortSub::naturally - Benchmark natural sorting

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::SortSub::naturally (from Perl distribution Bencher-Scenarios-SortSub), released on 2017-02-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SortSub::naturally

To run module startup overhead benchmark:

 % bencher --module-startup -m SortSub::naturally

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::Key::Natural> 0.04

L<Sort::Naturally> 1.03

L<Sort::Naturally::XS> 0.7.3

L<Sort::Sub> 0.10

=head1 BENCHMARK PARTICIPANTS

=over

=item * Sort::Sub::naturally (perl_code)

Code template:

 sort $Bencher::Scenario::SortSub::naturally::naturally @{<data>}



=item * Sort::Naturally::nsort (perl_code)

Function call template:

 Sort::Naturally::nsort(@{<data>})



=item * Sort::Naturally::ncmp (perl_code)

Code template:

 sort {Sort::Naturally::ncmp($a, $b)} @{<data>}



=item * Sort::Naturally::XS::nsort (perl_code)

Function call template:

 Sort::Naturally::XS::nsort(@{<data>})



=item * Sort::Naturally::XS::ncmp (perl_code)

Code template:

 sort {Sort::Naturally::XS::ncmp($a, $b)} @{<data>}



=item * Sort::Key::Natural::natsort (perl_code)

Function call template:

 Sort::Key::Natural::natsort(@{<data>})



=back

=head1 BENCHMARK DATASETS

=over

=item * 10items

=item * 100items

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m SortSub::naturally >>):

 #table1#
 {dataset=>"100items"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Sort::Naturally::nsort      |       578 |  1.73     |        1   | 9.1e-07 |      20 |
 | Sort::Key::Natural::natsort |      2000 |  0.5      |        3   | 5.9e-06 |      20 |
 | Sort::Naturally::XS::nsort  |      7950 |  0.126    |       13.8 | 4.7e-08 |      26 |
 | Sort::Sub::naturally        |    200000 |  0.005    |      400   | 8.4e-08 |      31 |
 | Sort::Naturally::XS::ncmp   |    233800 |  0.004277 |      404.5 | 4.6e-11 |      20 |
 | Sort::Naturally::ncmp       |    235000 |  0.00426  |      406   | 1.7e-09 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"10items"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Sort::Naturally::nsort      |     15000 | 65        |      1     | 1.1e-07 |      20 |
 | Sort::Key::Natural::natsort |     18000 | 55        |      1.2   |   8e-08 |      20 |
 | Sort::Naturally::XS::nsort  |    189260 |  5.2838   |     12.278 | 1.2e-11 |      24 |
 | Sort::Naturally::ncmp       |   1580000 |  0.633    |    103     |   2e-10 |      21 |
 | Sort::Sub::naturally        |   1768950 |  0.565308 |    114.758 |   0     |      20 |
 | Sort::Naturally::XS::ncmp   |   1794000 |  0.5576   |    116.4   | 4.1e-11 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SortSub::naturally --module-startup >>):

 #table3#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Sort::Key::Natural  | 1.4                          | 4.8                | 19             |      27   |                   21.6 |        1   |   6e-05 |      20 |
 | Sort::Naturally::XS | 1.4                          | 4.7                | 19             |      12   |                    6.6 |        2.3 | 1.5e-05 |      21 |
 | Sort::Naturally     | 1.2                          | 4.7                | 16             |      11   |                    5.6 |        2.4 | 4.4e-05 |      20 |
 | Sort::Sub           | 1.2                          | 4.7                | 16             |       7.9 |                    2.5 |        3.4 |   2e-05 |      20 |
 | perl -e1 (baseline) | 0.87                         | 4.2                | 16             |       5.4 |                    0   |        5   |   1e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-SortSub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-SortSub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-SortSub>

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
