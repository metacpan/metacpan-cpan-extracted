package Bencher::Scenario::ArraySet::union;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark union operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_union(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'union',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'union',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);', # $res->as_string
        },
    ],
    datasets => [
        { name => '1_1'  , args => { set1=>[1], set2=>[1] } },

        { name => '10_1' , args => { set1=>[1..10], set2=>[1] } },
        { name => '10_5' , args => { set1=>[1..10], set2=>[3..7] } },
        { name => '10_10', args => { set1=>[1..10], set2=>[1..10] } },

        { name => '100_1'  , args => { set1=>[1..100], set2=>[1] } },
        { name => '100_10' , args => { set1=>[1..100], set2=>[96..105] } },
        { name => '100_100', args => { set1=>[1..100], set2=>[1..100] } },

        { name => '1000_1'   , args => { set1=>[1..1000], set2=>[1] } },
        { name => '1000_10'  , args => { set1=>[1..1000], set2=>[996..1005] } },
        { name => '1000_100' , args => { set1=>[1..1000], set2=>[951..1050] } },
        { name => '1000_1000', args => { set1=>[1..1000], set2=>[1..1000] } },
    ],
};

1;
# ABSTRACT: Benchmark union operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySet::union - Benchmark union operation

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArraySet::union (from Perl distribution Bencher-Scenarios-ArraySet), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySet::union

To run module startup overhead benchmark:

 % bencher --module-startup -m ArraySet::union

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

=item * Array::Set::set_union (perl_code)

Function call template:

 Array::Set::set_union(<set1>, <set2>)



=item * Set::Object::union (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);



=item * Set::Scalar::union (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->union($set2);



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

Benchmark with C<< bencher -m ArraySet::union --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |       290 |      3.5  |        1   | 5.5e-06 |      22 |
 | Array::Set::set_union | 0.02   |       300 |      3.4  |        1   | 1.9e-05 |      20 |
 | Array::Set::set_union | 0.05   |      1600 |      0.63 |        5.5 | 3.1e-06 |      20 |
 | Set::Object::union    |        |      2100 |      0.48 |        7.2 | 6.4e-07 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"1000_10"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |       300 |      4    |        1   | 7.1e-05 |      20 |
 | Array::Set::set_union | 0.02   |       330 |      3.1  |        1.3 | 1.7e-05 |      20 |
 | Array::Set::set_union | 0.05   |      1600 |      0.63 |        6.3 | 3.8e-06 |      20 |
 | Set::Object::union    |        |      2000 |      0.5  |        7.9 | 1.3e-06 |      22 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"1000_100"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |       230 |      4.4  |       1    | 2.6e-05 |      20 |
 | Array::Set::set_union | 0.02   |       296 |      3.37 |       1.32 | 2.3e-06 |      20 |
 | Array::Set::set_union | 0.05   |      2000 |      0.6  |       7    | 1.1e-05 |      21 |
 | Set::Object::union    |        |      1700 |      0.59 |       7.5  |   3e-06 |      22 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"1000_1000"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |       150 |     6.7   |       1    | 2.7e-05 |      20 |
 | Array::Set::set_union | 0.02   |       200 |     5.1   |       1.3  | 8.9e-06 |      21 |
 | Set::Object::union    |        |      1020 |     0.979 |       6.87 | 5.7e-07 |      25 |
 | Array::Set::set_union | 0.05   |      1100 |     0.9   |       7.5  | 8.3e-06 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"100_1"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |      2500 |       400 |        1   | 4.3e-07 |      20 |
 | Array::Set::set_union | 0.02   |      3100 |       320 |        1.2 |   6e-07 |      23 |
 | Set::Object::union    |        |     19000 |        52 |        7.7 | 1.1e-07 |      20 |
 | Array::Set::set_union | 0.05   |     20000 |        51 |        7.9 | 1.1e-07 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"100_10"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |      2300 |   440     |     1      | 1.3e-06 |      20 |
 | Array::Set::set_union | 0.02   |      2900 |   350     |     1.3    | 4.8e-07 |      20 |
 | Set::Object::union    |        |     18000 |    57     |     7.7    | 1.1e-07 |      20 |
 | Array::Set::set_union | 0.05   |     18566 |    53.863 |     8.1464 | 1.4e-10 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"100_100"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |      1610 |       619 |        1   | 5.6e-07 |      26 |
 | Array::Set::set_union | 0.02   |      1900 |       530 |        1.2 | 9.1e-07 |      20 |
 | Set::Object::union    |        |     11000 |        92 |        6.7 | 1.1e-07 |      30 |
 | Array::Set::set_union | 0.05   |     14000 |        70 |        8.9 | 1.1e-07 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"10_1"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |     10000 |  100      |    1       | 1.3e-07 |      20 |
 | Array::Set::set_union | 0.02   |     26591 |   37.6068 |    2.65084 |   0     |      21 |
 | Set::Object::union    |        |    111000 |    8.99   |   11.1     | 3.5e-09 |      23 |
 | Array::Set::set_union | 0.05   |    140000 |    7.2    |   14       | 1.3e-08 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"10_10"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |    8500   |  120      |    1       | 2.3e-07 |      28 |
 | Array::Set::set_union | 0.02   |   17625.5 |   56.7358 |    2.07035 |   0     |      22 |
 | Set::Object::union    |        |   82000   |   12      |    9.7     | 1.3e-08 |      20 |
 | Array::Set::set_union | 0.05   |  110000   |    9.1    |   13       |   4e-08 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"10_5"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |      9200 |    110    |       1    | 2.4e-07 |      25 |
 | Array::Set::set_union | 0.02   |     21800 |     45.8  |       2.36 | 1.3e-08 |      20 |
 | Set::Object::union    |        |     95190 |     10.51 |      10.32 | 9.8e-10 |      21 |
 | Array::Set::set_union | 0.05   |    120000 |      8.1  |      13    | 1.3e-08 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"1_1"}
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | participant           | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union    |        |     15000 |      65   |        1   | 8.2e-08 |      34 |
 | Array::Set::set_union | 0.02   |    100000 |       9.6 |        6.8 | 1.3e-08 |      20 |
 | Set::Object::union    |        |    200000 |       4.9 |       13   | 6.6e-09 |      21 |
 | Array::Set::set_union | 0.05   |    330000 |       3   |       22   | 3.3e-09 |      20 |
 +-----------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ArraySet::union --module-startup >>):

 #table12#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Set::Object         | 1.9                          | 5.3                | 19             |        19 |                     13 |        1   |   0.00013 |      20 |
 | Set::Scalar         | 0.82                         | 4.1                | 16             |        17 |                     11 |        1.1 | 4.5e-05   |      20 |
 | Array::Set          | 2.2                          | 5.7                | 19             |        10 |                      4 |        1.9 | 4.3e-05   |      22 |
 | perl -e1 (baseline) | 1                            | 4                  | 20             |         6 |                      0 |        3   | 8.8e-05   |      20 |
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
