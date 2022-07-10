package Bencher::Scenario::Array::Sample::WeightedRandom::nocopy_algo;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-21'; # DATE
our $DIST = 'Bencher-Scenarios-Array-Sample-WeightedRandom'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => "Benchmark the nocopy algorithm",
    participants => [
        {name=>'nocopy', fcall_template=>'Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(<ary>, <n>, {algo=>"nocopy"})'},
        {name=>'copy'  , fcall_template=>'Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(<ary>, <n>, {algo=>"copy"}  )'},
    ],
    datasets => [
        {name=>'empty'           , args=>{ary=>[], n=>1}},

        #{name=>'ary=25 n=1'      , args=>{ary=>[map {[$_=>1]} 1..25], n=>1}},
        {name=>'ary=25 n=2'      , args=>{ary=>[map {[$_=>1]} 1..25], n=>2}},
        {name=>'ary=25 n=10'     , args=>{ary=>[map {[$_=>1]} 1..25], n=>10}},

        #{name=>'ary=1000 n=1'    , args=>{ary=>[map {[$_=>1]} 1..1000], n=>1}},
        {name=>'ary=1000 n=2'    , args=>{ary=>[map {[$_=>1]} 1..1000], n=>2}},
        {name=>'ary=1000 n=200'  , args=>{ary=>[map {[$_=>1]} 1..1000], n=>200}},

        {name=>'ary=100_000 n=2' , args=>{ary=>[map {[$_=>1]} 1..100_000], n=>2}},
    ],
};

1;
# ABSTRACT: Benchmark the nocopy algorithm

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Array::Sample::WeightedRandom::nocopy_algo - Benchmark the nocopy algorithm

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Array::Sample::WeightedRandom::nocopy_algo (from Perl distribution Bencher-Scenarios-Array-Sample-WeightedRandom), released on 2022-05-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Array::Sample::WeightedRandom::nocopy_algo

To run module startup overhead benchmark:

 % bencher --module-startup -m Array::Sample::WeightedRandom::nocopy_algo

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Sample::WeightedRandom> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * nocopy (perl_code)

Function call template:

 Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(<ary>, <n>, {algo=>"nocopy"})



=item * copy (perl_code)

Function call template:

 Array::Sample::WeightedRandom::sample_weighted_random_no_replacement(<ary>, <n>, {algo=>"copy"}  )



=back

=head1 BENCHMARK DATASETS

=over

=item * empty

=item * ary=25 n=2

=item * ary=25 n=10

=item * ary=1000 n=2

=item * ary=1000 n=200

=item * ary=100_000 n=2

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Array::Sample::WeightedRandom::nocopy_algo >>):

 #table1#
 +-------------+-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant | dataset         | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------+-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | nocopy      | ary=100_000 n=2 |        10 |  80       |                 0.00% |           7876847.01% |   0.0014  |      20 |
 | copy        | ary=100_000 n=2 |        10 |  70       |                 6.07% |           7425757.21% |   0.0023  |      20 |
 | nocopy      | ary=1000 n=200  |        32 |  31       |               143.88% |           3229757.64% |   0.00019 |      20 |
 | copy        | ary=1000 n=200  |        56 |  18       |               324.79% |           1854221.67% |   0.00015 |      20 |
 | copy        | ary=1000 n=2    |      2000 |   0.5     |             15917.72% |             49076.45% | 1.8e-05   |      20 |
 | nocopy      | ary=1000 n=2    |      2000 |   0.4     |             17153.98% |             45552.92% | 1.6e-05   |      20 |
 | nocopy      | ary=25 n=10     |     18000 |   0.055   |            136784.00% |              5654.47% | 3.9e-07   |      21 |
 | copy        | ary=25 n=10     |     28000 |   0.036   |            212258.09% |              3609.28% | 1.6e-07   |      20 |
 | nocopy      | ary=25 n=2      |     64000 |   0.016   |            484109.60% |              1526.76% | 5.3e-08   |      20 |
 | copy        | ary=25 n=2      |     71000 |   0.014   |            537020.95% |              1366.51% | 1.1e-07   |      20 |
 | copy        | empty           |    961000 |   0.00104 |           7252294.69% |                 8.61% | 3.5e-10   |      28 |
 | nocopy      | empty           |   1000000 |   0.00096 |           7876847.01% |                 0.00% | 1.3e-09   |      20 |
 +-------------+-----------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                               Rate  nocopy ary=100_000 n=2  copy ary=100_000 n=2  nocopy ary=1000 n=200  copy ary=1000 n=200  copy ary=1000 n=2  nocopy ary=1000 n=2  nocopy ary=25 n=10  copy ary=25 n=10  nocopy ary=25 n=2  copy ary=25 n=2  copy empty  nocopy empty 
  nocopy ary=100_000 n=2       10/s                      --                  -12%                   -61%                 -77%               -99%                 -99%                -99%              -99%               -99%             -99%        -99%          -99% 
  copy ary=100_000 n=2         10/s                     14%                    --                   -55%                 -74%               -99%                 -99%                -99%              -99%               -99%             -99%        -99%          -99% 
  nocopy ary=1000 n=200        32/s                    158%                  125%                     --                 -41%               -98%                 -98%                -99%              -99%               -99%             -99%        -99%          -99% 
  copy ary=1000 n=200          56/s                    344%                  288%                    72%                   --               -97%                 -97%                -99%              -99%               -99%             -99%        -99%          -99% 
  copy ary=1000 n=2          2000/s                  15900%                13900%                  6100%                3500%                 --                 -19%                -89%              -92%               -96%             -97%        -99%          -99% 
  nocopy ary=1000 n=2        2000/s                  19900%                17400%                  7650%                4400%                25%                   --                -86%              -91%               -96%             -96%        -99%          -99% 
  nocopy ary=25 n=10        18000/s                 145354%               127172%                 56263%               32627%               809%                 627%                  --              -34%               -70%             -74%        -98%          -98% 
  copy ary=25 n=10          28000/s                 222122%               194344%                 86011%               49900%              1288%                1011%                 52%                --               -55%             -61%        -97%          -97% 
  nocopy ary=25 n=2         64000/s                 499900%               437400%                193650%              112400%              3025%                2400%                243%              125%                 --             -12%        -93%          -94% 
  copy ary=25 n=2           71000/s                 571328%               499900%                221328%              128471%              3471%                2757%                292%              157%                14%               --        -92%          -93% 
  copy empty               961000/s                7692207%              6730669%               2980669%             1730669%             47976%               38361%               5188%             3361%              1438%            1246%          --           -7% 
  nocopy empty            1000000/s                8333233%              7291566%               3229066%             1874900%             51983%               41566%               5629%             3649%              1566%            1358%          8%            -- 
 
 Legends:
   copy ary=1000 n=2: dataset=ary=1000 n=2 participant=copy
   copy ary=1000 n=200: dataset=ary=1000 n=200 participant=copy
   copy ary=100_000 n=2: dataset=ary=100_000 n=2 participant=copy
   copy ary=25 n=10: dataset=ary=25 n=10 participant=copy
   copy ary=25 n=2: dataset=ary=25 n=2 participant=copy
   copy empty: dataset=empty participant=copy
   nocopy ary=1000 n=2: dataset=ary=1000 n=2 participant=nocopy
   nocopy ary=1000 n=200: dataset=ary=1000 n=200 participant=nocopy
   nocopy ary=100_000 n=2: dataset=ary=100_000 n=2 participant=nocopy
   nocopy ary=25 n=10: dataset=ary=25 n=10 participant=nocopy
   nocopy ary=25 n=2: dataset=ary=25 n=2 participant=nocopy
   nocopy empty: dataset=empty participant=nocopy

Benchmark module startup overhead (C<< bencher -m Array::Sample::WeightedRandom::nocopy_algo --module-startup >>):

 #table2#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Array::Sample::WeightedRandom |      13.6 |               2.6 |                 0.00% |                21.97% | 8.5e-06 |      20 |
 | perl -e1 (baseline)           |      11   |               0   |                21.97% |                 0.00% | 1.4e-05 |      20 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                         Rate  AS:W  perl -e1 (baseline) 
  AS:W                 73.5/s    --                 -19% 
  perl -e1 (baseline)  90.9/s   23%                   -- 
 
 Legends:
   AS:W: mod_overhead_time=2.6 participant=Array::Sample::WeightedRandom
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Array-Sample-WeightedRandom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Array-Sample-WeightedRandom>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Array-Sample-WeightedRandom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
