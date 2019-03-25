package Bencher::Scenario::ComparingArrays;

our $DATE = '2019-03-24'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

sub _loop {
    my $a1 = shift;
    my $a2 = shift;
    return 0 unless @$a1 == @$a2;
    for (0..$#{$a1}) { return 0 if $a1->[$_] != $a2->[$_] }
    1;
}

sub _loopstr {
    my $a1 = shift;
    my $a2 = shift;
    return 0 unless @$a1 == @$a2;
    for (0..$#{$a1}) { return 0 if $a1->[$_] ne $a2->[$_] }
    1;
}

our $scenario = {
    summary => 'Modules that compare arrays',
    modules => {
        'Data::Cmp' => 0.002,
    },
    participants => [
        {
            module => 'Data::Cmp',
            fcall_template => 'Data::Cmp::cmp_data(<array1>, <array2>)',
            tags => ["int","str"],
        },
        {
            module => 'Array::Compare',
            code_template => 'Array::Compare->new()->compare(<array1>, <array2>)',
            tags => ["int","str"],
        },
        {
            module => 'Arrays::Same',
            fcall_template => 'Arrays::Same::arrays_same_i(<array1>, <array2>)',
            tags => ["int"],
        },
        {
            module => 'Arrays::Same',
            fcall_template => 'Arrays::Same::arrays_same_s(<array1>, <array2>)',
            tags => ["str"],
        },
        {
            name => 'num eq op loop',
            code_template => __PACKAGE__.'::_loop(<array1>, <array2>)',
            tags => ["int"],
        },
        {
            name => 'str eq op loop',
            code_template => __PACKAGE__.'::_loopstr(<array1>, <array2>)',
            tags => ["str"],
        },
        {
            module => 'Storable',
            func => 'freeze',
            code_template => 'Storable::freeze(<array1>) eq Storable::freeze(<array2>)',
            tags => ["int","str"],
        },
        {
            module => 'Sereal::Encoder',
            func => 'encode_sereal',
            code_template => 'Sereal::Encoder::encode_sereal(<array1>) eq Sereal::Encoder::encode_sereal(<array2>)',
            tags => ["int","str"],
        },
        {
            module => 'Cpanel::JSON::XS',
            func => 'encode_json',
            code_template => 'Cpanel::JSON::XS::encode_json(<array1>) eq Cpanel::JSON::XS::encode_json(<array2>)',
            tags => ["int","str"],
        },
    ],

    datasets => [
        {name=>'empty'        , args=>{array1=>[], array2=>[]}},
        {name=>'10-int-same'  , args=>{array1=>[1..10], array2=>[1..10]}, include_participant_tags=>["int"]},
        {name=>'10-str-same'  , args=>{array1=>[("a")x 10], array2=>[("a")x 10]}, include_participant_tags=>["str"]},
        {name=>'100-int-same' , args=>{array1=>[1..100], array2=>[1..100]}, include_participant_tags=>["int"]},
        {name=>'100-str-same' , args=>{array1=>[("a")x 100], array2=>[("a")x 100]}, include_participant_tags=>["str"]},
        {name=>'1000-int-same', args=>{array1=>[1..1000], array2=>[1..1000]}, include_participant_tags=>["int"]},
        {name=>'1000-str-same', args=>{array1=>[("a")x 1000], array2=>[("a")x 1000]}, include_participant_tags=>["str"]},
    ],
};

1;
# ABSTRACT: Modules that compare arrays

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ComparingArrays - Modules that compare arrays

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ComparingArrays (from Perl distribution Bencher-Scenario-ComparingArrays), released on 2019-03-24.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ComparingArrays

To run module startup overhead benchmark:

 % bencher --module-startup -m ComparingArrays

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Compare> 3.0.2

L<Arrays::Same> 0.002

L<Cpanel::JSON::XS> 3.0239

L<Data::Cmp> 0.006

L<Sereal::Encoder> 4.005

L<Storable> 2.62

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Cmp::cmp_data (perl_code) [int, str]

Function call template:

 Data::Cmp::cmp_data(<array1>, <array2>)



=item * Array::Compare (perl_code) [int, str]

Code template:

 Array::Compare->new()->compare(<array1>, <array2>)



=item * Arrays::Same::arrays_same_i (perl_code) [int]

Function call template:

 Arrays::Same::arrays_same_i(<array1>, <array2>)



=item * Arrays::Same::arrays_same_s (perl_code) [str]

Function call template:

 Arrays::Same::arrays_same_s(<array1>, <array2>)



=item * num eq op loop (perl_code) [int]

Code template:

 Bencher::Scenario::ComparingArrays::_loop(<array1>, <array2>)



=item * str eq op loop (perl_code) [str]

Code template:

 Bencher::Scenario::ComparingArrays::_loopstr(<array1>, <array2>)



=item * Storable (perl_code) [int, str]

Code template:

 Storable::freeze(<array1>) eq Storable::freeze(<array2>)



=item * Sereal::Encoder (perl_code) [int, str]

Code template:

 Sereal::Encoder::encode_sereal(<array1>) eq Sereal::Encoder::encode_sereal(<array2>)



=item * Cpanel::JSON::XS (perl_code) [int, str]

Code template:

 Cpanel::JSON::XS::encode_json(<array1>) eq Cpanel::JSON::XS::encode_json(<array2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * 10-int-same

=item * 10-str-same

=item * 100-int-same

=item * 100-str-same

=item * 1000-int-same

=item * 1000-str-same

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m ComparingArrays >>):

 #table1#
 {dataset=>"10-int-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Array::Compare              | int, str |     44800 |  22.3     |     1      | 6.7e-09 |      20 |
 | Data::Cmp::cmp_data         | int, str |     88400 |  11.3     |     1.97   |   1e-08 |      34 |
 | Storable                    | int, str |    142000 |   7.03    |     3.18   | 2.8e-09 |      28 |
 | num eq op loop              | int      |    520000 |   1.92    |    11.6    | 6.5e-10 |      33 |
 | Sereal::Encoder             | int, str |    599717 |   1.66745 |    13.3943 |   0     |      24 |
 | Cpanel::JSON::XS            | int, str |    670000 |   1.5     |    15      | 1.7e-09 |      20 |
 | Arrays::Same::arrays_same_i | int      |   1210000 |   0.824   |    27.1    | 4.5e-10 |      20 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"10-str-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Array::Compare              | int, str |     43000 |  23       |    1       | 5.3e-08 |      20 |
 | Data::Cmp::cmp_data         | int, str |     81100 |  12.3     |    1.89    | 3.3e-09 |      21 |
 | Storable                    | int, str |    130605 |   7.65669 |    3.03704 |   0     |      20 |
 | str eq op loop              | str      |    348000 |   2.87    |    8.1     | 8.3e-10 |      20 |
 | Cpanel::JSON::XS            | int, str |    420000 |   2.4     |    9.8     | 5.3e-09 |      32 |
 | Sereal::Encoder             | int, str |    430000 |   2.3     |   10       | 3.1e-09 |      23 |
 | Arrays::Same::arrays_same_s | str      |    590000 |   1.7     |   14       | 3.3e-09 |      20 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"100-int-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Data::Cmp::cmp_data         | int, str |     11500 |     87.1  |        1   | 2.7e-08 |      20 |
 | Array::Compare              | int, str |     15000 |     67    |        1.3 | 3.5e-07 |      20 |
 | Storable                    | int, str |     63000 |     16    |        5.5 | 1.1e-07 |      20 |
 | num eq op loop              | int      |     69000 |     15    |        6   | 1.1e-07 |      20 |
 | Cpanel::JSON::XS            | int, str |     90000 |     11    |        7.9 | 1.6e-08 |      23 |
 | Sereal::Encoder             | int, str |    127000 |      7.84 |       11.1 | 3.3e-09 |      20 |
 | Arrays::Same::arrays_same_i | int      |    180000 |      5.5  |       16   | 6.5e-09 |      21 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"100-str-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Data::Cmp::cmp_data         | int, str |   11000   |   94      |    1       |   1e-07 |      21 |
 | Array::Compare              | int, str |   16000   |   63      |    1.5     | 1.1e-07 |      20 |
 | Storable                    | int, str |   37200   |   26.9    |    3.48    | 1.3e-08 |      20 |
 | str eq op loop              | str      |   47175.7 |   21.1973 |    4.41521 |   0     |      20 |
 | Cpanel::JSON::XS            | int, str |   60000   |   17      |    5.6     | 2.7e-08 |      20 |
 | Sereal::Encoder             | int, str |   66000   |   15      |    6.2     | 4.9e-08 |      24 |
 | Arrays::Same::arrays_same_s | str      |   77000   |   13      |    7.2     |   2e-08 |      21 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"1000-int-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Data::Cmp::cmp_data         | int, str |      1200 |     870   |        1   |   2e-06 |      21 |
 | Array::Compare              | int, str |      2100 |     470   |        1.8 | 9.1e-07 |      20 |
 | num eq op loop              | int      |      6900 |     150   |        6   | 2.1e-07 |      20 |
 | Storable                    | int, str |      7400 |     140   |        6.4 | 1.6e-07 |      20 |
 | Cpanel::JSON::XS            | int, str |     10000 |      96   |        9   | 1.1e-07 |      20 |
 | Sereal::Encoder             | int, str |     15000 |      69   |       13   | 2.1e-07 |      20 |
 | Arrays::Same::arrays_same_i | int      |     16500 |      60.5 |       14.4 | 2.7e-08 |      20 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"1000-str-same"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Data::Cmp::cmp_data         | int, str |   1100    |   900     |    1       | 2.7e-06 |      22 |
 | Array::Compare              | int, str |   2180    |   458     |    1.97    | 2.7e-07 |      20 |
 | Storable                    | int, str |   4660    |   215     |    4.21    | 1.8e-07 |      27 |
 | str eq op loop              | str      |   4836.24 |   206.772 |    4.37298 |   0     |      20 |
 | Cpanel::JSON::XS            | int, str |   6539.15 |   152.925 |    5.91276 |   0     |      20 |
 | Sereal::Encoder             | int, str |   7100    |   140     |    6.4     | 2.5e-07 |      23 |
 | Arrays::Same::arrays_same_s | str      |   7800    |   130     |    7       | 2.1e-07 |      20 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"empty"}
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | participant                 | p_tags   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+
 | Array::Compare              | int, str |     57000 |  17       |    1       | 2.7e-08 |      20 |
 | Storable                    | int, str |    173526 |   5.76282 |    3.02255 |   0     |      20 |
 | Data::Cmp::cmp_data         | int, str |    390000 |   2.6     |    6.8     | 3.3e-09 |      20 |
 | Sereal::Encoder             | int, str |   1130000 |   0.888   |   19.6     | 4.1e-10 |      21 |
 | str eq op loop              | str      |   1700000 |   0.6     |   29       | 8.1e-10 |      21 |
 | num eq op loop              | int      |   1800000 |   0.55    |   32       | 2.6e-09 |      21 |
 | Cpanel::JSON::XS            | int, str |   1800000 |   0.55    |   32       | 7.8e-10 |      24 |
 | Arrays::Same::arrays_same_s | str      |   4400000 |   0.23    |   76       | 4.2e-10 |      20 |
 | Arrays::Same::arrays_same_i | int      |   4800000 |   0.21    |   83       | 4.2e-10 |      20 |
 +-----------------------------+----------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ComparingArrays --module-startup >>):

 #table8#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Array::Compare      |      55   |                   49.1 |        1   | 9.8e-05 |      20 |
 | Storable            |      14   |                    8.1 |        4   | 2.5e-05 |      20 |
 | Sereal::Encoder     |      12   |                    6.1 |        4.5 |   2e-05 |      20 |
 | Cpanel::JSON::XS    |      11   |                    5.1 |        4.9 | 1.8e-05 |      20 |
 | Arrays::Same        |      10   |                    4.1 |        5.4 | 1.1e-05 |      24 |
 | Data::Cmp           |       9.5 |                    3.6 |        5.8 | 2.3e-05 |      20 |
 | perl -e1 (baseline) |       5.9 |                    0   |        9.3 | 4.3e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ComparingArrays>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ComparingArrays>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ComparingArrays>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
