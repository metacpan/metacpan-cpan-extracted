package Bencher::Scenario::RoleTinyCommonsTree::descendants;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use strict;
use warnings;

use Bencher::ScenarioUtil::RoleTinyCommonsTree qw(:all);

our $scenario = {
    summary => 'Benchmark descendants()',
    participants => [
        { fcall_template => 'Code::Includable::Tree::NodeMethods::descendants(<tree>)' },
    ],
    datasets => [
        {
            name=>'h3-o15',
            summary => 'A tree of height 3, 15 objects',
            args => { tree => $tree_h3_o15 },
        },
        {
            name=>'h4-o100',
            summary => 'A tree of height 4, 100 objects',
            args => { tree => $tree_h4_o100 },
        },
        {
            name=>'h6-o1k',
            summary => 'A tree of height 6, 1k objects',
            args => { tree => $tree_h6_o1k },
        },
        {
            name=>'h7-o20k',
            summary => 'A tree of height 7, ~20k objects',
            args => { tree => $tree_h7_o20k },
        },
    ],
};

1;
# ABSTRACT: Benchmark descendants()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RoleTinyCommonsTree::descendants - Benchmark descendants()

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::RoleTinyCommonsTree::descendants (from Perl distribution Bencher-Scenarios-RoleTinyCommonsTree), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RoleTinyCommonsTree::descendants

To run module startup overhead benchmark:

 % bencher --module-startup -m RoleTinyCommonsTree::descendants

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Code::Includable::Tree::NodeMethods> 0.11

=head1 BENCHMARK PARTICIPANTS

=over

=item * Code::Includable::Tree::NodeMethods::descendants (perl_code)

Function call template:

 Code::Includable::Tree::NodeMethods::descendants(<tree>)



=back

=head1 BENCHMARK DATASETS

=over

=item * h3-o15

A tree of height 3, 15 objects

=item * h4-o100

A tree of height 4, 100 objects

=item * h6-o1k

A tree of height 6, 1k objects

=item * h7-o20k

A tree of height 7, ~20k objects

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RoleTinyCommonsTree::descendants >>):

 #table1#
 +---------+-----------+-----------+------------+----------+---------+
 | dataset | rate (/s) | time (ms) | vs_slowest |  errors  | samples |
 +---------+-----------+-----------+------------+----------+---------+
 | h7-o20k |        14 |    70     |          1 |   0.0001 |      22 |
 | h6-o1k  |       410 |     2.5   |         29 | 1.2e-05  |      20 |
 | h4-o100 |      3890 |     0.257 |        274 | 2.1e-07  |      20 |
 | h3-o15  |     27000 |     0.038 |       1900 | 1.5e-07  |      23 |
 +---------+-----------+-----------+------------+----------+---------+


Benchmark module startup overhead (C<< bencher -m RoleTinyCommonsTree::descendants --module-startup >>):

 #table2#
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Code::Includable::Tree::NodeMethods | 0.83                         | 4.2                | 16             |        16 |                      5 |        1   | 6.4e-05 |      20 |
 | perl -e1 (baseline)                 | 1.2                          | 4.6                | 18             |        11 |                      0 |        1.5 | 3.8e-05 |      20 |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RoleTinyCommonsTree>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RoleTinyCommonsTree>

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
