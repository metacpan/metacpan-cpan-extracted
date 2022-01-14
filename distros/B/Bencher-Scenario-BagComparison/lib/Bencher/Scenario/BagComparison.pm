package Bencher::Scenario::BagComparison;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.005'; # VERSION

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

This document describes version 0.005 of Bencher::Scenario::BagComparison (from Perl distribution Bencher-Scenario-BagComparison), released on 2021-07-31.

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

L<Test::Deep> 1.130

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

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m BagComparison

Result formatted as table:

 #table1#
 | dataset      | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |--------------+-----------+-----------+-----------------------+-----------------------+---------+---------|
 | elems=200num |      14.5 |     69    |                 0.00% |             21844.48% | 4.7e-05 |      20 |
 | elems=100num |      33   |     30    |               128.97% |              9483.95% | 4.1e-05 |      20 |
 | elems=10num  |    3200   |      0.31 |             21844.48% |                 0.00% | 4.3e-07 |      20 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                  Rate  elems=200num  elems=100num  elems=10num 
  elems=200num  14.5/s            --          -56%         -99% 
  elems=100num    33/s          129%            --         -98% 
  elems=10num   3200/s        22158%         9577%           -- 
 
 Legends:
   elems=100num: dataset=elems=100num
   elems=10num: dataset=elems=10num
   elems=200num: dataset=elems=200num

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m BagComparison --module-startup

Result formatted as table:

 #table2#
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 |---------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------|
 | Test::Deep          |      45   |              40.1 |                 0.00% |               817.50% |   0.00019 |      20 |
 | perl -e1 (baseline) |       4.9 |               0   |               817.50% |                 0.00% | 2.2e-05   |      21 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate   T:D  perl -e1 (baseline) 
  T:D                   22.2/s    --                 -89% 
  perl -e1 (baseline)  204.1/s  818%                   -- 
 
 Legends:
   T:D: mod_overhead_time=40.1 participant=Test::Deep
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (@pc-office)

perlancar (@pc-office) <perlancar@gmail.com>

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

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
