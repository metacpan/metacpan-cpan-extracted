package Bencher::Scenario::ArraySet::symdiff;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark symmetric difference operation',
    participants => [
        {
            fcall_template => 'Array::Set::set_symdiff(<set1>, <set2>)',
        },
        {
            module => 'Set::Object',
            function => 'symmetric_difference',
            code_template => 'my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);', # $res->as_string
        },
        {
            module => 'Set::Scalar',
            function => 'symmetric_difference',
            code_template => 'my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);', # $res->as_string
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
# ABSTRACT: Benchmark symmetric difference operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySet::symdiff - Benchmark symmetric difference operation

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArraySet::symdiff (from Perl distribution Bencher-Scenarios-ArraySet), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySet::symdiff

To run module startup overhead benchmark:

 % bencher --module-startup -m ArraySet::symdiff

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

=item * Array::Set::set_symdiff (perl_code)

Function call template:

 Array::Set::set_symdiff(<set1>, <set2>)



=item * Set::Object::symmetric_difference (perl_code)

Code template:

 my $set1 = Set::Object->new; $set1->insert(@{<set1>}); my $set2 = Set::Object->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);



=item * Set::Scalar::symmetric_difference (perl_code)

Code template:

 my $set1 = Set::Scalar->new; $set1->insert(@{<set1>}); my $set2 = Set::Scalar->new; $set2->insert(@{<set2>}); my $res = $set1->symmetric_difference($set2);



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

Benchmark with C<< bencher -m ArraySet::symdiff --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>"1000_1"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       300 |       3.4 |        1   | 1.5e-05 |      20 |
 | Set::Scalar::symmetric_difference |        |       390 |       2.5 |        1.3 | 4.1e-06 |      20 |
 | Set::Object::symmetric_difference |        |       930 |       1.1 |        3.1 | 9.9e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      2000 |       0.7 |        5   | 7.8e-06 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"1000_10"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       300 |       3.3 |        1   | 7.4e-06 |      20 |
 | Set::Scalar::symmetric_difference |        |       410 |       2.5 |        1.4 | 1.1e-05 |      20 |
 | Set::Object::symmetric_difference |        |      1000 |       1   |        3   | 1.1e-05 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1000 |       0.7 |        5   | 1.1e-05 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"1000_100"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |       200 |      4    |        1   |   9e-05 |      20 |
 | Set::Scalar::symmetric_difference |        |       300 |      3    |        1   | 3.8e-05 |      20 |
 | Set::Object::symmetric_difference |        |       930 |      1.1  |        4.1 | 4.9e-06 |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1400 |      0.72 |        6.1 | 5.8e-06 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"1000_1000"}
 +-----------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | participant                       | modver | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | Array::Set::set_symdiff           | 0.02   |       100 |      8    |        1   |   0.00018 |      20 |
 | Set::Scalar::symmetric_difference |        |       240 |      4.1  |        1.9 | 6.9e-06   |      20 |
 | Set::Object::symmetric_difference |        |       800 |      1.3  |        6.4 | 3.8e-06   |      20 |
 | Array::Set::set_symdiff           | 0.05   |      1100 |      0.88 |        9   | 7.4e-06   |      21 |
 +-----------------------------------+--------+-----------+-----------+------------+-----------+---------+

 #table5#
 {dataset=>"100_1"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |    3000   |  330      |    1       | 4.8e-07 |      20 |
 | Set::Scalar::symmetric_difference |        |    3400   |  294      |    1.12    | 2.1e-07 |      20 |
 | Set::Object::symmetric_difference |        |    8600   |  120      |    2.9     | 4.1e-07 |      22 |
 | Array::Set::set_symdiff           | 0.05   |   21501.3 |   46.5088 |    7.09206 |   9e-12 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"100_10"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |      2500 |     400   |       1    | 6.9e-07 |      20 |
 | Set::Scalar::symmetric_difference |        |      3270 |     305   |       1.31 | 2.1e-07 |      20 |
 | Set::Object::symmetric_difference |        |      6000 |     200   |       2    | 5.7e-06 |      29 |
 | Array::Set::set_symdiff           | 0.05   |     20100 |      49.6 |       8.06 |   4e-08 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"100_100"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |    1400   |  700      |     1      | 3.4e-06 |      20 |
 | Set::Scalar::symmetric_difference |        |    2200   |  450      |     1.6    | 3.4e-06 |      20 |
 | Set::Object::symmetric_difference |        |    7200   |  140      |     5.1    | 2.1e-07 |      20 |
 | Array::Set::set_symdiff           | 0.05   |   14478.2 |   69.0691 |    10.1506 | 3.9e-11 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"10_1"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::symmetric_difference |        |     17000 |     60    |       1    | 8.9e-08 |      29 |
 | Array::Set::set_symdiff           | 0.02   |     25000 |     39    |       1.5  |   4e-08 |      20 |
 | Set::Object::symmetric_difference |        |     53000 |     19    |       3.2  |   2e-08 |      20 |
 | Array::Set::set_symdiff           | 0.05   |    136000 |      7.35 |       8.22 | 3.2e-09 |      22 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table9#
 {dataset=>"10_10"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Array::Set::set_symdiff           | 0.02   |     12000 |     83    |       1    | 1.3e-07 |      21 |
 | Set::Scalar::symmetric_difference |        |     13000 |     77    |       1.1  | 6.9e-07 |      20 |
 | Set::Object::symmetric_difference |        |     47000 |     21    |       3.9  |   6e-08 |      20 |
 | Array::Set::set_symdiff           | 0.05   |    119000 |      8.39 |       9.91 |   3e-09 |      25 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table10#
 {dataset=>"10_5"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::symmetric_difference |        |     15000 |     66    |       1    | 9.7e-08 |      24 |
 | Array::Set::set_symdiff           | 0.02   |     16000 |     64    |       1    | 3.4e-07 |      21 |
 | Set::Object::symmetric_difference |        |     30000 |     30    |       2    | 1.3e-06 |      28 |
 | Array::Set::set_symdiff           | 0.05   |    127000 |      7.86 |       8.46 | 2.9e-09 |      29 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+

 #table11#
 {dataset=>"1_1"}
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                       | modver | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::symmetric_difference |        |     27000 |    37     |       1    | 1.3e-08 |      21 |
 | Set::Object::symmetric_difference |        |     70000 |    10     |       3    |   7e-07 |      22 |
 | Array::Set::set_symdiff           | 0.02   |     90000 |    11     |       3.3  | 1.7e-08 |      20 |
 | Array::Set::set_symdiff           | 0.05   |    275800 |     3.625 |      10.21 | 1.4e-10 |      20 |
 +-----------------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ArraySet::symdiff --module-startup >>):

 #table12#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Set::Object         | 1.9                          | 5.2                | 19             |        19 |                     13 |        1   | 6.5e-05   |      20 |
 | Set::Scalar         | 0.82                         | 4.1                | 16             |        17 |                     11 |        1.1 | 3.5e-05   |      21 |
 | Array::Set          | 2                            | 6                  | 20             |        10 |                      4 |        2   |   0.00013 |      20 |
 | perl -e1 (baseline) | 1                            | 4.5                | 16             |         6 |                      0 |        3.2 | 1.8e-05   |      21 |
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
