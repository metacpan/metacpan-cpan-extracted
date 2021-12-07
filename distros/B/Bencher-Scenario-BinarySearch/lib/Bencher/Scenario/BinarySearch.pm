package Bencher::Scenario::BinarySearch;

use 5.010001;
use strict;
use warnings;

use Tie::Simple;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'Bencher-Scenario-BinarySearch'; # DIST
our $VERSION = '0.003'; # VERSION

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

This document describes version 0.003 of Bencher::Scenario::BinarySearch (from Perl distribution Bencher-Scenario-BinarySearch), released on 2021-11-14.

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m BinarySearch >>):

 #table1#
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | List::BinarySearch::PP-10k-str-tie |     27000 | 37        |                 0.00% |              4100.90% | 1.1e-07 |      20 |
 | List::BinarySearch::PP-10k-num-tie |     30000 | 34        |                10.16% |              3713.49% | 5.2e-08 |      21 |
 | List::BinarySearch::PP-10k-str     |     71000 | 14        |               161.85% |              1504.31% | 3.3e-08 |      20 |
 | List::BinarySearch::PP-10k-num     |     85000 | 12        |               212.93% |              1242.43% | 2.7e-08 |      20 |
 | List::BinarySearch::XS-10k-str     |    980000 |  1        |              3513.63% |                16.25% | 1.6e-09 |      21 |
 | List::BinarySearch::XS-10k-num     |   1134540 |  0.881412 |              4100.90% |                 0.00% |   0     |      22 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                           Rate  List::BinarySearch::PP-10k-str-tie  List::BinarySearch::PP-10k-num-tie  List::BinarySearch::PP-10k-str  List::BinarySearch::PP-10k-num  List::BinarySearch::XS-10k-str  List::BinarySearch::XS-10k-num 
  List::BinarySearch::PP-10k-str-tie    27000/s                                  --                                 -8%                            -62%                            -67%                            -97%                            -97% 
  List::BinarySearch::PP-10k-num-tie    30000/s                                  8%                                  --                            -58%                            -64%                            -97%                            -97% 
  List::BinarySearch::PP-10k-str        71000/s                                164%                                142%                              --                            -14%                            -92%                            -93% 
  List::BinarySearch::PP-10k-num        85000/s                                208%                                183%                             16%                              --                            -91%                            -92% 
  List::BinarySearch::XS-10k-str       980000/s                               3600%                               3300%                           1300%                           1100%                              --                            -11% 
  List::BinarySearch::XS-10k-num      1134540/s                               4097%                               3757%                           1488%                           1261%                             13%                              -- 
 
 Legends:
   List::BinarySearch::PP-10k-num: participant=List::BinarySearch::PP-10k-num
   List::BinarySearch::PP-10k-num-tie: participant=List::BinarySearch::PP-10k-num-tie
   List::BinarySearch::PP-10k-str: participant=List::BinarySearch::PP-10k-str
   List::BinarySearch::PP-10k-str-tie: participant=List::BinarySearch::PP-10k-str-tie
   List::BinarySearch::XS-10k-num: participant=List::BinarySearch::XS-10k-num
   List::BinarySearch::XS-10k-str: participant=List::BinarySearch::XS-10k-str

Benchmark module startup overhead (C<< bencher -m BinarySearch --module-startup >>):

 #table2#
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant            | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | List::BinarySearch::PP |     12    |              5.9  |                 0.00% |                91.67% | 1.4e-05 |      20 |
 | List::BinarySearch::XS |      9.09 |              2.99 |                28.47% |                49.19% | 2.2e-06 |      20 |
 | perl -e1 (baseline)    |      6.1  |              0    |                91.67% |                 0.00% | 2.1e-05 |      20 |
 +------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  LB:P  LB:X  perl -e1 (baseline) 
  LB:P                  83.3/s    --  -24%                 -49% 
  LB:X                 110.0/s   32%    --                 -32% 
  perl -e1 (baseline)  163.9/s   96%   49%                   -- 
 
 Legends:
   LB:P: mod_overhead_time=5.9 participant=List::BinarySearch::PP
   LB:X: mod_overhead_time=2.99 participant=List::BinarySearch::XS
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<List::BinarySearch::XS> is an order of magnitude faster, but does not support
tied arrays. On my laptop, binary searching a tied array is about three times
flower than binary searching a regular array.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-BinarySearch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-BinarySearch>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-BinarySearch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
