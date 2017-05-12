package Bencher::Scenario::ArraySet::diff;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark diff operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_diff(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'difference',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'difference',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);', # $res->as_string
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
# ABSTRACT: Benchmark diff operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySet::diff - Benchmark diff operation

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArraySet::diff (from Perl distribution Bencher-Scenarios-ArraySet), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySet::diff

To run module startup overhead benchmark:

 % bencher --module-startup -m ArraySet::diff

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

=item * Array::Set::set_diff (perl_code)

Function call template:

 Array::Set::set_diff(<set1>, <set2>)



=item * Set::Object::difference (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);



=item * Set::Scalar::difference (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->difference($set2);



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

Benchmark with C<< bencher -m ArraySet::diff --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |       340 |     2.9   |       1    | 3.6e-06 |      20 |
 | Set::Scalar::difference |        |       390 |     2.6   |       1.1  | 1.4e-05 |      24 |
 | Set::Object::difference |        |      1300 |     0.78  |       3.7  | 1.3e-06 |      20 |
 | Array::Set::set_diff    | 0.05   |      3210 |     0.312 |       9.32 | 2.7e-07 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"1000_10"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |       237 |     4.22  |        1   | 2.9e-06 |      20 |
 | Set::Scalar::difference |        |       300 |     3     |        1   | 5.4e-05 |      23 |
 | Set::Object::difference |        |      1400 |     0.714 |        5.9 | 6.4e-07 |      20 |
 | Array::Set::set_diff    | 0.05   |      3200 |     0.31  |       14   | 9.6e-07 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"1000_100"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |        55 |     18    |       1    | 3.2e-05 |      20 |
 | Set::Scalar::difference |        |       357 |      2.8  |       6.55 | 2.2e-06 |      20 |
 | Set::Object::difference |        |      1400 |      0.73 |      25    | 7.5e-07 |      20 |
 | Array::Set::set_diff    | 0.05   |      3000 |      0.33 |      55    | 4.8e-07 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"1000_1000"}
 +-------------------------+--------+-----------+-----------+------------+-----------+---------+
 | participant             | modver | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------------------+--------+-----------+-----------+------------+-----------+---------+
 | Array::Set::set_diff    | 0.02   |        10 |    70     |        1   |   0.00073 |      20 |
 | Set::Scalar::difference |        |       254 |     3.94  |       17.6 | 2.2e-06   |      20 |
 | Set::Object::difference |        |      1190 |     0.842 |       82.5 | 6.9e-07   |      20 |
 | Array::Set::set_diff    | 0.05   |      2000 |     0.6   |      100   | 6.2e-06   |      22 |
 +-------------------------+--------+-----------+-----------+------------+-----------+---------+

 #table5#
 {dataset=>"100_1"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |      3100 |     320   |        1   | 1.8e-06 |      26 |
 | Set::Scalar::difference |        |      3400 |     300   |        1.1 | 3.9e-07 |      30 |
 | Set::Object::difference |        |     13000 |      79   |        4.1 | 1.2e-07 |      23 |
 | Array::Set::set_diff    | 0.05   |     32700 |      30.6 |       10.6 | 1.2e-08 |      25 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"100_10"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |      2200 |       460 |       1    | 4.8e-07 |      20 |
 | Set::Scalar::difference |        |      3050 |       327 |       1.41 | 2.7e-07 |      20 |
 | Set::Object::difference |        |     12000 |        81 |       5.7  | 1.2e-07 |      26 |
 | Array::Set::set_diff    | 0.05   |     31000 |        32 |      14    | 5.3e-08 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"100_100"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_diff    | 0.02   |      1000 |    1000   |       1    | 1.7e-05 |      21 |
 | Set::Scalar::difference |        |      1760 |     567   |       1.81 | 2.1e-07 |      20 |
 | Set::Object::difference |        |     11300 |      88.6 |      11.6  |   8e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |     22600 |      44.3 |      23.2  | 1.1e-08 |      28 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"10_1"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::difference |        |     12000 |      86   |        1   |   1e-07 |      22 |
 | Array::Set::set_diff    | 0.02   |     30000 |      34   |        2.5 | 4.6e-08 |      27 |
 | Set::Object::difference |        |     88000 |      11   |        7.6 | 1.3e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |    210000 |       4.8 |       18   | 6.5e-09 |      21 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"10_10"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::difference |        |      8800 |     110   |       1    | 1.8e-07 |      27 |
 | Array::Set::set_diff    | 0.02   |     20500 |      48.8 |       2.33 | 4.6e-08 |      27 |
 | Set::Object::difference |        |     77000 |      13   |       8.7  | 2.7e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |    150000 |       6.9 |      17    | 1.3e-08 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"10_5"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::difference |        |     10000 |     98    |        1   | 1.3e-07 |      21 |
 | Array::Set::set_diff    | 0.02   |     23000 |     44    |        2.2 | 5.2e-08 |      21 |
 | Set::Object::difference |        |     80000 |     13    |        7.8 | 2.3e-08 |      20 |
 | Array::Set::set_diff    | 0.05   |    181000 |      5.52 |       17.7 | 1.3e-09 |      32 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"1_1"}
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant             | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::difference |        |     16000 |     63    |        1   | 9.9e-08 |      23 |
 | Array::Set::set_diff    | 0.02   |    130000 |      7.7  |        8.1 | 1.3e-08 |      20 |
 | Set::Object::difference |        |    240000 |      4.2  |       15   | 9.5e-09 |      22 |
 | Array::Set::set_diff    | 0.05   |    489000 |      2.04 |       30.8 | 8.3e-10 |      20 |
 +-------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ArraySet::diff --module-startup >>):

 #table12#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Set::Object         | 1.91                         | 5.29               | 19.1           |      17.3 |                   11.6 |        1   | 1.1e-05 |      20 |
 | Set::Scalar         | 0.82                         | 4.1                | 16             |      17   |                   11.3 |        1   |   4e-05 |      20 |
 | Array::Set          | 2.2                          | 5.6                | 19             |       9.5 |                    3.8 |        1.8 | 3.6e-05 |      20 |
 | perl -e1 (baseline) | 1                            | 4.4                | 16             |       5.7 |                    0   |        3   | 1.5e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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
