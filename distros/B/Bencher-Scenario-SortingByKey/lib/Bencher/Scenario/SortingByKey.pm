package Bencher::Scenario::SortingByKey;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-25'; # DATE
our $DIST = 'Bencher-Scenario-SortingByKey'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various techniques to sort array by some computed key',
    participants => [

        {
            name => 'uncached',
            description => <<'_',

This technique does not cache the sort key and computes it everytime they are
compared. This performance of this technique depends on how expensive the
computation of key is. (In this benchmark, the computation is very cheap.)

In Perl code:

    @sorted = sort { GEN_KEY($a) cmp GEN_KEY($b) } @array;

_
            code_template => 'state $array=<array>; sort { -$a <=> -$b } @$array', result_is_list=>1,
        },

        {
            name => 'ST',
            description => <<'_',

Schwartzian transform (also known as map/sort/map technique) caches the sort key
in an arrayref. It works by constructing, for each array element, a container
record (most often anonymous arrayref) containing the original element and the
key to be sorted. Later after the sort, it discards the anonymous arrayrefs. The
arrayref construction is a significant part of the total cost, especially for
larger arrays.

In Perl code:

    @sorted = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, GEN_KEY($_)] } @array;

_
            code_template => 'state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array', result_is_list=>1,
        },

        {
            name => 'GRT',
            description => <<'_',

Guttman-Rosler transform, another map/sort/map technique, is similar to ST. The
difference is, the computed key is transformed into a fixed-length string that
can be compared lexicographically (thus eliminating the need for the Perl custom
sort block). The original element is also transformed as a string and
concatenated into the string. Thus, GRT avoids the construction of the anonymous
arrayrefs. As a downside, the construction of the key string can be tricky.

In Perl code (assuming the compute key is transformed into a fixed 4-byte
string:

    @sorted = map { substr($_, 4) } sort map { pack("NN", -$_, $_) } @array;

_
            code_template => 'state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array',
            result_is_list=>1,
        },

        {
            name => '2array',
            description => <<'_',

This technique caches the compute key in a single array. It also constructs an
array of indexes, sorts the array according to the array keys, then constructs
the final sorted array using the sorted indexes.

Compared to GRT, it constructs far fewer anonymous arrayrefs. But it still
requires Perl custom sort block.

In Perl code:

    @indexes = 0 .. $#array;
    @keys    = map { GEN_KEY($_) } @array;
    @sorted  = map { $array[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes;

_
            code_template => 'state $array=<array>; my @keys = map { -$_ } @$array; my @indexes = 0..$#{$array}; map { $array->[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes',
            result_is_list=>1,
        },

        {
            name => 'Sort::Key::nkeysort',
            module => 'Sort::Key',
            function => 'nkeysort',
            description => <<'_',

This module also caches the compute keys. It's faster because it's implemented
in XS. The compute key must be string (to be compared lexicographically) or
numeric.

_
            code_template => 'state $array=<array>; Sort::Key::nkeysort(sub { -$_ }, @$array)',
            result_is_list => 1,
        },


    ],
    datasets => [
        {name=>'10'   , args=>{array=>[map {int(   10*rand)} 1..10   ]}},
        {name=>'100'  , args=>{array=>[map {int(  100*rand)} 1..100  ]}},
        {name=>'1000' , args=>{array=>[map {int( 1000*rand)} 1..1000 ]}},
        {name=>'10000', args=>{array=>[map {int(10000*rand)} 1..10000]}},
    ],
};

1;
# ABSTRACT: Benchmark various techniques to sort array by some computed key

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SortingByKey - Benchmark various techniques to sort array by some computed key

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::SortingByKey (from Perl distribution Bencher-Scenario-SortingByKey), released on 2019-12-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SortingByKey

To run module startup overhead benchmark:

 % bencher --module-startup -m SortingByKey

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Sort::Key> 1.33

=head1 BENCHMARK PARTICIPANTS

=over

=item * uncached (perl_code)

Code template:

 state $array=<array>; sort { -$a <=> -$b } @$array

This technique does not cache the sort key and computes it everytime they are
compared. This performance of this technique depends on how expensive the
computation of key is. (In this benchmark, the computation is very cheap.)

In Perl code:

 @sorted = sort { GEN_KEY($a) cmp GEN_KEY($b) } @array;




=item * ST (perl_code)

Code template:

 state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array

Schwartzian transform (also known as map/sort/map technique) caches the sort key
in an arrayref. It works by constructing, for each array element, a container
record (most often anonymous arrayref) containing the original element and the
key to be sorted. Later after the sort, it discards the anonymous arrayrefs. The
arrayref construction is a significant part of the total cost, especially for
larger arrays.

In Perl code:

 @sorted = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, GEN_KEY($_)] } @array;




=item * GRT (perl_code)

Code template:

 state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array

Guttman-Rosler transform, another map/sort/map technique, is similar to ST. The
difference is, the computed key is transformed into a fixed-length string that
can be compared lexicographically (thus eliminating the need for the Perl custom
sort block). The original element is also transformed as a string and
concatenated into the string. Thus, GRT avoids the construction of the anonymous
arrayrefs. As a downside, the construction of the key string can be tricky.

In Perl code (assuming the compute key is transformed into a fixed 4-byte
string:

 @sorted = map { substr($_, 4) } sort map { pack("NN", -$_, $_) } @array;




=item * 2array (perl_code)

Code template:

 state $array=<array>; my @keys = map { -$_ } @$array; my @indexes = 0..$#{$array}; map { $array->[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes

This technique caches the compute key in a single array. It also constructs an
array of indexes, sorts the array according to the array keys, then constructs
the final sorted array using the sorted indexes.

Compared to GRT, it constructs far fewer anonymous arrayrefs. But it still
requires Perl custom sort block.

In Perl code:

 @indexes = 0 .. $#array;
 @keys    = map { GEN_KEY($_) } @array;
 @sorted  = map { $array[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes;




=item * Sort::Key::nkeysort (perl_code)

Code template:

 state $array=<array>; Sort::Key::nkeysort(sub { -$_ }, @$array)

This module also caches the compute keys. It's faster because it's implemented
in XS. The compute key must be string (to be compared lexicographically) or
numeric.




=back

=head1 BENCHMARK DATASETS

=over

=item * 10

=item * 100

=item * 1000

=item * 10000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m SortingByKey >>):

 #table1#
 {dataset=>10}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | GRT                 |    203230 |    4.9206 |      1     | 5.8e-12 |      20 |
 | ST                  |    207000 |    4.84   |      1.02  | 1.5e-09 |      26 |
 | 2array              |    320000 |    3.13   |      1.57  | 1.6e-09 |      23 |
 | Sort::Key::nkeysort |    506900 |    1.973  |      2.494 | 2.3e-11 |      22 |
 | uncached            |  25000000 |    0.04   |    123     | 2.3e-11 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>100}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | GRT                 |     13000 |    75     |       1    | 2.1e-07 |      20 |
 | ST                  |     13000 |    75     |       1    | 1.3e-07 |      20 |
 | 2array              |     23400 |    42.8   |       1.75 | 1.2e-08 |      26 |
 | Sort::Key::nkeysort |     51900 |    19.3   |       3.88 | 5.2e-09 |      33 |
 | uncached            |   9830000 |     0.102 |     736    | 5.2e-11 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>1000}
 +---------------------+-----------+-----------+------------+---------+---------+
 | participant         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------+-----------+-----------+------------+---------+---------+
 | GRT                 |       930 |  1100     |       1    | 1.7e-06 |      20 |
 | ST                  |       940 |  1100     |       1    |   2e-06 |      21 |
 | 2array              |      1580 |   634     |       1.69 | 2.1e-07 |      20 |
 | Sort::Key::nkeysort |      3820 |   261     |       4.1  | 5.3e-08 |      20 |
 | uncached            |   1456000 |     0.687 |    1561    | 1.7e-11 |      20 |
 +---------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>10000}
 +---------------------+-----------+-------------+------------+---------+---------+
 | participant         | rate (/s) |  time (ms)  | vs_slowest |  errors | samples |
 +---------------------+-----------+-------------+------------+---------+---------+
 | GRT                 |      67.6 | 14.8        |       1    | 1.3e-05 |      20 |
 | ST                  |      67.9 | 14.7        |       1    |   7e-06 |      20 |
 | 2array              |     122   |  8.22       |       1.8  | 1.8e-06 |      20 |
 | Sort::Key::nkeysort |     320   |  3.1        |       4.8  |   6e-06 |      20 |
 | uncached            |  149191   |  0.00670284 |    2206.16 | 5.7e-12 |      20 |
 +---------------------+-----------+-------------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SortingByKey --module-startup >>):

 #table5#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Sort::Key           |      13.4 |                    7.4 |        1   | 9.4e-06 |      20 |
 | perl -e1 (baseline) |       6   |                    0   |        2.2 | 9.4e-06 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SortingByKey>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SortingByKey>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SortingByKey>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Guttman, U., & Rosler, L. (2003). A fresh look at efficient perl sorting.
L<http://www.sysarch.com/Perl/sort_paper.html>. This is the original paper that
mentions GRT.

L<https://www.perlmonks.org/?node_id=145659>

L<https://www.perlmonks.org/?node_id=287149>

L<Sort::Maker>, also by Uri Guttman, describes the various sort techniques (ST,
GRT, etc).

L<Sort::Key> by Salvador Fandiño García.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
