package Bencher::Scenario::BinarySearch;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-21'; # DATE
our $DIST = 'Bencher-Scenario-BinarySearch'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Tie::Simple;

our @ary_10k_num = (0..9999);
our @ary_10k_str = ("aaa".."oup");

our @ary_10k_num_tie;
tie @ary_10k_num_tie, 'Tie::Simple', my($data_num),
    FETCH     => sub { my ($self, $index) = @_; $ary_10k_num[$index] },
    FETCHSIZE => sub { my $self = shift; scalar(@ary_10k_num) };

our @ary_10k_str_tie;
tie @ary_10k_str_tie, 'Tie::Simple', my($data_str),
    FETCH     => sub { my ($self, $index) = @_; $ary_10k_str[$index] },
    FETCHSIZE => sub { my $self = shift; scalar(@ary_10k_str) };

our $scenario = {
    summary => 'Benchmark binary searching Perl arrays',
    participants => [
        {module=>'List::BinarySearch::PP', name=>'List::BinarySearch::PP-10k-num'    , code_template=>'List::BinarySearch::PP::binsearch(sub {$a <=> $b}, int(10_000*rand()), \\@Bencher::Scenario::BinarySearch::ary_10k_num)'},
        {module=>'List::BinarySearch::XS', name=>'List::BinarySearch::XS-10k-num'    , code_template=>'List::BinarySearch::XS::binsearch(sub {$a <=> $b}, int(10_000*rand()), \\@Bencher::Scenario::BinarySearch::ary_10k_num)'},
        {module=>'List::BinarySearch::PP', name=>'List::BinarySearch::PP-10k-num-tie', code_template=>'List::BinarySearch::PP::binsearch(sub {$a <=> $b}, int(10_000*rand()), \\@Bencher::Scenario::BinarySearch::ary_10k_num_tie)'},
        #{module=>'List::BinarySearch::XS', name=>'List::BinarySearch::XS-10k-num-tie', code_template=>'List::BinarySearch::XS::binsearch(sub {$a <=> $b}, int(10_000*rand()), \\@Bencher::Scenario::BinarySearch::ary_10k_num_tie)'},

        {module=>'List::BinarySearch::PP', name=>'List::BinarySearch::PP-10k-str'    , code_template=>'List::BinarySearch::PP::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \\@Bencher::Scenario::BinarySearch::ary_10k_str)'},
        {module=>'List::BinarySearch::XS', name=>'List::BinarySearch::XS-10k-str'    , code_template=>'List::BinarySearch::XS::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \\@Bencher::Scenario::BinarySearch::ary_10k_str)'},
        {module=>'List::BinarySearch::PP', name=>'List::BinarySearch::PP-10k-str-tie', code_template=>'List::BinarySearch::PP::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \\@Bencher::Scenario::BinarySearch::ary_10k_str_tie)'},
        #{module=>'List::BinarySearch::XS', name=>'List::BinarySearch::PP-10k-str-tie', code_template=>'List::BinarySearch::XS::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \\@Bencher::Scenario::BinarySearch::ary_10k_str_tie)'},
    ],
};

1;
# ABSTRACT: Benchmark binary searching Perl arrays

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::BinarySearch - Benchmark binary searching Perl arrays

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::BinarySearch (from Perl distribution Bencher-Scenario-BinarySearch), released on 2021-04-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m BinarySearch

To run module startup overhead benchmark:

 % bencher --module-startup -m BinarySearch

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<List::BinarySearch::PP> 0.25

L<List::BinarySearch::XS> 0.09

=head1 BENCHMARK PARTICIPANTS

=over

=item * List::BinarySearch::PP-10k-num (perl_code)

Code template:

 List::BinarySearch::PP::binsearch(sub {$a <=> $b}, int(10_000*rand()), \@Bencher::Scenario::BinarySearch::ary_10k_num)



=item * List::BinarySearch::XS-10k-num (perl_code)

Code template:

 List::BinarySearch::XS::binsearch(sub {$a <=> $b}, int(10_000*rand()), \@Bencher::Scenario::BinarySearch::ary_10k_num)



=item * List::BinarySearch::PP-10k-num-tie (perl_code)

Code template:

 List::BinarySearch::PP::binsearch(sub {$a <=> $b}, int(10_000*rand()), \@Bencher::Scenario::BinarySearch::ary_10k_num_tie)



=item * List::BinarySearch::PP-10k-str (perl_code)

Code template:

 List::BinarySearch::PP::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \@Bencher::Scenario::BinarySearch::ary_10k_str)



=item * List::BinarySearch::XS-10k-str (perl_code)

Code template:

 List::BinarySearch::XS::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \@Bencher::Scenario::BinarySearch::ary_10k_str)



=item * List::BinarySearch::PP-10k-str-tie (perl_code)

Code template:

 List::BinarySearch::PP::binsearch(sub {$a cmp $b}, $Bencher::Scenario::BinarySearch::ary_10k_str[(10_000*rand())], \@Bencher::Scenario::BinarySearch::ary_10k_str_tie)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m BinarySearch >>):

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | List::BinarySearch::PP-10k-str-tie |     28000 |    36     |                 0.00% |              4056.39% | 1.2e-07 |      20 |
 | List::BinarySearch::PP-10k-num-tie |     31000 |    33     |                 9.38% |              3699.79% | 1.1e-07 |      20 |
 | List::BinarySearch::PP-10k-str     |     75000 |    13     |               167.29% |              1455.04% | 5.3e-08 |      20 |
 | List::BinarySearch::PP-10k-num     |     91000 |    11     |               224.35% |              1181.45% | 2.7e-08 |      20 |
 | List::BinarySearch::XS-10k-str     |   1010000 |     0.986 |              3510.35% |                15.12% | 4.2e-10 |      20 |
 | List::BinarySearch::XS-10k-num     |   1200000 |     0.86  |              4056.39% |                 0.00% | 1.2e-09 |      22 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m BinarySearch --module-startup >>):

 #table2#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | List::BinarySearch::PP |     11.7  |              5.1  |                 0.00% |                77.75% |   1e-05 |      20 |
 | List::BinarySearch::XS |      9.23 |              2.63 |                26.62% |                40.38% | 7.6e-06 |      20 |
 | perl -e1 (baseline)    |      6.6  |              0    |                77.75% |                 0.00% | 5.7e-05 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<List::BinarySearch::XS> is an order of magnitude faster, but does not support
tied arrays. On my laptop, binary searching a tied array is about three times
faster than binary searching a regular array.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BinarySearch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BinarySearch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenario-BinarySearch/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
