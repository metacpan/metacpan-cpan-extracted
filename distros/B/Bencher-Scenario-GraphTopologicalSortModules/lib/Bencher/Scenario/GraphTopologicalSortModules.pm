package Bencher::Scenario::GraphTopologicalSortModules;

our $DATE = '2019-02-15'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark graph topological sort modules',
    modules => {
    },
    participants => [
        {
            module => 'Sort::Topological',
            function => 'toposort',
            code_template  => 'my $graph = <graph>; Sort::Topological::toposort(sub { @{ $graph->{$_[0]} || [] } }, <unsorted>)',
            result_is_list => 1,
        },
        {
            fcall_template => 'Data::Graph::Util::toposort(<graph>, <unsorted>)',
            result_is_list => 1,
        },
        {
            module => 'Algorithm::Dependency',
            helper_modules => ['Algorithm::Dependency::Source::HoA'],
            code_template => 'my $deps = Algorithm::Dependency::Source::HoA->new(<graph>); my $dep = Algorithm::Dependency->new(source=>$deps); $dep->schedule_all',
        },
    ],

    datasets => [
        {
            name => 'empty',
            args => { graph => {}, unsorted => [] },
            result => [],
            include_by_default => 0, # croaks Algorithm::Dependency
        },

        {
            name => '2nodes-1edge',
            args => {
                graph => {
                    a => ['b'],
                    b => [], # Algorithm::Dependency requires all nodes to be specified
                },
                unsorted => ['b','a'],
            },
            result => ['a', 'b'],
        },

        {
            name => '6nodes-7edges',
            args => {
                graph => {
                    'a' => [ 'b', 'c' ],
                    'c' => [ 'x' ],
                    'b' => [ 'c', 'x' ],
                    'x' => [ 'y' ],
                    'y' => [ 'z' ],
                    'z' => [ ],
                },
                unsorted => ['z', 'a', 'x', 'c', 'b', 'y'],
            },
            result => ['a', 'b', 'c', 'x', 'y', 'z'],
        },

        {
            name => '10nodes-35edges',
            args => {
                graph => {
                    (map { sprintf("%02d",$_) => [grep {$_<=10} sprintf("%02d", $_+1), sprintf("%02d", $_+2), sprintf("%02d", $_+3), sprintf("%02d", $_+4), sprintf("%02d", $_+5)] } 1..10)
                },
                unsorted => [reverse(map {sprintf("%02d", $_)} 1..10)],
            },
            result => [map {sprintf("%02d", $_)} 1..10],
        },

        {
            # Algorithm::Dependency gives different results when we use 1..100 instead of 001 .. 100
            name => '100nodes-100edges',
            args => {
                graph => {
                    (map { (sprintf("%03d",$_) => [$_==1 ? ("002","003") : $_==100 ? () : (sprintf("%03d", $_+1))]) } 1..100)
                },
                unsorted => [reverse(map {sprintf("%03d", $_)} 1..100)],
            },
            result => [map {sprintf("%03d", $_)} 1..100],
        },

        {
            name => '100nodes-500edges',
            args => {
                graph => {
                    (map { (sprintf("%03d",$_) => [$_==1 ? ("002".."021") : (grep {$_<=100} sprintf("%03d", $_+1), sprintf("%03d", $_+2), sprintf("%03d", $_+3), sprintf("%03d", $_+4), sprintf("%03d", $_+5))]) } 1..100)
                },
                unsorted => [reverse(map {sprintf("%03d", $_)} 1..100)],
            },
            result => [map {sprintf("%03d", $_)} 1..100],
            # Sort::Topological eats too much memory
            include_by_default => 0,
        },

        # cyclic datasets not included by default because they hang
        # Sort::Topological
        {
            name => 'cyclic1',
            args => {
                graph => {a=>["a"]},
                unsorted => ['a'],
            },
            include_by_default => 0,
        },
        {
            name => 'cyclic2',
            args => {
                graph => {a=>["b"], b=>["a"]},
                unsorted => ['b', 'a'],
            },
            include_by_default => 0,
        },
        {
            name => 'cyclic3',
            args => {
                graph => {a=>["b"], b=>["c"], c=>["a"]},
                unsorted => ['a', 'c', 'b'],
            },
            include_by_default => 0,
        },
        {
            name => 'cyclic4',
            args => {
                graph => {a=>["b","c"], c=>["a","b"], d=>["e"], e=>["f","g","h","a"]},
                unsorted => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
            },
            include_by_default => 0,
        },
    ],
};

1;
# ABSTRACT: Benchmark graph topological sort modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::GraphTopologicalSortModules - Benchmark graph topological sort modules

=head1 VERSION

This document describes version 0.005 of Bencher::Scenario::GraphTopologicalSortModules (from Perl distribution Bencher-Scenario-GraphTopologicalSortModules), released on 2019-02-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m GraphTopologicalSortModules

To run module startup overhead benchmark:

 % bencher --module-startup -m GraphTopologicalSortModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Algorithm::Dependency> 1.111

L<Data::Graph::Util> 0.006

L<Sort::Topological> 0.02

=head1 BENCHMARK PARTICIPANTS

=over

=item * Sort::Topological::toposort (perl_code)

Code template:

 my $graph = <graph>; Sort::Topological::toposort(sub { @{ $graph->{$_[0]} || [] } }, <unsorted>)



=item * Data::Graph::Util::toposort (perl_code)

Function call template:

 Data::Graph::Util::toposort(<graph>, <unsorted>)



=item * Algorithm::Dependency (perl_code)

Code template:

 my $deps = Algorithm::Dependency::Source::HoA->new(<graph>); my $dep = Algorithm::Dependency->new(source=>$deps); $dep->schedule_all



=back

=head1 BENCHMARK DATASETS

=over

=item * 2nodes-1edge

=item * 6nodes-7edges

=item * 10nodes-35edges

=item * 100nodes-100edges

=item * empty (not included by default)

=item * 100nodes-500edges (not included by default)

=item * cyclic1 (not included by default)

=item * cyclic2 (not included by default)

=item * cyclic3 (not included by default)

=item * cyclic4 (not included by default)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m GraphTopologicalSortModules >>):

 #table1#
 +-----------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | participant                 | dataset           | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-------------------+-----------+-----------+------------+---------+---------+
 | Sort::Topological::toposort | 100nodes-100edges |        45 |   22      |          1 | 7.5e-05 |      20 |
 | Sort::Topological::toposort | 10nodes-35edges   |       980 |    1      |         22 | 1.4e-06 |      20 |
 | Algorithm::Dependency       | 100nodes-100edges |       990 |    1      |         22 | 9.3e-06 |      20 |
 | Data::Graph::Util::toposort | 100nodes-100edges |      1300 |    0.76   |         29 | 9.1e-07 |      20 |
 | Algorithm::Dependency       | 6nodes-7edges     |      5500 |    0.18   |        120 | 4.8e-07 |      20 |
 | Data::Graph::Util::toposort | 10nodes-35edges   |      8900 |    0.11   |        200 | 2.7e-07 |      20 |
 | Algorithm::Dependency       | 10nodes-35edges   |      9800 |    0.1    |        220 | 5.3e-07 |      22 |
 | Algorithm::Dependency       | 2nodes-1edge      |     12000 |    0.084  |        270 | 2.2e-07 |      23 |
 | Data::Graph::Util::toposort | 6nodes-7edges     |     19000 |    0.054  |        410 | 1.8e-07 |      21 |
 | Sort::Topological::toposort | 6nodes-7edges     |     24000 |    0.043  |        520 | 1.1e-07 |      20 |
 | Data::Graph::Util::toposort | 2nodes-1edge      |     47000 |    0.021  |       1000 | 4.1e-08 |      34 |
 | Sort::Topological::toposort | 2nodes-1edge      |    150000 |    0.0068 |       3300 | 1.3e-08 |      20 |
 +-----------------------------+-------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m GraphTopologicalSortModules --module-startup >>):

 #table2#
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | participant           | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | Algorithm::Dependency |      42   |                   28.4 |       1    |   7e-05 |      20 |
 | Sort::Topological     |      24   |                   10.4 |       1.8  | 7.4e-05 |      23 |
 | Data::Graph::Util     |      22.8 |                    9.2 |       1.86 | 2.1e-05 |      20 |
 | perl -e1 (baseline)   |      13.6 |                    0   |       3.12 | 9.9e-06 |      20 |
 +-----------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-GraphTopologicalSortModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-GraphTopologicalSortModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-GraphTopologicalSortModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
