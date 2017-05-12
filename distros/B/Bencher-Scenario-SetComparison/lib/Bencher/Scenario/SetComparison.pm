package Bencher::Scenario::SetComparison;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark set comparison',
    participants => [
        {
            module => 'Test::Deep', # Test::Deep::NoTest is useless without importing
            code_template=>'state $set = Test::Deep::set(@{<set>}); Test::Deep::eq_deeply(<array>, $set)',
        },
        {
            module => 'Set::Tiny',
            code_template=>'state $set1 = Set::Tiny->new(@{<array>}); state $set2 = Set::Tiny->new(@{<set>}); $set1->symmetric_difference($set2)->size == 0 ? 1:0',
            tags => ['simple-elements'], # Set::Tiny stringifies arguments
        },
    ],
    datasets => [
        {name=>'elems=10num' , args=>{array=>[1..10] , set=>[reverse 1..10, 1] }},
        {name=>'elems=100num', args=>{array=>[1..100], set=>[reverse 1..100, 1]}},
        {name=>'elems=200num', args=>{array=>[1..200], set=>[reverse 1..200, 1]}},
    ],
};

1;
# ABSTRACT: Benchmark set comparison

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SetComparison - Benchmark set comparison

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::SetComparison (from Perl distribution Bencher-Scenario-SetComparison), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SetComparison

To run module startup overhead benchmark:

 % bencher --module-startup -m SetComparison

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

TODO: include more set modules.

TODO: compare complex elements.

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Test::Deep> 1.120

L<Set::Tiny> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Test::Deep (perl_code)

Code template:

 state $set = Test::Deep::set(@{<set>}); Test::Deep::eq_deeply(<array>, $set)



=item * Set::Tiny (perl_code) [simple-elements]

Code template:

 state $set1 = Set::Tiny->new(@{<array>}); state $set2 = Set::Tiny->new(@{<set>}); $set1->symmetric_difference($set2)->size == 0 ? 1:0



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=10num

=item * elems=100num

=item * elems=200num

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m SetComparison >>):

 #table1#
 +-------------+--------------+-----------+-----------+------------+-----------+---------+
 | participant | dataset      | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------+--------------+-----------+-----------+------------+-----------+---------+
 | Test::Deep  | elems=200num |       5.4 | 180       |          1 |   0.00053 |      20 |
 | Test::Deep  | elems=100num |      22   |  46       |          4 |   0.00031 |      20 |
 | Test::Deep  | elems=10num  |    1900   |   0.53    |        350 | 6.2e-07   |      21 |
 | Set::Tiny   | elems=200num |   17000   |   0.059   |       3100 | 5.6e-07   |      20 |
 | Set::Tiny   | elems=100num |   30000   |   0.03    |       6000 | 3.6e-07   |      25 |
 | Set::Tiny   | elems=10num  |  239000   |   0.00419 |      44100 | 1.7e-09   |      20 |
 +-------------+--------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m SetComparison --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Test::Deep          | 1                            | 4.4                | 16             |      41   |                   36.1 |        1   |   0.00014 |      20 |
 | Set::Tiny           | 0.82                         | 4.1                | 16             |       6.7 |                    1.8 |        6.1 | 2.6e-05   |      20 |
 | perl -e1 (baseline) | 5.2                          | 8.6                | 24             |       4.9 |                    0   |        8.4 | 1.3e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Test::Deep is slow :)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SetComparison>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SetComparison>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SetComparison>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::BagComparison>

L<Bencher::Scenario::SetOperationModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
