package Bencher::Scenario::HashUnique;

our $DATE = '2017-06-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Hash::Unique',
    modules => {
        'Hash::Unique' => { version=>"0.06" },
    },
    participants => [
        {
            name => 'Hash::Unique',
            module => 'Hash::Unique',
            code_template => '[ Hash::Unique->get_unique_hash(<array>, <key>) ]',
        },
        {
            name => 'ad-hoc',
            code_template => 'my @res; my %seen; for (@{ <array> }) { push @res, $_ unless $seen{ $_->{ <key> } }++ }; \@res',
        },
    ],
    datasets => [
        {
            name=>'2elems-1key',
            args=>{
                array=>[
                    {a=>1},
                    {a=>1},
                ],
                key => 'a',
            },
            result=>[
                {a=>1},
            ],
        },
        {
            name=>'10elems-3keys',
            args=>{
                array=>[
                    {a=>1, b=>1, c=>1}, #0
                    {a=>1, b=>1, c=>1}, #1
                    {a=>1, b=>1, c=>2}, #2
                    {a=>1, b=>2, c=>1}, #3
                    {a=>1, b=>1, c=>1}, #4
                    {a=>1, b=>2, c=>1}, #5
                    {a=>1, b=>1, c=>3}, #6
                    {a=>1, b=>1, c=>4}, #7
                    {a=>1, b=>2, c=>1}, #8
                    {a=>2, b=>1, c=>2}, #9
                ],
                key => 'c',
            },
            result=>[
                {a=>1, b=>1, c=>1}, #0
                {a=>1, b=>1, c=>2}, #2
                {a=>1, b=>1, c=>3}, #6
                {a=>1, b=>1, c=>4}, #7
            ],
        },
    ],
};

1;
# ABSTRACT: Benchmark Hash::Unique

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HashUnique - Benchmark Hash::Unique

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::HashUnique (from Perl distribution Bencher-Scenario-HashUnique), released on 2017-06-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HashUnique

To run module startup overhead benchmark:

 % bencher --module-startup -m HashUnique

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Hash::Unique> 0.06

=head1 BENCHMARK PARTICIPANTS

=over

=item * Hash::Unique (perl_code)

Code template:

 [ Hash::Unique->get_unique_hash(<array>, <key>) ]



=item * ad-hoc (perl_code)

Code template:

 my @res; my %seen; for (@{ <array> }) { push @res, $_ unless $seen{ $_->{ <key> } }++ }; \@res



=back

=head1 BENCHMARK DATASETS

=over

=item * 2elems-1key

=item * 10elems-3keys

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m HashUnique >>):

 #table1#
 +--------------+---------------+-----------+-----------+------------+---------+---------+
 | participant  | dataset       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +--------------+---------------+-----------+-----------+------------+---------+---------+
 | Hash::Unique | 10elems-3keys |     87600 |   11.4    |     1      | 3.3e-09 |      20 |
 | ad-hoc       | 10elems-3keys |    140540 |    7.1156 |     1.6044 | 4.6e-11 |      20 |
 | Hash::Unique | 2elems-1key   |    330000 |    3      |     3.7    | 3.3e-09 |      21 |
 | ad-hoc       | 2elems-1key   |    610000 |    1.6    |     7      | 3.3e-09 |      20 |
 +--------------+---------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HashUnique --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Hash::Unique        | 840                          | 4.1                | 20             |       8.2 |                    2.9 |        1   | 3.5e-05 |      21 |
 | perl -e1 (baseline) | 852                          | 4.1                | 20             |       5.3 |                    0   |        1.5 | 3.7e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-HashUnique>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-HashUnique>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-HashUnique>

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
