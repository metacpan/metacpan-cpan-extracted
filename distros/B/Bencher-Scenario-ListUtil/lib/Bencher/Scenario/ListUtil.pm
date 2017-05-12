package Bencher::Scenario::ListUtil;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark List::Util (XS) vs PP implementation(s)',

    description => <<'_',

EARLY VERSION, ONLY A FEW FUNCTIONS HAVE BEEN BENCHMARKED.

For max*/min*, in general the XS version are about 3x faster than PP.

_

    participants => [
        # max
        {
            tags => ['numeric'],
            fcall_template => 'List::Util::max(@{<list>})',
        },
        {
            tags => ['numeric'],
            fcall_template => 'PERLANCAR::List::Util::PP::max(@{<list>})',
        },
        # maxstr
        {
            tags => ['stringy'],
            fcall_template => 'List::Util::maxstr(@{<list>})',
        },
        {
            tags => ['stringy'],
            fcall_template => 'PERLANCAR::List::Util::PP::maxstr(@{<list>})',
        },

        # min
        {
            tags => ['numeric'],
            fcall_template => 'List::Util::min(@{<list>})',
        },
        {
            tags => ['numeric'],
            fcall_template => 'PERLANCAR::List::Util::PP::min(@{<list>})',
        },
        # minstr
        {
            tags => ['stringy'],
            fcall_template => 'List::Util::minstr(@{<list>})',
        },
        {
            tags => ['stringy'],
            fcall_template => 'PERLANCAR::List::Util::PP::minstr(@{<list>})',
        },

    ],

    datasets => [
        {
            name => 'num10',
            args => {
                list => [2..5, 1,10, 6..9],
            },
        },
        {
            name => 'num100',
            args => {
                list => [2..50, 1,100, 51..99],
            },
        },
        {
            name => 'num1000',
            args => {
                list => [2..500, 1,1000, 501..999],
            },
        },

        {
            name => 'str10',
            args => {
                list => ['b'..'e', 'a','j', 'f'..'i'],
            },
            exclude_participant_tags => ['numeric'],
        },
        {
            name => 'str100', # aa..dv
            args => {
                list => ['ab'..'bx', 'aa','dv', 'by'..'du'],
            },
            exclude_participant_tags => ['numeric'],
        },
        {
            name => 'str1000', # aaa..bml
            args => {
                list => ['aab'..'atf', 'aaa','bml', 'atg'..'bmk'],
            },
            exclude_participant_tags => ['numeric'],
        },
    ],
};

1;
# ABSTRACT: Benchmark List::Util (XS) vs PP implementation(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListUtil - Benchmark List::Util (XS) vs PP implementation(s)

=head1 VERSION

This document describes version 0.05 of Bencher::Scenario::ListUtil (from Perl distribution Bencher-Scenario-ListUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListUtil

To run module startup overhead benchmark:

 % bencher --module-startup -m ListUtil

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

EARLY VERSION, ONLY A FEW FUNCTIONS HAVE BEEN BENCHMARKED.

For max*/min*, in general the XS version are about 3x faster than PP.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::Util> 1.45

L<PERLANCAR::List::Util::PP> 0.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::Util::max (perl_code) [numeric]

Function call template:

 List::Util::max(@{<list>})



=item * PERLANCAR::List::Util::PP::max (perl_code) [numeric]

Function call template:

 PERLANCAR::List::Util::PP::max(@{<list>})



=item * List::Util::maxstr (perl_code) [stringy]

Function call template:

 List::Util::maxstr(@{<list>})



=item * PERLANCAR::List::Util::PP::maxstr (perl_code) [stringy]

Function call template:

 PERLANCAR::List::Util::PP::maxstr(@{<list>})



=item * List::Util::min (perl_code) [numeric]

Function call template:

 List::Util::min(@{<list>})



=item * PERLANCAR::List::Util::PP::min (perl_code) [numeric]

Function call template:

 PERLANCAR::List::Util::PP::min(@{<list>})



=item * List::Util::minstr (perl_code) [stringy]

Function call template:

 List::Util::minstr(@{<list>})



=item * PERLANCAR::List::Util::PP::minstr (perl_code) [stringy]

Function call template:

 PERLANCAR::List::Util::PP::minstr(@{<list>})



=back

=head1 BENCHMARK DATASETS

=over

=item * num10

=item * num100

=item * num1000

=item * str10

=item * str100

=item * str1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ListUtil >>):

 #table1#
 +-----------------------------------+---------+------------+------------+------------+---------+---------+
 | participant                       | dataset | rate (/s)  | time (μs)  | vs_slowest |  errors | samples |
 +-----------------------------------+---------+------------+------------+------------+---------+---------+
 | PERLANCAR::List::Util::PP::minstr | num1000 |    4838.76 | 206.664    |    1       |   0     |      28 |
 | PERLANCAR::List::Util::PP::maxstr | num1000 |    5370    | 186        |    1.11    | 5.3e-08 |      20 |
 | PERLANCAR::List::Util::PP::maxstr | str1000 |    7450    | 134        |    1.54    | 4.8e-08 |      25 |
 | PERLANCAR::List::Util::PP::minstr | str1000 |    8540    | 117        |    1.77    |   5e-08 |      23 |
 | List::Util::minstr                | num1000 |    9189.73 | 108.817    |    1.89919 | 3.1e-11 |      20 |
 | List::Util::maxstr                | num1000 |    9300    | 110        |    1.9     | 2.1e-07 |      20 |
 | PERLANCAR::List::Util::PP::max    | num1000 |   10000    |  98        |    2.1     | 1.1e-07 |      20 |
 | PERLANCAR::List::Util::PP::min    | num1000 |   10700    |  93.5      |    2.21    | 2.4e-08 |      24 |
 | List::Util::minstr                | str1000 |   17000    |  60        |    3.4     | 5.6e-07 |      20 |
 | List::Util::maxstr                | str1000 |   18000    |  55.6      |    3.72    | 2.2e-08 |      30 |
 | List::Util::min                   | num1000 |   42500    |  23.5      |    8.79    | 6.5e-09 |      21 |
 | List::Util::max                   | num1000 |   43000    |  23.3      |    8.89    | 6.7e-09 |      20 |
 | PERLANCAR::List::Util::PP::minstr | num100  |   52755.6  |  18.9553   |   10.9027  | 1.1e-11 |      20 |
 | PERLANCAR::List::Util::PP::maxstr | num100  |   57252.1  |  17.4666   |   11.832   | 1.2e-11 |      20 |
 | PERLANCAR::List::Util::PP::maxstr | str100  |   67000    |  15        |   14       | 7.2e-08 |      29 |
 | PERLANCAR::List::Util::PP::minstr | str100  |   74700    |  13.4      |   15.4     | 5.4e-09 |      31 |
 | PERLANCAR::List::Util::PP::max    | num100  |   99800    |  10        |   20.6     | 3.3e-09 |      20 |
 | PERLANCAR::List::Util::PP::min    | num100  |  110000    |   9.2      |   23       | 1.5e-08 |      26 |
 | List::Util::minstr                | num100  |  110990    |   9.0095   |   22.938   | 1.2e-11 |      20 |
 | List::Util::maxstr                | num100  |  111398    |   8.9768   |   23.0221  |   0     |      29 |
 | List::Util::maxstr                | str100  |  170000    |   5.9      |   35       | 3.9e-08 |      31 |
 | List::Util::minstr                | str100  |  181070    |   5.5226   |   37.422   | 1.1e-11 |      25 |
 | List::Util::max                   | num100  |  370300    |   2.7      |   76.53    | 1.2e-10 |      20 |
 | List::Util::min                   | num100  |  418000    |   2.39     |   86.4     | 8.3e-10 |      20 |
 | PERLANCAR::List::Util::PP::maxstr | num10   |  446000    |   2.24     |   92.2     | 8.2e-10 |      22 |
 | PERLANCAR::List::Util::PP::minstr | num10   |  453900    |   2.203    |   93.8     | 3.4e-11 |      20 |
 | PERLANCAR::List::Util::PP::minstr | str10   |  586600    |   1.705    |  121.2     | 3.5e-11 |      32 |
 | PERLANCAR::List::Util::PP::maxstr | str10   |  603000    |   1.66     |  125       | 7.8e-10 |      23 |
 | PERLANCAR::List::Util::PP::max    | num10   |  688500    |   1.452    |  142.3     | 3.4e-11 |      22 |
 | List::Util::minstr                | num10   |  798000    |   1.25     |  165       | 3.7e-10 |      25 |
 | PERLANCAR::List::Util::PP::min    | num10   |  890000    |   1.12     |  184       |   1e-09 |      29 |
 | List::Util::maxstr                | num10   |  897000    |   1.12     |  185       |   4e-10 |      22 |
 | List::Util::maxstr                | str10   | 1403770    |   0.712368 |  290.109   |   0     |      20 |
 | List::Util::minstr                | str10   | 1420000    |   0.704    |  294       | 9.1e-11 |      21 |
 | List::Util::max                   | num10   | 2300000    |   0.43     |  480       | 3.3e-09 |      20 |
 | List::Util::min                   | num10   | 2700000    |   0.38     |  550       | 8.3e-10 |      20 |
 +-----------------------------------+---------+------------+------------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ListUtil --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | List::Util                | 1108                         | 4.4                | 16             |       9.6 |                    3.7 |        1   | 2.5e-05 |      21 |
 | PERLANCAR::List::Util::PP | 1032                         | 4.3                | 18             |       9.6 |                    3.7 |        1   |   2e-05 |      20 |
 | perl -e1 (baseline)       | 1032                         | 4.4                | 18             |       5.9 |                    0   |        1.6 | 2.8e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ListUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ListUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ListUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
