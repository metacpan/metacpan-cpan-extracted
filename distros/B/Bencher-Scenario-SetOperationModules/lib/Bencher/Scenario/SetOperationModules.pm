package Bencher::Scenario::SetOperationModules;

our $DATE = '2017-02-19'; # DATE
our $VERSION = '0.12'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Perl set operation (union, intersection, diff, symmetric diff) modules',
    modules => {
        'List::MoreUtils' => {
            version => '0.407', # singleton() is available from this version
        },
    },
    participants => [
        # UNION
        {
            tags => ['op:union'],
            module => 'Array::Utils',
            function => 'unique',
            code_template => '&Array::Utils::unique(<set1>, <set2>)', # we use &func instead of func to defeat prototype which confuses some tools
        },
        {
            tags => ['op:union'],
            module => 'Set::Scalar',
            function => 'union',
            code_template => 'my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->union($s2)',
        },
        {
            tags => ['op:union'],
            fcall_template => 'List::MoreUtils::PP::uniq(@{<set1>}, @{<set2>})',
        },
        {
            name => 'List::MoreUtils::XS::uniq',
            tags => ['op:union'],
            module => 'List::MoreUtils::XS',
            fcall_template => 'List::MoreUtils::uniq(@{<set1>}, @{<set2>})',
        },
        {
            tags => ['op:union'],
            fcall_template => 'Array::Set::set_union(<set1>, <set2>)',
        },
        {
            tags => ['op:union'],
            module => 'Set::Array',
            function => 'union',
            code_template => 'my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->union($s2)',
        },
        {
            tags => ['op:union'],
            module => 'Array::AsObject',
            function => 'union',
            code_template => 'my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->union($s2, 1)',
        },
        {
            tags => ['op:union'],
            module => 'Set::Object',
            function => 'union',
            code_template => 'my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->union($s2)',
        },
        {
            tags => ['op:union'],
            module => 'Set::Tiny',
            function => 'union',
            code_template => 'my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->union($s2)',
        },
        {
            tags => ['op:union'],
            module => 'List::Collection',
            function => 'union',
            code_template => '[List::Collection::union(<set1>, <set2>)]',
        },

        # SYMDIFF
        {
            tags => ['op:symdiff'],
            module => 'Array::Utils',
            function => 'array_diff',
            code_template => '&Array::Utils::array_diff(<set1>, <set2>)', # we use &func instead of func to defeat prototype which confuses some tools
        },
        {
            tags => ['op:symdiff'],
            module => 'Set::Scalar',
            function => 'symmetric_difference',
            code_template => 'my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->symmetric_difference($s2)',
        },
        # List::MoreUtils' singleton() can do symmetric difference as long as we
        # make sure that set1 and set2 do not contain duplicates (which, since
        # they should be sets, should not)
        {
            tags => ['op:symdiff'],
            fcall_template => 'List::MoreUtils::PP::singleton(@{<set1>}, @{<set2>})',
        },
        {
            name => 'List::MoreUtils::XS::singleton',
            tags => ['op:symdiff'],
            module => 'List::MoreUtils::XS',
            fcall_template => 'List::MoreUtils::singleton(@{<set1>}, @{<set2>})',
        },
        {
            tags => ['op:symdiff'],
            fcall_template => 'Array::Set::set_symdiff(<set1>, <set2>)',
        },
        {
            tags => ['op:symdiff'],
            module => 'Set::Array',
            function => 'symmetric_difference',
            code_template => 'my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->symmetric_difference($s2)',
        },
        # Array::AsObject::symmetric_difference's handling of duplicates is
        # non-standard though, see its doc
        {
            tags => ['op:symdiff'],
            module => 'Array::AsObject',
            function => 'symmetric_difference',
            code_template => 'my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->symmetric_difference($s2)',
        },
        {
            tags => ['op:symdiff'],
            module => 'Set::Object',
            function => 'symmetric_difference',
            code_template => 'my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->symmetric_difference($s2)',
        },
        {
            tags => ['op:symdiff'],
            module => 'Set::Tiny',
            function => 'symmetric_difference',
            code_template => 'my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->symmetric_difference($s2)',
        },
        {
            tags => ['op:symdiff'],
            module => 'List::Collection',
            function => 'complement',
            code_template => '[List::Collection::complement(<set1>, <set2>)]',
        },

        # DIFF
        {
            tags => ['op:diff'],
            module => 'Array::Utils',
            function => 'array_minus',
            code_template => '&Array::Utils::array_minus(<set1>, <set2>)', # we use &func instead of func to defeat prototype which confuses some tools
        },
        {
            tags => ['op:diff'],
            module => 'Set::Scalar',
            function => 'difference',
            code_template => 'my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->difference($s2)',
        },
        {
            tags => ['op:diff'],
            fcall_template => 'Array::Set::set_diff(<set1>, <set2>)',
        },
        {
            tags => ['op:diff'],
            module => 'Set::Array',
            function => 'difference',
            code_template => 'my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->difference($s2)',
        },
        # Array::AsObject::difference's handling of duplicates is non-standard
        # though, see its doc
        {
            tags => ['op:diff'],
            module => 'Array::AsObject',
            function => 'difference',
            code_template => 'my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->difference($s2)',
        },
        {
            tags => ['op:diff'],
            module => 'Set::Object',
            function => 'difference',
            code_template => 'my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->difference($s2)',
        },
        {
            tags => ['op:diff'],
            module => 'Set::Tiny',
            function => 'difference',
            code_template => 'my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->difference($s2)',
        },
        {
            tags => ['op:diff'],
            module => 'List::Collection',
            function => 'subtract',
            code_template => '[List::Collection::subtract(<set1>, <set2>)]',
        },

        # INTERSECT
        {
            tags => ['op:intersect'],
            module => 'Array::Utils',
            function => 'intersect',
            code_template => '&Array::Utils::intersect(<set1>, <set2>)', # we use &func instead of func to defeat prototype which confuses some tools
        },
        {
            tags => ['op:intersect'],
            module => 'Set::Scalar',
            function => 'intersection',
            code_template => 'my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->intersection($s2)',
        },
        # there's no opposite for singleton() yet in List::MoreUtils (as of
        # v0.413).
        {
            tags => ['op:intersect'],
            fcall_template => 'Array::Set::set_intersect(<set1>, <set2>)',
        },
        {
            tags => ['op:intersect'],
            module => 'Set::Array',
            function => 'intersection',
            code_template => 'my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->intersection($s2)',
        },
        {
            tags => ['op:intersect'],
            module => 'Array::AsObject',
            function => 'intersection',
            code_template => 'my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->intersection($s2, 1)',
        },
        {
            tags => ['op:intersect'],
            module => 'Set::Object',
            function => 'intersection',
            code_template => 'my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->intersection($s2)',
        },
        {
            tags => ['op:intersect'],
            module => 'Set::Tiny',
            function => 'intersection',
            code_template => 'my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->intersection($s2)',
        },
        {
            tags => ['op:intersect'],
            module => 'List::Collection',
            function => 'intersect',
            code_template => '[List::Collection::intersect(<set1>, <set2>)]',
        },
    ],

    # XXX: add more datasets (larger data, etc)
    datasets => [
        {
            name => 'num10',
            args => {
                set1 => [1..10],
                set2 => [2..11],
            },
        },
        {
            name => 'num100',
            args => {
                set1 => [1..100],
                set2 => [2..101],
            },
        },
        {
            name => 'num1000',
            args => {
                set1 => [1..1000],
                set2 => [2..1001],
            },
            include_by_default => 0,
        },
    ],
};

1;
# ABSTRACT: Benchmark Perl set operation (union, intersection, diff, symmetric diff) modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SetOperationModules - Benchmark Perl set operation (union, intersection, diff, symmetric diff) modules

=head1 VERSION

This document describes version 0.12 of Bencher::Scenario::SetOperationModules (from Perl distribution Bencher-Scenario-SetOperationModules), released on 2017-02-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SetOperationModules

To run module startup overhead benchmark:

 % bencher --module-startup -m SetOperationModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::AsObject> 1.02

L<Array::Set> 0.05

L<Array::Utils> 0.5

L<List::Collection> 0.0.4

L<List::MoreUtils> 0.416

L<List::MoreUtils::PP> 0.416

L<Set::Array> 0.30

L<Set::Object> 1.35

L<Set::Scalar> 1.29

L<Set::Tiny> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Utils::unique (perl_code) [op:union]

Code template:

 &Array::Utils::unique(<set1>, <set2>)



=item * Set::Scalar::union (perl_code) [op:union]

Code template:

 my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->union($s2)



=item * List::MoreUtils::PP::uniq (perl_code) [op:union]

Function call template:

 List::MoreUtils::PP::uniq(@{<set1>}, @{<set2>})



=item * List::MoreUtils::XS::uniq (perl_code) [op:union]

Function call template:

 List::MoreUtils::uniq(@{<set1>}, @{<set2>})



=item * Array::Set::set_union (perl_code) [op:union]

Function call template:

 Array::Set::set_union(<set1>, <set2>)



=item * Set::Array::union (perl_code) [op:union]

Code template:

 my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->union($s2)



=item * Array::AsObject::union (perl_code) [op:union]

Code template:

 my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->union($s2, 1)



=item * Set::Object::union (perl_code) [op:union]

Code template:

 my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->union($s2)



=item * Set::Tiny::union (perl_code) [op:union]

Code template:

 my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->union($s2)



=item * List::Collection::union (perl_code) [op:union]

Code template:

 [List::Collection::union(<set1>, <set2>)]



=item * Array::Utils::array_diff (perl_code) [op:symdiff]

Code template:

 &Array::Utils::array_diff(<set1>, <set2>)



=item * Set::Scalar::symmetric_difference (perl_code) [op:symdiff]

Code template:

 my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->symmetric_difference($s2)



=item * List::MoreUtils::PP::singleton (perl_code) [op:symdiff]

Function call template:

 List::MoreUtils::PP::singleton(@{<set1>}, @{<set2>})



=item * List::MoreUtils::XS::singleton (perl_code) [op:symdiff]

Function call template:

 List::MoreUtils::singleton(@{<set1>}, @{<set2>})



=item * Array::Set::set_symdiff (perl_code) [op:symdiff]

Function call template:

 Array::Set::set_symdiff(<set1>, <set2>)



=item * Set::Array::symmetric_difference (perl_code) [op:symdiff]

Code template:

 my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->symmetric_difference($s2)



=item * Array::AsObject::symmetric_difference (perl_code) [op:symdiff]

Code template:

 my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->symmetric_difference($s2)



=item * Set::Object::symmetric_difference (perl_code) [op:symdiff]

Code template:

 my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->symmetric_difference($s2)



=item * Set::Tiny::symmetric_difference (perl_code) [op:symdiff]

Code template:

 my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->symmetric_difference($s2)



=item * List::Collection::complement (perl_code) [op:symdiff]

Code template:

 [List::Collection::complement(<set1>, <set2>)]



=item * Array::Utils::array_minus (perl_code) [op:diff]

Code template:

 &Array::Utils::array_minus(<set1>, <set2>)



=item * Set::Scalar::difference (perl_code) [op:diff]

Code template:

 my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->difference($s2)



=item * Array::Set::set_diff (perl_code) [op:diff]

Function call template:

 Array::Set::set_diff(<set1>, <set2>)



=item * Set::Array::difference (perl_code) [op:diff]

Code template:

 my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->difference($s2)



=item * Array::AsObject::difference (perl_code) [op:diff]

Code template:

 my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->difference($s2)



=item * Set::Object::difference (perl_code) [op:diff]

Code template:

 my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->difference($s2)



=item * Set::Tiny::difference (perl_code) [op:diff]

Code template:

 my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->difference($s2)



=item * List::Collection::subtract (perl_code) [op:diff]

Code template:

 [List::Collection::subtract(<set1>, <set2>)]



=item * Array::Utils::intersect (perl_code) [op:intersect]

Code template:

 &Array::Utils::intersect(<set1>, <set2>)



=item * Set::Scalar::intersection (perl_code) [op:intersect]

Code template:

 my $s1 = Set::Scalar->new(@{<set1>}); my $s2 = Set::Scalar->new(@{<set2>}); $s1->intersection($s2)



=item * Array::Set::set_intersect (perl_code) [op:intersect]

Function call template:

 Array::Set::set_intersect(<set1>, <set2>)



=item * Set::Array::intersection (perl_code) [op:intersect]

Code template:

 my $s1 = Set::Array->new(@{<set1>}); my $s2 = Set::Array->new(@{<set2>}); $s1->intersection($s2)



=item * Array::AsObject::intersection (perl_code) [op:intersect]

Code template:

 my $s1 = Array::AsObject->new(@{<set1>}); my $s2 = Array::AsObject->new(@{<set2>}); $s1->intersection($s2, 1)



=item * Set::Object::intersection (perl_code) [op:intersect]

Code template:

 my $s1 = Set::Object->new(@{<set1>}); my $s2 = Set::Object->new(@{<set2>}); $s1->intersection($s2)



=item * Set::Tiny::intersection (perl_code) [op:intersect]

Code template:

 my $s1 = Set::Tiny->new(@{<set1>}); my $s2 = Set::Tiny->new(@{<set2>}); $s1->intersection($s2)



=item * List::Collection::intersect (perl_code) [op:intersect]

Code template:

 [List::Collection::intersect(<set1>, <set2>)]



=back

=head1 BENCHMARK DATASETS

=over

=item * num10

=item * num100

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m SetOperationModules >>):

 #table1#
 {dataset=>"num10",p_tags=>"op:diff"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::difference     |     12000 |   80      |      1     | 1.3e-07 |      20 |
 | Array::AsObject::difference |     24000 |   41.7    |      1.92  | 1.3e-08 |      20 |
 | Set::Array::difference      |     67000 |   15      |      5.3   | 1.9e-08 |      22 |
 | Set::Object::difference     |    114000 |    8.74   |      9.16  | 3.3e-09 |      20 |
 | Set::Tiny::difference       |    141000 |    7.08   |     11.3   |   3e-09 |      24 |
 | List::Collection::subtract  |    190000 |    5.3    |     15     | 6.7e-09 |      20 |
 | Array::Set::set_diff        |    226000 |    4.42   |     18.1   | 1.7e-09 |      20 |
 | Array::Utils::array_minus   |    263070 |    3.8013 |     21.053 | 2.9e-11 |      21 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"num100",p_tags=>"op:diff"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Array::AsObject::difference |       460 |    2.2    |        1   | 4.2e-06 |      21 |
 | Set::Scalar::difference     |      2200 |    0.46   |        4.7 | 2.4e-06 |      21 |
 | Set::Array::difference      |     13000 |    0.078  |       28   | 4.2e-07 |      21 |
 | Set::Object::difference     |     15000 |    0.068  |       32   |   8e-08 |      20 |
 | Set::Tiny::difference       |     17000 |    0.058  |       37   | 1.1e-07 |      20 |
 | Array::Set::set_diff        |     29000 |    0.035  |       62   | 5.3e-08 |      20 |
 | Array::Utils::array_minus   |     30000 |    0.034  |       64   | 5.3e-08 |      20 |
 | List::Collection::subtract  |     29600 |    0.0338 |       64.5 |   1e-08 |      34 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"num10",p_tags=>"op:intersect"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::intersection     |     11000 |  90       |     1      | 1.1e-07 |      30 |
 | Array::AsObject::intersection |     11000 |  90       |     1      |   1e-07 |      22 |
 | List::Collection::intersect   |     18000 |  55       |     1.6    | 9.7e-08 |      24 |
 | Set::Array::intersection      |     36000 |  28       |     3.3    | 3.7e-08 |      24 |
 | Set::Object::intersection     |     91400 |  10.9     |     8.21   | 3.3e-09 |      20 |
 | Set::Tiny::intersection       |    155572 |   6.42789 |    13.9869 |   0     |      38 |
 | Array::Set::set_intersect     |    176000 |   5.69    |    15.8    | 1.6e-09 |      22 |
 | Array::Utils::intersect       |    249390 |   4.0098  |    22.422  | 2.3e-11 |      20 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"num100",p_tags=>"op:intersect"}
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | participant                   | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------------------------+-----------+-----------+------------+---------+---------+
 | Array::AsObject::intersection |       223 |    4.48   |       1    | 2.5e-06 |      20 |
 | Set::Array::intersection      |       595 |    1.68   |       2.66 | 1.1e-06 |      20 |
 | List::Collection::intersect   |      1400 |    0.73   |       6.2  | 2.2e-06 |      20 |
 | Set::Scalar::intersection     |      1980 |    0.505  |       8.87 | 2.1e-07 |      20 |
 | Set::Object::intersection     |     11000 |    0.092  |      49    | 1.1e-07 |      27 |
 | Set::Tiny::intersection       |     18000 |    0.056  |      80    |   1e-07 |      21 |
 | Array::Set::set_intersect     |     20800 |    0.0482 |      92.9  | 1.3e-08 |      22 |
 | Array::Utils::intersect       |     27900 |    0.0358 |     125    | 1.1e-08 |      28 |
 +-------------------------------+-----------+-----------+------------+---------+---------+

 #table5#
 {dataset=>"num10",p_tags=>"op:symdiff"}
 +---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                           | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------------+-----------+-----------+------------+---------+---------+
 | Array::AsObject::symmetric_difference |    5110   |  196      |     1      | 4.9e-08 |      24 |
 | List::Collection::complement          |    7900   |  130      |     1.5    | 6.9e-07 |      20 |
 | Set::Scalar::symmetric_difference     |   19000   |   53      |     3.7    | 1.3e-07 |      21 |
 | Set::Object::symmetric_difference     |   62900   |   15.9    |    12.3    | 6.1e-09 |      24 |
 | Set::Array::symmetric_difference      |   73714.5 |   13.5659 |    14.4262 |   0     |      20 |
 | Set::Tiny::symmetric_difference       |  130000   |    7.6    |    26      | 1.3e-08 |      20 |
 | Array::Set::set_symdiff               |  173400   |    5.767  |    33.93   | 9.8e-11 |      21 |
 | Array::Utils::array_diff              |  216300   |    4.622  |    42.34   | 1.9e-10 |      22 |
 | List::MoreUtils::PP::singleton        |  235000   |    4.25   |    46.1    | 1.5e-09 |      26 |
 | List::MoreUtils::XS::singleton        |  414000   |    2.41   |    81.1    | 7.5e-10 |      25 |
 +---------------------------------------+-----------+-----------+------------+---------+---------+

 #table6#
 {dataset=>"num100",p_tags=>"op:symdiff"}
 +---------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                           | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +---------------------------------------+-----------+-----------+------------+---------+---------+
 | Array::AsObject::symmetric_difference |       110 |    9.3    |          1 | 2.8e-05 |      20 |
 | List::Collection::complement          |       530 |    1.9    |          5 | 3.8e-06 |      20 |
 | Set::Scalar::symmetric_difference     |      3000 |    0.34   |         28 | 6.1e-07 |      22 |
 | Set::Object::symmetric_difference     |      9400 |    0.11   |         87 | 1.5e-07 |      24 |
 | Set::Array::symmetric_difference      |     13300 |    0.0752 |        124 | 2.7e-08 |      20 |
 | Set::Tiny::symmetric_difference       |     16000 |    0.063  |        150 | 9.9e-08 |      23 |
 | Array::Set::set_symdiff               |     20800 |    0.0481 |        193 | 1.3e-08 |      20 |
 | List::MoreUtils::PP::singleton        |     26200 |    0.0381 |        244 | 1.2e-08 |      25 |
 | Array::Utils::array_diff              |     26700 |    0.0375 |        249 | 1.3e-08 |      20 |
 | List::MoreUtils::XS::singleton        |     42800 |    0.0234 |        398 |   6e-09 |      25 |
 +---------------------------------------+-----------+-----------+------------+---------+---------+

 #table7#
 {dataset=>"num10",p_tags=>"op:union"}
 +---------------------------+-----------+-----------+------------+---------+---------+
 | participant               | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+-----------+-----------+------------+---------+---------+
 | Set::Scalar::union        |     12000 |  85       |     1      | 1.3e-07 |      20 |
 | List::Collection::union   |     17000 |  60       |     1.4    | 2.1e-07 |      21 |
 | Array::AsObject::union    |     75100 |  13.3     |     6.38   | 6.7e-09 |      20 |
 | Set::Array::union         |     97000 |  10       |     8.2    | 1.3e-08 |      20 |
 | Set::Object::union        |    110000 |   8.9     |     9.5    | 1.3e-08 |      20 |
 | Set::Tiny::union          |    150000 |   6.6     |    13      |   1e-08 |      20 |
 | Array::Set::set_union     |    180000 |   5.5     |    16      | 6.7e-09 |      20 |
 | List::MoreUtils::PP::uniq |    320000 |   3.2     |    27      | 6.7e-09 |      20 |
 | List::MoreUtils::XS::uniq |    512740 |   1.95031 |    43.5071 |   0     |      24 |
 | Array::Utils::unique      |    849000 |   1.18    |    72.1    | 4.2e-10 |      20 |
 +---------------------------+-----------+-----------+------------+---------+---------+

 #table8#
 {dataset=>"num100",p_tags=>"op:union"}
 +---------------------------+-----------+-----------+------------+---------+---------+
 | participant               | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------+-----------+-----------+------------+---------+---------+
 | List::Collection::union   |       920 |  1100     |      1     | 2.2e-06 |      20 |
 | Set::Scalar::union        |      2130 |   469     |      2.31  | 4.3e-07 |      20 |
 | Array::AsObject::union    |     11000 |    91     |     12     |   3e-07 |      26 |
 | Set::Object::union        |     14000 |    71     |     15     | 2.1e-07 |      20 |
 | Set::Tiny::union          |     18000 |    57     |     19     | 1.1e-07 |      20 |
 | Set::Array::union         |     18000 |    56     |     19     | 1.1e-07 |      20 |
 | Array::Set::set_union     |     22168 |    45.111 |     24.076 | 5.8e-11 |      25 |
 | List::MoreUtils::PP::uniq |     34600 |    28.9   |     37.6   | 1.2e-08 |      24 |
 | List::MoreUtils::XS::uniq |     55900 |    17.9   |     60.7   | 5.8e-09 |      26 |
 | Array::Utils::unique      |    260000 |     3.9   |    280     | 6.7e-09 |      20 |
 +---------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m SetOperationModules --module-startup >>):

 #table9#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | List::Collection    | 0.93                         | 4.3                | 20             |      14   |                   11.4 |        1   | 3.3e-05 |      20 |
 | Set::Array          | 3                            | 6.5                | 26             |      14   |                   11.4 |        1   | 6.6e-05 |      20 |
 | Array::AsObject     | 2.2                          | 5.6                | 23             |      14   |                   11.4 |        1   | 5.9e-05 |      20 |
 | Set::Object         | 1                            | 4.4                | 20             |      12   |                    9.4 |        1.2 | 2.7e-05 |      20 |
 | Set::Scalar         | 1.2                          | 4.5                | 20             |      11   |                    8.4 |        1.3 | 3.2e-05 |      20 |
 | List::MoreUtils     | 1.1                          | 4.4                | 20             |       8.4 |                    5.8 |        1.7 |   5e-05 |      20 |
 | List::MoreUtils::PP | 1.6                          | 5                  | 23             |       5.7 |                    3.1 |        2.5 | 3.2e-05 |      20 |
 | Array::Set          | 2.7                          | 6.1                | 28             |       5.2 |                    2.6 |        2.8 | 2.7e-05 |      20 |
 | Set::Tiny           | 2.3                          | 5.7                | 27             |       3.8 |                    1.2 |        3.8 | 1.7e-05 |      20 |
 | Array::Utils        | 1.9                          | 5.3                | 23             |       3.7 |                    1.1 |        3.9 | 2.2e-05 |      20 |
 | perl -e1 (baseline) | 0.93                         | 4.3                | 20             |       2.6 |                    0   |        5.6 | 6.5e-06 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SetOperationModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SetOperationModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SetOperationModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Benchmark::Featureset::SetOps>

Excluded modules: L<Set::Bag> (expects hashes instead of arrays),
L<Set::SortedArray> (members are sorted).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
