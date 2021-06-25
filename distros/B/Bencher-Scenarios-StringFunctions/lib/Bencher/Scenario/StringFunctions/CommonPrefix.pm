package Bencher::Scenario::StringFunctions::CommonPrefix;

our $DATE = '2021-06-23'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark calculating common prefix",
    participants => [
        {fcall_template=>'String::CommonPrefix::common_prefix(@{<strings>})'},
    ],
    datasets => [
        {name=>'elems0'          , args=>{strings=>[]}},
        {name=>'elems1'          , args=>{strings=>['x']}},
        {name=>'elems10prefix0'  , args=>{strings=>[map{sprintf "%02d", $_} 1..10]}},
        {name=>'elems10prefix1'  , args=>{strings=>[map{sprintf "%02d", $_} 0..9]}},
        {name=>'elems100prefix0' , args=>{strings=>[map{sprintf "%03d", $_} 1..100]}},
        {name=>'elems100prefix1' , args=>{strings=>[map{sprintf "%03d", $_} 0..99]}},
        {name=>'elems1000prefix0', args=>{strings=>[map{sprintf "%04d", $_} 1..1000]}},
        {name=>'elems1000prefix1', args=>{strings=>[map{sprintf "%04d", $_} 0..999]}},
    ],
};

1;
# ABSTRACT: Benchmark calculating common prefix

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::StringFunctions::CommonPrefix - Benchmark calculating common prefix

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::StringFunctions::CommonPrefix (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-06-23.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m StringFunctions::CommonPrefix

To run module startup overhead benchmark:

 % bencher --module-startup -m StringFunctions::CommonPrefix

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<String::CommonPrefix> 0.01

=head1 BENCHMARK PARTICIPANTS

=over

=item * String::CommonPrefix::common_prefix (perl_code)

Function call template:

 String::CommonPrefix::common_prefix(@{<strings>})



=back

=head1 BENCHMARK DATASETS

=over

=item * elems0

=item * elems1

=item * elems10prefix0

=item * elems10prefix1

=item * elems100prefix0

=item * elems100prefix1

=item * elems1000prefix0

=item * elems1000prefix1

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::CommonPrefix >>):

 #table1#
 {dataset=>"elems0"}
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset | ds_tags | p_tags | perl | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems0  |         |        | perl |   7000000 |       100 |                 0.00% |                 0.00% | 1.9e-09 |      27 |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table2#
 {dataset=>"elems1"}
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset | ds_tags | p_tags | perl | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems1  |         |        | perl |   2090000 |       479 |                 0.00% |                 0.00% | 2.1e-10 |      20 |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table3#
 {dataset=>"elems1000prefix0"}
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset          | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems1000prefix0 |         |        | perl |      4400 |       230 |                 0.00% |                 0.00% | 2.7e-07 |      20 |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table4#
 {dataset=>"elems1000prefix1"}
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset          | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems1000prefix1 |         |        | perl |      3810 |       263 |                 0.00% |                 0.00% | 2.6e-07 |      21 |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table5#
 {dataset=>"elems100prefix0"}
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset         | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems100prefix0 |         |        | perl |     43401 |    23.041 |                 0.00% |                 0.00% | 3.3e-11 |      20 |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table6#
 {dataset=>"elems100prefix1"}
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | participant                         | dataset         | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest | errors | samples |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | String::CommonPrefix::common_prefix | elems100prefix1 |         |        | perl |     37300 |      26.8 |                 0.00% |                 0.00% |  1e-08 |      34 |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+

 #table7#
 {dataset=>"elems10prefix0"}
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset        | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems10prefix0 |         |        | perl |    370000 |     2.703 |                 0.00% |                 0.00% | 4.4e-11 |      20 |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

 #table8#
 {dataset=>"elems10prefix1"}
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset        | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems10prefix1 |         |        | perl |    300000 |         3 |                 0.00% |                 0.00% | 4.2e-08 |      20 |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m StringFunctions::CommonPrefix --module-startup >>):

 #table9#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix |       8.7 |               2.6 |                 0.00% |                42.51% | 8.7e-06 |      20 |
 | perl -e1 (baseline)  |       6.1 |               0   |                42.51% |                 0.00% | 2.5e-05 |      20 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-StringFunctions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-StringFunctions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-StringFunctions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
