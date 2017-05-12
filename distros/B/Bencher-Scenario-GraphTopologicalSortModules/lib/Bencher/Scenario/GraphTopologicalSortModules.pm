package Bencher::Scenario::GraphTopologicalSortModules;

our $DATE = '2017-04-03'; # DATE
our $VERSION = '0.003'; # VERSION

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
            name => 'g1',
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
        # hangs Sort::Topological
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

This document describes version 0.003 of Bencher::Scenario::GraphTopologicalSortModules (from Perl distribution Bencher-Scenario-GraphTopologicalSortModules), released on 2017-04-03.

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

L<Algorithm::Dependency> 1.110

L<Data::Graph::Util> 0.002

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

=item * g1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m GraphTopologicalSortModules >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Algorithm::Dependency       |     16700 |      60   |       1    | 2.5e-08 |      23 |
 | Sort::Topological::toposort |     16800 |      59.6 |       1.01 | 2.5e-08 |      23 |
 | Data::Graph::Util::toposort |     58700 |      17   |       3.52 | 6.7e-09 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m GraphTopologicalSortModules --module-startup >>):

 #table2#
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant           | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Algorithm::Dependency | 0.82                         | 4.1                | 20             |      16   |                   10.5 |        1   | 2.8e-05 |      20 |
 | Sort::Topological     | 0.95                         | 4.4                | 20             |       9   |                    3.5 |        1.8 | 2.4e-05 |      20 |
 | Data::Graph::Util     | 1.7                          | 5.2                | 25             |       8.7 |                    3.2 |        1.8 | 1.6e-05 |      20 |
 | perl -e1 (baseline)   | 0.97                         | 4.4                | 20             |       5.5 |                    0   |        2.9 | 2.5e-05 |      24 |
 +-----------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
