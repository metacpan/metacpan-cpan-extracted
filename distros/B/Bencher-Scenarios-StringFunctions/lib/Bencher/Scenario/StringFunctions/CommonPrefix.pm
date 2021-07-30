package Bencher::Scenario::StringFunctions::CommonPrefix;

our $DATE = '2021-07-30'; # DATE
our $VERSION = '0.004'; # VERSION

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

This document describes version 0.004 of Bencher::Scenario::StringFunctions::CommonPrefix (from Perl distribution Bencher-Scenarios-StringFunctions), released on 2021-07-30.

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m StringFunctions::CommonPrefix >>):

 #table1#
 {dataset=>"elems0"}
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset | ds_tags | p_tags | perl | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems0  |         |        | perl |   9053000 |     110.5 |                 0.00% |                 0.00% | 4.6e-12 |      20 |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

          Rate     
     9053000/s  -- 
 
 Legends:
   : dataset=elems0 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table2#
 {dataset=>"elems1"}
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | participant                         | dataset | ds_tags | p_tags | perl | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest | errors | samples |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | String::CommonPrefix::common_prefix | elems1  |         |        | perl |   2509000 |     398.6 |                 0.00% |                 0.00% |  5e-12 |      20 |
 +-------------------------------------+---------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

          Rate     
     2509000/s  -- 
 
 Legends:
   : dataset=elems1 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table3#
 {dataset=>"elems1000prefix0"}
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset          | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems1000prefix0 |         |        | perl |      5570 |       179 |                 0.00% |                 0.00% | 5.3e-08 |      20 |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

       Rate     
     5570/s  -- 
 
 Legends:
   : dataset=elems1000prefix0 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table4#
 {dataset=>"elems1000prefix1"}
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset          | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems1000prefix1 |         |        | perl |   4850.76 |   206.153 |                 0.00% |                 0.00% | 2.1e-11 |      20 |
 +-------------------------------------+------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

          Rate     
     4850.76/s  -- 
 
 Legends:
   : dataset=elems1000prefix1 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table5#
 {dataset=>"elems100prefix0"}
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset         | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems100prefix0 |         |        | perl |     54800 |      18.3 |                 0.00% |                 0.00% | 6.4e-09 |      22 |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

        Rate     
     54800/s  -- 
 
 Legends:
   : dataset=elems100prefix0 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table6#
 {dataset=>"elems100prefix1"}
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset         | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems100prefix1 |         |        | perl |     47193 |    21.189 |                 0.00% |                 0.00% | 2.1e-11 |      32 |
 +-------------------------------------+-----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

        Rate     
     47193/s  -- 
 
 Legends:
   : dataset=elems100prefix1 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table7#
 {dataset=>"elems10prefix0"}
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset        | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems10prefix0 |         |        | perl |    465000 |      2.15 |                 0.00% |                 0.00% | 8.3e-10 |      20 |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

         Rate     
     465000/s  -- 
 
 Legends:
   : dataset=elems10prefix0 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl

 #table8#
 {dataset=>"elems10prefix1"}
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                         | dataset        | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix::common_prefix | elems10prefix1 |         |        | perl |    396800 |    2.5202 |                 0.00% |                 0.00% | 5.3e-12 |      20 |
 +-------------------------------------+----------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

         Rate     
     396800/s  -- 
 
 Legends:
   : dataset=elems10prefix1 ds_tags= p_tags= participant=String::CommonPrefix::common_prefix perl=perl


Benchmark module startup overhead (C<< bencher -m StringFunctions::CommonPrefix --module-startup >>):

 #table9#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | String::CommonPrefix |         8 |                 4 |                 0.00% |               119.08% | 0.00015 |      20 |
 | perl -e1 (baseline)  |         4 |                 0 |               119.08% |                 0.00% | 0.00014 |      31 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                Rate   S:C  :perl -e1 ( 
  S:C          0.1/s    --         -50% 
  :perl -e1 (  0.2/s  100%           -- 
 
 Legends:
   :perl -e1 (: mod_overhead_time=0 participant=perl -e1 (baseline)
   S:C: mod_overhead_time=4 participant=String::CommonPrefix

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
