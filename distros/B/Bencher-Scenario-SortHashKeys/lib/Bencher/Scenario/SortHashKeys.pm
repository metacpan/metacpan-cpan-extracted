package Bencher::Scenario::SortHashKeys;

our $DATE = '2017-05-24'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Sort::HashKeys',
    participants => [
        {
            name => 'map',
            code_template => 'state $h = <hash>; map {($_, $h->{$_})} sort keys %$h',
            result_is_list => 1,
        },
        {
            module => 'Sort::HashKeys',
            function => 'sort',
            code_template => 'state $h = <hash>; Sort::HashKeys::sort(%$h)',
            result_is_list => 1,
        },
    ],
    datasets => [
        {name=>'2key'  , args=>{hash=>{map {$_=>1} 1..  2}} },
        {name=>'10key' , args=>{hash=>{map {$_=>1} 1.. 10}} },
        {name=>'100key', args=>{hash=>{map {$_=>1} 1..100}} },
    ],
};

1;
# ABSTRACT: Benchmark Sort::HashKeys

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SortHashKeys - Benchmark Sort::HashKeys

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::SortHashKeys (from Perl distribution Bencher-Scenario-SortHashKeys), released on 2017-05-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SortHashKeys

To run module startup overhead benchmark:

 % bencher --module-startup -m SortHashKeys

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::HashKeys> 0.007

=head1 BENCHMARK PARTICIPANTS

=over

=item * map (perl_code)

Code template:

 state $h = <hash>; map {($_, $h->{$_})} sort keys %$h



=item * Sort::HashKeys::sort (perl_code)

Code template:

 state $h = <hash>; Sort::HashKeys::sort(%$h)



=back

=head1 BENCHMARK DATASETS

=over

=item * 2key

=item * 10key

=item * 100key

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m SortHashKeys >>):

 #table1#
 +----------------------+---------+-----------+-----------+------------+---------+---------+
 | participant          | dataset | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------+---------+-----------+-----------+------------+---------+---------+
 | map                  | 100key  |     47500 |   21      |      1     | 6.7e-09 |      20 |
 | Sort::HashKeys::sort | 100key  |     56500 |   17.7    |      1.19  | 6.1e-09 |      24 |
 | map                  | 10key   |    553600 |    1.806  |     11.65  | 4.3e-11 |      20 |
 | Sort::HashKeys::sort | 10key   |    848670 |    1.1783 |     17.859 | 1.1e-11 |      20 |
 | map                  | 2key    |   2121000 |    0.4714 |     44.64  | 4.6e-11 |      20 |
 | Sort::HashKeys::sort | 2key    |   3600000 |    0.27   |     77     | 4.2e-10 |      20 |
 +----------------------+---------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SortHashKeys --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Sort::HashKeys      | 904                          | 4.2                | 18             |       7.4 |                    2.5 |        1   | 6.8e-05 |      20 |
 | perl -e1 (baseline) | 840                          | 4.1                | 16             |       4.9 |                    0   |        1.5 | 1.2e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SortHashKeys>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SortHashKeys>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SortHashKeys>

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
