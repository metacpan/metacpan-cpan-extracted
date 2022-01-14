package Bencher::Scenario::Allocations;

our $DATE = '2021-07-31'; # DATE
our $VERSION = '0.040'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark allocations',

    descriptions => <<'_',

This scenario tries to give a picture on how long it takes to allocate arrays
and hashes of various size take.

_
    participants => [
        {name=>'1k-array0'  , summary => 'Allocating empty array 1000 times'      , code_template=>'my $val; for (1..1000) { $val = [] }'},
        {name=>'1k-hash0'   , summary => 'Allocating empty hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {} }'},
        {name=>'1k-array1'  , summary => 'Allocating 1-element array 1000 times'  , code_template=>'my $val; for (1..1000) { $val = [1] }'},
        {name=>'1k-hash1'   , summary => 'Allocating 1-key hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {a=>1} }'},
        {name=>'1k-array5'  , summary => 'Allocating 5-element array 1000 times'  , code_template=>'my $val; for (1..1000) { $val = [1..5] }'},
        {name=>'1k-hash5'   , summary => 'Allocating 5-key hash 1000 times'       , code_template=>'my $val; for (1..1000) { $val = {a=>1, b=>2, c=>3, d=>4, e=>5} }'},
        {name=>'1k-array10' , summary => 'Allocating 10-element array 1000 times' , code_template=>'my $val; for (1..1000) { $val = [1..10] }'},
        {name=>'1k-hash10'  , summary => 'Allocating 10-key hash 1000 times'      , code_template=>'my $val; for (1..1000) { $val = {1..20} }'},
        {name=>'1k-array100', summary => 'Allocating 100-element array 1000 times', code_template=>'my $val; for (1..1000) { $val = [1..100] }'},
        {name=>'1k-hash100' , summary => 'Allocating 100-key hash 1000 times'     , code_template=>'my $val; for (1..1000) { $val = {1..200} }'},
    ],
};

1;
# ABSTRACT: Benchmark allocations

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Allocations - Benchmark allocations

=head1 VERSION

This document describes version 0.040 of Bencher::Scenario::Allocations (from Perl distribution Bencher-Scenario-Allocations), released on 2021-07-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Allocations

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k-array0 (perl_code)

Allocating empty array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [] }



=item * 1k-hash0 (perl_code)

Allocating empty hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {} }



=item * 1k-array1 (perl_code)

Allocating 1-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1] }



=item * 1k-hash1 (perl_code)

Allocating 1-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {a=>1} }



=item * 1k-array5 (perl_code)

Allocating 5-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..5] }



=item * 1k-hash5 (perl_code)

Allocating 5-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {a=>1, b=>2, c=>3, d=>4, e=>5} }



=item * 1k-array10 (perl_code)

Allocating 10-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..10] }



=item * 1k-hash10 (perl_code)

Allocating 10-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {1..20} }



=item * 1k-array100 (perl_code)

Allocating 100-element array 1000 times.

Code template:

 my $val; for (1..1000) { $val = [1..100] }



=item * 1k-hash100 (perl_code)

Allocating 100-key hash 1000 times.

Code template:

 my $val; for (1..1000) { $val = {1..200} }



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m Allocations

Result formatted as table:

 #table1#
 | participant | rate (/s) |  time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 |-------------+-----------+------------+-----------------------+-----------------------+---------+---------|
 | 1k-hash100  |   150     | 6.5        |                 0.00% |              8882.72% | 6.8e-06 |      20 |
 | 1k-array100 |   813     | 1.23       |               427.13% |              1604.08% |   2e-07 |      23 |
 | 1k-hash10   |  1370     | 0.728      |               791.05% |               908.10% | 1.6e-07 |      20 |
 | 1k-hash5    |  2680     | 0.372      |              1640.85% |               416.00% |   5e-08 |      23 |
 | 1k-array10  |  4293.021 | 0.2329362  |              2683.74% |               222.68% | 5.7e-12 |      22 |
 | 1k-hash1    |  5900     | 0.17       |              3743.94% |               133.69% | 2.1e-07 |      21 |
 | 1k-array5   |  6190     | 0.162      |              3913.30% |               123.82% | 1.6e-07 |      21 |
 | 1k-array1   |  9803.81  | 0.102001   |              6257.13% |                41.30% |   0     |      20 |
 | 1k-hash0    | 12204.32  | 0.08193819 |              7813.71% |                13.51% | 5.7e-12 |      20 |
 | 1k-array0   | 13852.9   | 0.0721869  |              8882.72% |                 0.00% |   0     |      20 |


The above result formatted in L<Benchmark.pm|Benchmark> style:

                     Rate  1k-hash100  1k-array100  1k-hash10  1k-hash5  1k-array10  1k-hash1  1k-array5  1k-array1  1k-hash0  1k-array0 
  1k-hash100        150/s          --         -81%       -88%      -94%        -96%      -97%       -97%       -98%      -98%       -98% 
  1k-array100       813/s        428%           --       -40%      -69%        -81%      -86%       -86%       -91%      -93%       -94% 
  1k-hash10        1370/s        792%          68%         --      -48%        -68%      -76%       -77%       -85%      -88%       -90% 
  1k-hash5         2680/s       1647%         230%        95%        --        -37%      -54%       -56%       -72%      -77%       -80% 
  1k-array10   4293.021/s       2690%         428%       212%       59%          --      -27%       -30%       -56%      -64%       -69% 
  1k-hash1         5900/s       3723%         623%       328%      118%         37%        --        -4%       -39%      -51%       -57% 
  1k-array5        6190/s       3912%         659%       349%      129%         43%        4%         --       -37%      -49%       -55% 
  1k-array1     9803.81/s       6272%        1105%       613%      264%        128%       66%        58%         --      -19%       -29% 
  1k-hash0     12204.32/s       7832%        1401%       788%      354%        184%      107%        97%        24%        --       -11% 
  1k-array0     13852.9/s       8904%        1603%       908%      415%        222%      135%       124%        41%       13%         -- 
 
 Legends:
   1k-array0: participant=1k-array0
   1k-array1: participant=1k-array1
   1k-array10: participant=1k-array10
   1k-array100: participant=1k-array100
   1k-array5: participant=1k-array5
   1k-hash0: participant=1k-hash0
   1k-hash1: participant=1k-hash1
   1k-hash10: participant=1k-hash10
   1k-hash100: participant=1k-hash100
   1k-hash5: participant=1k-hash5

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 CONTRIBUTOR

=for stopwords perlancar (@pc-office)

perlancar (@pc-office) <perlancar@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Allocations>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Allocations>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Allocations>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
