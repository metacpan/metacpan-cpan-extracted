package Bencher::Scenario::SortBySpec;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)',
    participants => [
        {
            name => 'gen_sorter-sbe',
            tags => ['gen_sorter', 'sbe'],
            module => 'Sort::ByExample',
            code_template => 'Sort::ByExample::sbe(<spec>)',
        },
        {
            name => 'gen_sorter-sbs',
            tags => ['gen_sorter', 'sbs'],
            module => 'Sort::BySpec',
            code_template => 'Sort::BySpec::sort_by_spec(spec => <spec>)',
        },

        {
            name => 'sort-sbe',
            tags => ['sort', 'sbe'],
            module => 'Sort::ByExample',
            code_template => 'state $sorter = Sort::ByExample::sbe(<spec>); [$sorter->(@{<list>})]',
        },
        {
            name => 'sort-sbs',
            tags => ['sort', 'sbs'],
            module => 'Sort::BySpec',
            code_template => 'state $sorter = Sort::BySpec::sort_by_spec(spec => <spec>); [$sorter->(@{<list>})]',
        },
    ],

    datasets => [
        {
            name => 'eg-num5-list10',
            args => {
                spec => [5,4,3,2,1],
                # currently unwieldy, need to use hash
                #'list@' => [
                #    [1..10],  # 10-elem
                #    [1..100], # 100-elem
                #],
                'list' => [1..10],
            },
        },
        {
            name => 'eg-num5-list100',
            args => {
                spec => [5,4,3,2,1],
                'list' => [1..100],
            },
        },
        {
            name => 'eg-num5-list1000',
            args => {
                spec => [5,4,3,2,1],
                'list' => [1..1000],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SortBySpec - Benchmark Sort::BySpec (e.g. against Sort::ByExample, etc)

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::SortBySpec (from Perl distribution Bencher-Scenario-SortBySpec), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SortBySpec

To run module startup overhead benchmark:

 % bencher --module-startup -m SortBySpec

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::ByExample> 0.007

L<Sort::BySpec> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_sorter-sbe (perl_code) [gen_sorter, sbe]

Code template:

 Sort::ByExample::sbe(<spec>)



=item * gen_sorter-sbs (perl_code) [gen_sorter, sbs]

Code template:

 Sort::BySpec::sort_by_spec(spec => <spec>)



=item * sort-sbe (perl_code) [sort, sbe]

Code template:

 state $sorter = Sort::ByExample::sbe(<spec>); [$sorter->(@{<list>})]



=item * sort-sbs (perl_code) [sort, sbs]

Code template:

 state $sorter = Sort::BySpec::sort_by_spec(spec => <spec>); [$sorter->(@{<list>})]



=back

=head1 BENCHMARK DATASETS

=over

=item * eg-num5-list10

=item * eg-num5-list100

=item * eg-num5-list1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m SortBySpec >>):

 #table1#
 +----------------+------------------+-----------+-----------+------------+---------+---------+
 | participant    | dataset          | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------+------------------+-----------+-----------+------------+---------+---------+
 | sort-sbs       | eg-num5-list1000 |       220 | 4.5       |       1    | 9.9e-06 |      30 |
 | sort-sbs       | eg-num5-list100  |      2200 | 0.454     |       9.93 | 2.1e-07 |      20 |
 | sort-sbe       | eg-num5-list1000 |      2440 | 0.411     |      11    | 4.8e-08 |      25 |
 | sort-sbe       | eg-num5-list100  |     23200 | 0.0431    |     105    | 1.3e-08 |      22 |
 | sort-sbs       | eg-num5-list10   |     33200 | 0.0302    |     149    | 1.2e-08 |      24 |
 | sort-sbe       | eg-num5-list10   |    117000 | 0.00854   |     528    | 2.8e-09 |      28 |
 | gen_sorter-sbs | eg-num5-list100  |    180000 | 0.0055    |     810    | 6.7e-09 |      20 |
 | gen_sorter-sbe | eg-num5-list100  |    184230 | 0.0054281 |     829.77 | 1.1e-11 |      21 |
 | gen_sorter-sbe | eg-num5-list10   |    185000 | 0.00539   |     835    | 1.7e-09 |      20 |
 | gen_sorter-sbs | eg-num5-list10   |    200000 | 0.005     |     900    | 7.4e-08 |      31 |
 | gen_sorter-sbs | eg-num5-list1000 |    202000 | 0.00495   |     910    | 1.7e-09 |      20 |
 | gen_sorter-sbe | eg-num5-list1000 |    207000 | 0.00484   |     930    | 1.5e-09 |      24 |
 +----------------+------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SortBySpec --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Sort::ByExample     | 0.99                         | 4.3                | 16             |      21   |                   15.1 |        1   | 6.6e-05 |      20 |
 | Sort::BySpec        | 2.4                          | 5.9                | 22             |       9.2 |                    3.3 |        2.3 | 2.7e-05 |      20 |
 | perl -e1 (baseline) | 2.4                          | 5.8                | 22             |       5.9 |                    0   |        3.5 | 1.3e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SortBySpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SortBySpec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SortBySpec>

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
