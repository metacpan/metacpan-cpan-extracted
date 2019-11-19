package Bencher::Scenario::SamplingFromList;

our $DATE = '2019-09-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark random sampling from a list',
    participants => [
        {
            fcall_template => 'List::MoreUtils::samples(<num_samples>, @{<data>})',
            result_is_list => 1,
        },
        {
            module => 'List::Util',
            function => 'shuffle',
            code_template => 'my @shuffled = List::Util::shuffle(@{<data>}); @shuffled[0..<num_samples>-1]',
            result_is_list => 1,
        },
        {
            fcall_template => 'Array::Pick::Scan::random_item(<data>, <num_samples>)',
            result_is_list => 1,
        },
    ],

    datasets => [
        {
            name=>'int100-1',
            args=>{data=>[1..100], num_samples=>1},
        },
        {
            name=>'int100-10',
            args=>{data=>[1..100], num_samples=>10},
        },
        {
            name=>'int100-100',
            args=>{data=>[1..100], num_samples=>100},
        },

        {
            name=>'int1000-1',
            args=>{data=>[1..1000], num_samples=>1},
        },
        {
            name=>'int1000-10',
            args=>{data=>[1..1000], num_samples=>10},
        },
        {
            name=>'int1000-100',
            args=>{data=>[1..1000], num_samples=>100},
        },
        {
            name=>'int1000-1000',
            args=>{data=>[1..1000], num_samples=>1000},
        },
    ],
};

1;
# ABSTRACT: Benchmark random sampling from a list

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SamplingFromList - Benchmark random sampling from a list

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::SamplingFromList (from Perl distribution Bencher-Scenario-SamplingFromList), released on 2019-09-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SamplingFromList

To run module startup overhead benchmark:

 % bencher --module-startup -m SamplingFromList

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::MoreUtils> 0.428

L<List::Util> 1.5

L<Array::Pick::Scan> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::MoreUtils::samples (perl_code)

Function call template:

 List::MoreUtils::samples(<num_samples>, @{<data>})



=item * List::Util::shuffle (perl_code)

Code template:

 my @shuffled = List::Util::shuffle(@{<data>}); @shuffled[0..<num_samples>-1]



=item * Array::Pick::Scan::random_item (perl_code)

Function call template:

 Array::Pick::Scan::random_item(<data>, <num_samples>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int100-1

=item * int100-10

=item * int100-100

=item * int1000-1

=item * int1000-10

=item * int1000-100

=item * int1000-1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m SamplingFromList >>):

 #table1#
 +--------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | participant                    | dataset      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------------------+--------------+-----------+-----------+------------+---------+---------+
 | Array::Pick::Scan::random_item | int1000-1000 |    2650   |  377      |    1       | 2.1e-07 |      20 |
 | Array::Pick::Scan::random_item | int1000-100  |    3100   |  320      |    1.2     | 9.1e-07 |      20 |
 | Array::Pick::Scan::random_item | int1000-10   |    3800   |  263      |    1.43    | 2.1e-07 |      20 |
 | List::Util::shuffle            | int1000-1000 |   17100   |   58.4    |    6.47    | 2.2e-08 |      29 |
 | List::Util::shuffle            | int1000-100  |   19000   |   53      |    7.1     |   8e-08 |      20 |
 | List::Util::shuffle            | int1000-1    |   19147.4 |   52.2265 |    7.22595 | 1.1e-11 |      26 |
 | List::Util::shuffle            | int1000-10   |   19200   |   52.1    |    7.25    | 2.6e-08 |      21 |
 | List::MoreUtils::samples       | int1000-1000 |   30200   |   33.1    |   11.4     | 1.3e-08 |      21 |
 | Array::Pick::Scan::random_item | int100-10    |   31000   |   33      |   12       | 6.2e-08 |      23 |
 | Array::Pick::Scan::random_item | int100-100   |   35000   |   29      |   13       |   4e-08 |      20 |
 | List::MoreUtils::samples       | int1000-100  |   43700   |   22.9    |   16.5     | 6.7e-09 |      20 |
 | List::MoreUtils::samples       | int1000-1    |   44000   |   23      |   17       | 2.6e-08 |      21 |
 | List::MoreUtils::samples       | int1000-10   |   45675   |   21.894  |   17.237   | 5.6e-11 |      20 |
 | Array::Pick::Scan::random_item | int1000-1    |   47900   |   20.9    |   18.1     | 5.7e-09 |      27 |
 | List::Util::shuffle            | int100-100   |  164000   |    6.11   |   61.8     |   5e-09 |      36 |
 | List::Util::shuffle            | int100-10    |  179900   |    5.559  |   67.88    | 1.4e-10 |      23 |
 | List::Util::shuffle            | int100-1     |  188500   |    5.306  |   71.13    | 9.4e-11 |      20 |
 | List::MoreUtils::samples       | int100-100   |  310000   |    3.3    |  120       | 1.2e-08 |      24 |
 | Array::Pick::Scan::random_item | int100-1     |  420000   |    2.38   |  159       |   1e-09 |      21 |
 | List::MoreUtils::samples       | int100-10    |  433000   |    2.31   |  164       | 8.3e-10 |      20 |
 | List::MoreUtils::samples       | int100-1     |  450000   |    2.2    |  170       | 2.8e-09 |      29 |
 +--------------------------------+--------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SamplingFromList --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | List::MoreUtils     |      14   |                    9.3 |        1   |   2e-05 |      20 |
 | List::Util          |       8   |                    3.3 |        1.7 | 1.3e-05 |      20 |
 | Array::Pick::Scan   |       7.3 |                    2.6 |        1.9 |   3e-05 |      20 |
 | perl -e1 (baseline) |       4.7 |                    0   |        2.9 | 2.5e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SamplingFromList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SamplingFromList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SamplingFromList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::RandomLineModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
