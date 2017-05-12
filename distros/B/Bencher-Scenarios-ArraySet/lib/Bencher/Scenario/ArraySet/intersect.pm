package Bencher::Scenario::ArraySet::intersect;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark intersect operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_intersect(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'intersection',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'intersection',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);', # $res->as_string
        },
    ],
    datasets => [
        { name => '1_1'  , args => { set1=>[1], set2=>[1] } },

        { name => '10_1' , args => { set1=>[1..10], set2=>[1] } },
        { name => '10_5' , args => { set1=>[1..10], set2=>[1..5] } },
        { name => '10_10', args => { set1=>[1..10], set2=>[1..10] } },

        { name => '100_1'  , args => { set1=>[1..100], set2=>[1] } },
        { name => '100_10' , args => { set1=>[1..100], set2=>[1..10] } },
        { name => '100_100', args => { set1=>[1..100], set2=>[1..100] } },

        { name => '1000_1'   , args => { set1=>[1..1000], set2=>[1] } },
        { name => '1000_10'  , args => { set1=>[1..1000], set2=>[1..10] } },
        { name => '1000_100' , args => { set1=>[1..1000], set2=>[1..100] } },
        { name => '1000_1000', args => { set1=>[1..1000], set2=>[1..1000] } },
    ],
};

1;
# ABSTRACT: Benchmark intersect operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySet::intersect - Benchmark intersect operation

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArraySet::intersect (from Perl distribution Bencher-Scenarios-ArraySet), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySet::intersect

To run module startup overhead benchmark:

 % bencher --module-startup -m ArraySet::intersect

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Set> 0.05

L<Set::Object> 1.35

L<Set::Scalar> 1.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Set::set_intersect (perl_code)

Function call template:

 Array::Set::set_intersect(<set1>, <set2>)



=item * Set::Object::intersection (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);



=item * Set::Scalar::intersection (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->intersection($set2);



=back

=head1 BENCHMARK DATASETS

=over

=item * 1_1

=item * 10_1

=item * 10_5

=item * 10_10

=item * 100_1

=item * 100_10

=item * 100_100

=item * 1000_1

=item * 1000_10

=item * 1000_100

=item * 1000_1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m ArraySet::intersect --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       300 |     3     |       1    | 4.1e-05 |      20 |
 | Set::Scalar::intersection |        |       400 |     2.5   |       1.3  | 1.6e-05 |      23 |
 | Set::Object::intersection |        |      1200 |     0.835 |       4.02 | 4.8e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |      5500 |     0.18  |      18    | 2.5e-07 |      22 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"1000_10"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       320 |     3.1   |        1   | 6.9e-06 |      20 |
 | Set::Scalar::intersection |        |       410 |     2.4   |        1.3 | 3.1e-06 |      20 |
 | Set::Object::intersection |        |      1100 |     0.9   |        3.4 | 3.8e-06 |      32 |
 | Array::Set::set_intersect | 0.05   |      5430 |     0.184 |       16.8 |   5e-08 |      23 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"1000_100"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       290 |     3.4   |        1   | 5.5e-06 |      20 |
 | Set::Scalar::intersection |        |       370 |     2.7   |        1.3 | 3.6e-06 |      20 |
 | Set::Object::intersection |        |      1130 |     0.884 |        3.9 | 6.9e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |      4440 |     0.225 |       15.3 | 2.1e-07 |      21 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"1000_1000"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |       130 |     7.7   |        1   | 1.5e-05 |      21 |
 | Set::Scalar::intersection |        |       250 |     3.9   |        1.9 |   9e-06 |      20 |
 | Set::Object::intersection |        |       850 |     1.2   |        6.5 | 5.8e-06 |      36 |
 | Array::Set::set_intersect | 0.05   |      1480 |     0.677 |       11.3 | 2.7e-07 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"100_1"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |      1900 |       520 |       1    | 3.1e-06 |      20 |
 | Array::Set::set_intersect | 0.02   |      3130 |       319 |       1.62 | 2.3e-07 |      26 |
 | Set::Object::intersection |        |     12000 |        85 |       6.1  | 1.1e-07 |      20 |
 | Array::Set::set_intersect | 0.05   |     60000 |        20 |      30    | 2.5e-07 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"100_10"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |      2100 |       480 |        1   |   2e-06 |      21 |
 | Array::Set::set_intersect | 0.02   |      2800 |       350 |        1.4 | 3.7e-07 |      27 |
 | Set::Object::intersection |        |     12000 |        87 |        5.5 |   1e-07 |      21 |
 | Array::Set::set_intersect | 0.05   |     46000 |        22 |       22   | 5.2e-08 |      21 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"100_100"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_intersect | 0.02   |      1490 |     669   |        1   | 6.4e-07 |      20 |
 | Set::Scalar::intersection |        |      1600 |     640   |        1   | 7.5e-07 |      29 |
 | Set::Object::intersection |        |      9600 |     100   |        6.4 | 1.7e-07 |      30 |
 | Array::Set::set_intersect | 0.05   |     15700 |      63.6 |       10.5 | 2.7e-08 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"10_1"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |      8600 |    120    |       1    | 2.6e-07 |      21 |
 | Array::Set::set_intersect | 0.02   |     25500 |     39.2  |       2.98 | 1.3e-08 |      20 |
 | Set::Object::intersection |        |     83700 |     12    |       9.78 |   1e-08 |      20 |
 | Array::Set::set_intersect | 0.05   |    291000 |      3.44 |      34    | 1.7e-09 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"10_10"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |    7500   |  130      |    1       | 2.5e-07 |      23 |
 | Array::Set::set_intersect | 0.02   |   13954.6 |   71.6607 |    1.85522 |   0     |      20 |
 | Set::Object::intersection |        |   74700   |   13.4    |    9.93    | 5.8e-09 |      26 |
 | Array::Set::set_intersect | 0.05   |  137000   |    7.28   |   18.3     | 3.3e-09 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"10_5"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |      8200 |    120    |     1      | 2.6e-07 |      21 |
 | Array::Set::set_intersect | 0.02   |     18000 |     55    |     2.2    | 1.1e-07 |      29 |
 | Set::Object::intersection |        |     77337 |     12.93 |     9.4076 | 5.8e-11 |      20 |
 | Array::Set::set_intersect | 0.05   |    190000 |      5.2  |    23      | 6.7e-09 |      20 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"1_1"}
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant               | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection |        |     14000 |      72   |        1   | 1.1e-07 |      20 |
 | Array::Set::set_intersect | 0.02   |     91000 |      11   |        6.6 | 1.3e-08 |      22 |
 | Set::Object::intersection |        |    200000 |       5   |       10   | 5.5e-08 |      20 |
 | Array::Set::set_intersect | 0.05   |    430000 |       2.3 |       31   | 6.6e-09 |      26 |
 +---------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ArraySet::intersect --module-startup >>):

 #table12#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Set::Object         | 2                            | 5                  | 20             |        20 |                     13 |        1   |   0.00036 |      20 |
 | Set::Scalar         | 0.82                         | 4.1                | 16             |        17 |                     10 |        1.3 | 7.4e-05   |      20 |
 | Array::Set          | 2                            | 6                  | 20             |        10 |                      3 |        2   |   0.00034 |      20 |
 | perl -e1 (baseline) | 1                            | 4                  | 20             |         7 |                      0 |        3   |   0.00012 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArraySet>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArraySet>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArraySet>

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
