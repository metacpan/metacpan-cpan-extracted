package Bencher::Scenario::BagComparison;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark bag comparison',
    participants => [
        {
            module => 'Test::Deep', # Test::Deep::NoTest is useless without importing
            code_template=>'state $bag = Test::Deep::bag(@{<bag>}); Test::Deep::eq_deeply(<array>, $bag)',
        },
    ],
    datasets => [
        {name=>'elems=10num' , args=>{array=>[1..10] , bag=>[reverse 1..10] }},
        {name=>'elems=100num', args=>{array=>[1..100], bag=>[reverse 1..100]}},
        {name=>'elems=200num', args=>{array=>[1..200], bag=>[reverse 1..200]}},
    ],
};

1;
# ABSTRACT: Benchmark bag comparison

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BagComparison - Benchmark bag comparison

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::BagComparison (from Perl distribution Bencher-Scenario-BagComparison), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BagComparison

To run module startup overhead benchmark:

 % bencher --module-startup -m BagComparison

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

TODO: find another bag comparison module.

TODO: compare complex elements.

TODO: compare with Data::Compare + sorting.

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Test::Deep> 1.120

=head1 BENCHMARK PARTICIPANTS

=over

=item * Test::Deep (perl_code)

Code template:

 state $bag = Test::Deep::bag(@{<bag>}); Test::Deep::eq_deeply(<array>, $bag)



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=10num

=item * elems=100num

=item * elems=200num

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m BagComparison >>):

 #table1#
 +--------------+-----------+-----------+------------+-----------+---------+
 | dataset      | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +--------------+-----------+-----------+------------+-----------+---------+
 | elems=200num |        11 |    89     |        1   |   0.00013 |      21 |
 | elems=100num |        25 |    39     |        2.3 | 4.2e-05   |      20 |
 | elems=10num  |      2420 |     0.414 |      216   | 3.9e-07   |      24 |
 +--------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m BagComparison --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Test::Deep          | 0.82                         | 4                  | 16             |      41   |                   35.3 |        1   | 7.4e-05 |      20 |
 | perl -e1 (baseline) | 5.2                          | 8.7                | 24             |       5.7 |                    0   |        7.2 | 7.1e-06 |      22 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BagComparison>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BagComparison>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-BagComparison>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::SetComparison>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
