package Bencher::Scenario::DataSahResolve::Resolve;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'Bencher-Scenarios-DataSahResolve'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Sah::Schema::poseven; # to pull dependency
use Sah::Schema::posint;  # to pull dependency

our $scenario = {
    summary => 'Benchmark resolving',
    participants => [
        {
            fcall_template => 'Data::Sah::Resolve::resolve_schema(<schema>)',
        },
    ],

    datasets => [
        {name=>"int"           , args=>{schema=>'int'}},
        {name=>"posint"        , args=>{schema=>'posint'}},
        {name=>"poseven"       , args=>{schema=>'poseven'}},
    ],
};

1;
# ABSTRACT: Benchmark resolving

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DataSahResolve::Resolve - Benchmark resolving

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DataSahResolve::Resolve (from Perl distribution Bencher-Scenarios-DataSahResolve), released on 2021-08-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DataSahResolve::Resolve

To run module startup overhead benchmark:

 % bencher --module-startup -m DataSahResolve::Resolve

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah::Resolve> 0.011

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Sah::Resolve::resolve_schema (perl_code)

Function call template:

 Data::Sah::Resolve::resolve_schema(<schema>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * posint

=item * poseven

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command:

 % bencher -m DataSahResolve::Resolve --include-path archive/Data-Sah-Resolve-0.008/lib --include-path archive/Data-Sah-Resolve-0.011/lib --multimodver Data::Sah::Resolve

Result formatted as table:

 #table1#
 +---------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset | modver | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | poseven | 0.011  |     20000 |      49   |                 0.00% |              1869.65% | 1.1e-07 |      20 |
 | poseven | 0.008  |     22000 |      44   |                10.77% |              1678.22% | 5.1e-08 |      22 |
 | posint  | 0.011  |     35000 |      28   |                73.03% |              1038.29% | 5.3e-08 |      20 |
 | posint  | 0.008  |     43000 |      23.3 |               111.78% |               830.03% | 6.7e-09 |      20 |
 | int     | 0.011  |    210000 |       4.9 |               915.20% |                94.02% | 4.9e-09 |      21 |
 | int     | 0.008  |    400000 |       2.5 |              1869.65% |                 0.00% | 4.2e-09 |      20 |
 +---------+--------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

               Rate  poseven  poseven  posint  posint   int   int 
  poseven   20000/s       --     -10%    -42%    -52%  -90%  -94% 
  poseven   22000/s      11%       --    -36%    -47%  -88%  -94% 
  posint    35000/s      75%      57%      --    -16%  -82%  -91% 
  posint    43000/s     110%      88%     20%      --  -78%  -89% 
  int      210000/s     900%     797%    471%    375%    --  -48% 
  int      400000/s    1860%    1660%   1019%    832%   96%    -- 
 
 Legends:
   int: dataset=int modver=0.008
   poseven: dataset=poseven modver=0.008
   posint: dataset=posint modver=0.008

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m DataSahResolve::Resolve --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Sah::Resolve  |         8 |                 4 |                 0.00% |                73.07% | 0.00027 |      21 |
 | perl -e1 (baseline) |         4 |                 0 |                73.07% |                 0.00% | 0.00014 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  DS:R  perl -e1 (baseline) 
  DS:R                 125.0/s    --                 -50% 
  perl -e1 (baseline)  250.0/s  100%                   -- 
 
 Legends:
   DS:R: mod_overhead_time=4 participant=Data::Sah::Resolve
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

The above result presented as chart:

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSahResolve>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataSahResolve>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSahResolve>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
