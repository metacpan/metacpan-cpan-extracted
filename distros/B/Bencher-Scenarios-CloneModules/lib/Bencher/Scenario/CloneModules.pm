package Bencher::Scenario::CloneModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various data cloning modules',
    participants => [
        {fcall_template=>'Clone::clone(<data>)'},
        {fcall_template=>'Clone::PP::clone(<data>)'},
        {fcall_template=>'Data::Clone::clone(<data>)'},
        {fcall_template=>'Sereal::Dclone::dclone(<data>)'},
        {fcall_template=>'Storable::dclone(<data>)'},
    ],
    datasets => [
        {name=>'array0'   , args=>{data=>[]}},
        {name=>'array1'   , args=>{data=>[1]}},
        {name=>'array10'  , args=>{data=>[1..10]}},
        {name=>'array100' , args=>{data=>[1..100]}},
        {name=>'array1k'  , args=>{data=>[1..1000]}},
        {name=>'array10k' , args=>{data=>[1..10_000]}},

        {name=>'hash1k'   , args=>{data=>{map {$_=>1} 1..1000}}},
        {name=>'hash10k'  , args=>{data=>{map {$_=>1} 1..10_000}}},
    ],
};

1;
# ABSTRACT: Benchmark various data cloning modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::CloneModules - Benchmark various data cloning modules

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::CloneModules (from Perl distribution Bencher-Scenarios-CloneModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CloneModules

To run module startup overhead benchmark:

 % bencher --module-startup -m CloneModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Clone> 0.38

L<Clone::PP> 1.06

L<Data::Clone> 0.004

L<Sereal::Dclone> 0.002

L<Storable> 2.56

=head1 BENCHMARK PARTICIPANTS

=over

=item * Clone::clone (perl_code)

Function call template:

 Clone::clone(<data>)



=item * Clone::PP::clone (perl_code)

Function call template:

 Clone::PP::clone(<data>)



=item * Data::Clone::clone (perl_code)

Function call template:

 Data::Clone::clone(<data>)



=item * Sereal::Dclone::dclone (perl_code)

Function call template:

 Sereal::Dclone::dclone(<data>)



=item * Storable::dclone (perl_code)

Function call template:

 Storable::dclone(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * array0

=item * array1

=item * array10

=item * array100

=item * array1k

=item * array10k

=item * hash1k

=item * hash10k

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark cloning a 10k-element array (C<< bencher -m CloneModules --include-datasets array10k >>):

 #table1#
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | Clone::clone           |       240 |     4.2   |       1    | 3.5e-05 |      20 |
 | Clone::PP::clone       |       796 |     1.26  |       3.32 | 1.1e-06 |      20 |
 | Storable::dclone       |       900 |     1     |       4    | 1.7e-05 |      20 |
 | Sereal::Dclone::dclone |      1970 |     0.508 |       8.21 | 2.7e-07 |      20 |
 | Data::Clone::clone     |      2000 |     0.5   |       8.33 | 4.3e-07 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+


Benchmark cloning a 10k-pair hash (C<< bencher -m CloneModules --include-datasets hash10k >>):

 #table2#
 +------------------------+-----------+-----------+------------+---------+---------+
 | participant            | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------------+-----------+-----------+------------+---------+---------+
 | Clone::clone           |       100 |      10   |        1   | 4.9e-05 |      21 |
 | Clone::PP::clone       |       120 |       8.3 |        1.2 |   6e-05 |      20 |
 | Storable::dclone       |       180 |       5.6 |        1.8 | 9.6e-06 |      20 |
 | Data::Clone::clone     |       180 |       5.4 |        1.8 | 3.7e-05 |      20 |
 | Sereal::Dclone::dclone |       220 |       4.6 |        2.2 | 2.2e-05 |      20 |
 +------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m CloneModules --module-startup >>):

 #table3#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Storable            | 0.82                         | 4                  | 16             |      16   |                    9.9 |        1   | 6.3e-05   |      20 |
 | Sereal::Dclone      | 1.8                          | 5.3                | 21             |      15   |                    8.9 |        1   | 8.3e-05   |      21 |
 | Clone               | 1                            | 4.4                | 16             |      14   |                    7.9 |        1.1 |   0.00012 |      20 |
 | Data::Clone         | 1.5                          | 5.2                | 21             |      11   |                    4.9 |        1.5 | 4.5e-05   |      20 |
 | Clone::PP           | 1.1                          | 4.5                | 18             |      10   |                    3.9 |        1.5 | 4.2e-05   |      20 |
 | perl -e1 (baseline) | 1.3                          | 4.6                | 18             |       6.1 |                    0   |        2.5 | 1.5e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CloneModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CloneModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CloneModules>

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
