package Bencher::Scenario::SortKeyTop;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Sort::Key::Top',
    participants => [
        {
            name => 'sort',
            summary => "Perl's sort() builtin",
            code_template=>'state $elems=<elems>; my @sorted = sort { $a <=> $b } @$elems; splice @sorted, 0, <n>',
            result_is_list => 1,
        },
        {
            name => 'Sort::Key::Top',
            fcall_template => 'Sort::Key::Top::nkeytopsort(sub { $_ }, <n>, @{<elems>})',
            result_is_list => 1,
        },
        {
            name => 'Sort::Key::Top::PP',
            fcall_template => 'Sort::Key::Top::PP::nkeytopsort(sub { $_ }, <n>, @{<elems>})',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name=>'elems=10 , n=5'    , args=>{elems=>[reverse 1..10]  , n=>  5}},
        {name=>'elems=100, n=10'   , args=>{elems=>[reverse 1..100] , n=> 10}},
        {name=>'elems=1000, n=10'  , args=>{elems=>[reverse 1..1000], n=> 10}},
    ],
};

1;
# ABSTRACT: Benchmark Sort::Key::Top

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SortKeyTop - Benchmark Sort::Key::Top

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::SortKeyTop (from Perl distribution Bencher-Scenario-SortKeyTop), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SortKeyTop

To run module startup overhead benchmark:

 % bencher --module-startup -m SortKeyTop

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::Key::Top> 0.08

L<Sort::Key::Top::PP> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * sort (perl_code)

Perl's sort() builtin.

Code template:

 state $elems=<elems>; my @sorted = sort { $a <=> $b } @$elems; splice @sorted, 0, <n>



=item * Sort::Key::Top (perl_code)

Function call template:

 Sort::Key::Top::nkeytopsort(sub { $_ }, <n>, @{<elems>})



=item * Sort::Key::Top::PP (perl_code)

Function call template:

 Sort::Key::Top::PP::nkeytopsort(sub { $_ }, <n>, @{<elems>})



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=10 , n=5

=item * elems=100, n=10

=item * elems=1000, n=10

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m SortKeyTop >>):

 #table1#
 +--------------------+------------------+-----------+-----------+------------+---------+---------+
 | participant        | dataset          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------------+------------------+-----------+-----------+------------+---------+---------+
 | Sort::Key::Top::PP | elems=1000, n=10 |     849   | 1180      |      1     | 4.3e-07 |      20 |
 | Sort::Key::Top     | elems=1000, n=10 |    5360   |  187      |      6.32  | 5.2e-08 |      21 |
 | Sort::Key::Top::PP | elems=100, n=10  |    8400   |  120      |      9.9   | 2.1e-07 |      20 |
 | sort               | elems=1000, n=10 |   32100   |   31.1    |     37.9   | 1.2e-08 |      25 |
 | Sort::Key::Top     | elems=100, n=10  |   52600   |   19      |     61.9   | 6.1e-09 |      24 |
 | Sort::Key::Top::PP | elems=10 , n=5   |   92868.4 |   10.7679 |    109.415 |   9e-12 |      20 |
 | sort               | elems=100, n=10  |  292000   |    3.42   |    344     | 1.7e-09 |      20 |
 | Sort::Key::Top     | elems=10 , n=5   |  430000   |    2.3    |    500     | 3.3e-09 |      20 |
 | sort               | elems=10 , n=5   | 1420000   |    0.702  |   1680     | 3.4e-10 |      23 |
 +--------------------+------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SortKeyTop --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Sort::Key::Top::PP  | 2                            | 5.4                | 19             |      17   |                   11.1 |        1   | 5.9e-05 |      21 |
 | Sort::Key::Top      | 1.1                          | 4.5                | 18             |       9.8 |                    3.9 |        1.7 | 1.7e-05 |      20 |
 | perl -e1 (baseline) | 0.82                         | 4.1                | 16             |       5.9 |                    0   |        2.9 | 2.5e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SortKeyTop>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SortKeyTop>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SortKeyTop>

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
