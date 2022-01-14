package Bencher::Scenario::ArrayVsHashBuilding;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark building array vs hash',
    participants => [
        {
            name=>'array',
            code_template=>'state $elems=<elems>; my $ary = []; for my $elem (@$elems) { push @$ary, $elems }; $ary',
        },
        {
            name=>'hash',
            code_template=>'state $elems=<elems>; my $hash = {}; for my $elem (@$elems) { $hash->{$elem} = 1 }; $hash',
        },
    ],
    datasets => [
        {name=>'elems=1'    , args=>{elems=>[1]}},
        {name=>'elems=10'   , args=>{elems=>[1..10]}},
        {name=>'elems=100'  , args=>{elems=>[1..100]}},
        {name=>'elems=1000' , args=>{elems=>[1..1000]}},
        {name=>'elems=10000', args=>{elems=>[1..10000]}},
    ],
};

1;
# ABSTRACT: Benchmark building array vs hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArrayVsHashBuilding - Benchmark building array vs hash

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::ArrayVsHashBuilding (from Perl distribution Bencher-Scenario-ArrayVsHashBuilding), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArrayVsHashBuilding

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * array (perl_code)

Code template:

 state $elems=<elems>; my $ary = []; for my $elem (@$elems) { push @$ary, $elems }; $ary



=item * hash (perl_code)

Code template:

 state $elems=<elems>; my $hash = {}; for my $elem (@$elems) { $hash->{$elem} = 1 }; $hash



=back

=head1 BENCHMARK DATASETS

=over

=item * elems=1

=item * elems=10

=item * elems=100

=item * elems=1000

=item * elems=10000

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m ArrayVsHashBuilding

Result formatted as table:

 #table1#
 | participant | dataset     | rate (/s) | time (μs)   | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |-------------+-------------+-----------+-------------+-----------------------+-----------------------+---------+---------|
 | hash        | elems=10000 |       740 | 1300        |                 0.00% |            641955.16% | 1.4e-06 |      20 |
 | array       | elems=10000 |      1960 |  510        |               164.40% |            242732.24% | 2.6e-07 |      21 |
 | hash        | elems=1000  |      8200 |  120        |               999.66% |             58286.54% | 2.1e-07 |      20 |
 | array       | elems=1000  |     19434 |   51.4562   |              2518.03% |             24424.33% | 5.8e-12 |      20 |
 | hash        | elems=100   |     95200 |   10.5      |             12727.28% |              4905.39% | 3.3e-09 |      21 |
 | array       | elems=100   |    159000 |    6.31     |             21252.27% |              2906.96% | 3.2e-09 |      22 |
 | hash        | elems=10    |    844360 |    1.1843   |            113647.15% |               464.46% | 5.8e-12 |      20 |
 | array       | elems=10    |   1191880 |    0.839009 |            160463.55% |               299.88% |   0     |      20 |
 | hash        | elems=1     |   3958000 |    0.2527   |            533044.34% |                20.43% | 5.7e-12 |      20 |
 | array       | elems=1     |   4766000 |    0.2098   |            641955.16% |                 0.00% | 5.8e-12 |      20 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  hash elems=10000  array elems=10000  hash elems=1000  array elems=1000  hash elems=100  array elems=100  hash elems=10  array elems=10  hash elems=1  array elems=1 
  hash elems=10000       740/s                --               -60%             -90%              -96%            -99%             -99%           -99%            -99%          -99%           -99% 
  array elems=10000     1960/s              154%                 --             -76%              -89%            -97%             -98%           -99%            -99%          -99%           -99% 
  hash elems=1000       8200/s              983%               325%               --              -57%            -91%             -94%           -99%            -99%          -99%           -99% 
  array elems=1000     19434/s             2426%               891%             133%                --            -79%             -87%           -97%            -98%          -99%           -99% 
  hash elems=100       95200/s            12280%              4757%            1042%              390%              --             -39%           -88%            -92%          -97%           -98% 
  array elems=100     159000/s            20502%              7982%            1801%              715%             66%               --           -81%            -86%          -95%           -96% 
  hash elems=10       844360/s           109669%             42963%           10032%             4244%            786%             432%             --            -29%          -78%           -82% 
  array elems=10     1191880/s           154844%             60685%           14202%             6032%           1151%             652%            41%              --          -69%           -74% 
  hash elems=1       3958000/s           514344%            201720%           47387%            20262%           4055%            2397%           368%            232%            --           -16% 
  array elems=1      4766000/s           619537%            242988%           57097%            24426%           4904%            2907%           464%            299%           20%             -- 
 
 Legends:
   array elems=1: dataset=elems=1 participant=array
   array elems=10: dataset=elems=10 participant=array
   array elems=100: dataset=elems=100 participant=array
   array elems=1000: dataset=elems=1000 participant=array
   array elems=10000: dataset=elems=10000 participant=array
   hash elems=1: dataset=elems=1 participant=hash
   hash elems=10: dataset=elems=10 participant=hash
   hash elems=100: dataset=elems=100 participant=hash
   hash elems=1000: dataset=elems=1000 participant=hash
   hash elems=10000: dataset=elems=10000 participant=hash

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (@netbook-zenbook-ux305)

perlancar (@netbook-zenbook-ux305) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ArrayVsHashBuilding>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ArrayVsHashBuilding>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ArrayVsHashBuilding>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::HashBuilding>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
