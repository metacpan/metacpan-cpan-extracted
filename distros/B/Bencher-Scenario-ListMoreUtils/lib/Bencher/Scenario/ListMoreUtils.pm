package Bencher::Scenario::ListMoreUtils;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark List::MoreUtils::PP vs List::MoreUtils::XS',
    description => <<'_',

EARLY VERSION, ONLY A FEW FUNCTIONS HAVE BEEN BENCHMARKED.

_
    participants => [
        # uniq
        {
            tags => ['arg1'],
            fcall_template => 'List::MoreUtils::PP::uniq(@{<list>})',
        },
        {
            tags => ['arg1'],
            module => 'List::MoreUtils::XS',
            function => 'uniq',
            code_template => 'List::MoreUtils::uniq(@{<list>})',
        },

        # minmax
        {
            tags => ['arg1'],
            fcall_template => 'List::MoreUtils::PP::minmax(@{<list>})',
        },
        {
            tags => ['arg1'],
            module => 'List::MoreUtils::XS',
            function => 'minmax',
            code_template => 'List::MoreUtils::minmax(@{<list>})',
        },

        # first
        {
            tags => ['arg1'],
            module   => 'List::MoreUtils::PP',
            function => 'firstidx',
            code_template => 'List::MoreUtils::PP::firstidx(sub{$_==-1}, @{<list>})',
        },
        {
            tags => ['arg1'],
            module   => 'List::MoreUtils::XS',
            function => 'firstidx',
            code_template => 'List::MoreUtils::firstidx(sub{$_==-1}, @{<list>})',
        },
    ],

    datasets => [
        {
            name => 'num10',
            args => {
                list => [1..9,1],
            },
            include_participant_tags => ['arg1'],
        },
        {
            name => 'num100',
            args => {
                list => [1..99,1],
            },
            include_participant_tags => ['arg1'],
        },
        {
            name => 'num1000',
            args => {
                list => [1..999,1],
            },
            include_participant_tags => ['arg1'],
        },
    ],
};

1;
# ABSTRACT: Benchmark List::MoreUtils::PP vs List::MoreUtils::XS

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ListMoreUtils - Benchmark List::MoreUtils::PP vs List::MoreUtils::XS

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::ListMoreUtils (from Perl distribution Bencher-Scenario-ListMoreUtils), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ListMoreUtils

To run module startup overhead benchmark:

 % bencher --module-startup -m ListMoreUtils

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

EARLY VERSION, ONLY A FEW FUNCTIONS HAVE BEEN BENCHMARKED.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::MoreUtils::PP> 0.416

L<List::MoreUtils::XS> 0.416

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::MoreUtils::PP::uniq (perl_code) [arg1]

Function call template:

 List::MoreUtils::PP::uniq(@{<list>})



=item * List::MoreUtils::XS::uniq (perl_code) [arg1]

Code template:

 List::MoreUtils::uniq(@{<list>})



=item * List::MoreUtils::PP::minmax (perl_code) [arg1]

Function call template:

 List::MoreUtils::PP::minmax(@{<list>})



=item * List::MoreUtils::XS::minmax (perl_code) [arg1]

Code template:

 List::MoreUtils::minmax(@{<list>})



=item * List::MoreUtils::PP::firstidx (perl_code) [arg1]

Code template:

 List::MoreUtils::PP::firstidx(sub{$_==-1}, @{<list>})



=item * List::MoreUtils::XS::firstidx (perl_code) [arg1]

Code template:

 List::MoreUtils::firstidx(sub{$_==-1}, @{<list>})



=back

=head1 BENCHMARK DATASETS

=over

=item * num10

=item * num100

=item * num1000

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ListMoreUtils >>):

 #table1#
 +-------------------------------+---------+------------+-----------+------------+---------+---------+
 | participant                   | dataset | rate (/s)  | time (μs) | vs_slowest |  errors | samples |
 +-------------------------------+---------+------------+-----------+------------+---------+---------+
 | List::MoreUtils::PP::firstidx | num1000 |    2772.81 |  360.645  |     1      | 4.4e-11 |      20 |
 | List::MoreUtils::PP::uniq     | num1000 |    3100    |  330      |     1.1    |   1e-06 |      33 |
 | List::MoreUtils::XS::uniq     | num1000 |    3740    |  268      |     1.35   | 2.1e-07 |      20 |
 | List::MoreUtils::PP::minmax   | num1000 |    5700    |  170      |     2.1    | 2.1e-07 |      21 |
 | List::MoreUtils::XS::firstidx | num1000 |   23515    |   42.527  |     8.4805 | 4.6e-11 |      20 |
 | List::MoreUtils::PP::firstidx | num100  |   28000    |   35      |    10      | 2.4e-07 |      20 |
 | List::MoreUtils::XS::minmax   | num1000 |   35239    |   28.378  |    12.709  | 4.7e-11 |      20 |
 | List::MoreUtils::PP::uniq     | num100  |   37023    |   27.01   |    13.352  | 4.6e-11 |      21 |
 | List::MoreUtils::PP::minmax   | num100  |   56200    |   17.8    |    20.3    |   5e-09 |      36 |
 | List::MoreUtils::XS::uniq     | num100  |   57000    |   18      |    20      | 2.6e-08 |      21 |
 | List::MoreUtils::XS::firstidx | num100  |  205360    |    4.8695 |    74.063  | 4.6e-11 |      24 |
 | List::MoreUtils::PP::firstidx | num10   |  272900    |    3.664  |    98.42   | 4.9e-11 |      25 |
 | List::MoreUtils::PP::uniq     | num10   |  282000    |    3.54   |   102      | 1.6e-09 |      21 |
 | List::MoreUtils::XS::minmax   | num100  |  350000    |    2.86   |   126      | 8.5e-10 |      21 |
 | List::MoreUtils::PP::minmax   | num10   |  459000    |    2.18   |   166      | 6.9e-10 |      29 |
 | List::MoreUtils::XS::uniq     | num10   |  544390    |    1.8369 |   196.33   | 1.2e-11 |      25 |
 | List::MoreUtils::XS::firstidx | num10   | 1340000    |    0.744  |   485      | 3.9e-10 |      23 |
 | List::MoreUtils::XS::minmax   | num10   | 2000000    |    0.49   |   730      | 5.8e-10 |      23 |
 +-------------------------------+---------+------------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ListMoreUtils --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | List::MoreUtils::PP | 0.97                         | 4.4                | 18             |      10   |                    4.3 |        1   | 5.9e-05 |      20 |
 | List::MoreUtils::XS | 1.2                          | 4.5                | 16             |       9.2 |                    3.5 |        1.1 | 2.3e-05 |      20 |
 | perl -e1 (baseline) | 1.2                          | 4.5                | 16             |       5.7 |                    0   |        1.8 | 2.3e-05 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ListMoreUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ListMoreUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ListMoreUtils>

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
