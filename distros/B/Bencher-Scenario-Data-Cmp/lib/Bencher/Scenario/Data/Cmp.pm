package Bencher::Scenario::Data::Cmp;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenario-Data-Cmp'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark Data::Cmp against similar solutions',
    participants => [
        {
            fcall_template => 'Data::Cmp::cmp_data(<data1>, <data2>)',
        },
        {
            fcall_template => 'Data::Cmp::Numeric::cmp_data(<data1>, <data2>)',
        },
        {
            fcall_template => 'Data::Cmp::StrOrNumeric::cmp_data(<data1>, <data2>)',
        },
        {
            module => 'JSON::PP',
            code_template => 'JSON::PP::encode_json(<data1>) eq JSON::PP::encode_json(<data2>)',
        },
        {
            fcall_template => 'Data::Compare::Compare(<data1>, <data2>)',
        },
    ],

    datasets => [
        {
            name=>'empty arrays',
            args=>{
                data1=>[],
                data2=>[],
            },
        },
        {
            name=>'small arrays',
            args=>{
                data1=>[1,2,[],3,4],
                data2=>[1,2,[],5,4],
            },
        },
        {
            name=>'1k array of ints',
            args=>{
                data1=>[1..1000],
                data2=>[1..1000],
            },
        },
    ],
};

1;
# ABSTRACT: Benchmark Data::Cmp against similar solutions

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Cmp - Benchmark Data::Cmp against similar solutions

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Data::Cmp (from Perl distribution Bencher-Scenario-Data-Cmp), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Cmp

To run module startup overhead benchmark:

 % bencher --module-startup -m Data::Cmp

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Cmp> 0.007

L<Data::Cmp::Numeric> 0.007

L<Data::Cmp::StrOrNumeric> 0.007

L<JSON::PP> 4.06

L<Data::Compare> 1.27

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::Cmp::cmp_data (perl_code)

Function call template:

 Data::Cmp::cmp_data(<data1>, <data2>)



=item * Data::Cmp::Numeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::Numeric::cmp_data(<data1>, <data2>)



=item * Data::Cmp::StrOrNumeric::cmp_data (perl_code)

Function call template:

 Data::Cmp::StrOrNumeric::cmp_data(<data1>, <data2>)



=item * JSON::PP (perl_code)

Code template:

 JSON::PP::encode_json(<data1>) eq JSON::PP::encode_json(<data2>)



=item * Data::Compare::Compare (perl_code)

Function call template:

 Data::Compare::Compare(<data1>, <data2>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty arrays

=item * small arrays

=item * 1k array of ints

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Cmp >>):

 #table1#
 +-----------------------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | participant                       | dataset          | rate (/s) |  time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+
 | Data::Compare::Compare            | 1k array of ints |     410   | 2.4        |                 0.00% |            114055.54% | 5.2e-06 |      21 |
 | JSON::PP                          | 1k array of ints |     525   | 1.91       |                26.97% |             89810.83% | 4.3e-07 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | 1k array of ints |    1120   | 0.892      |               171.26% |             41983.64% | 2.1e-07 |      20 |
 | Data::Cmp::Numeric::cmp_data      | 1k array of ints |    1470   | 0.682      |               254.94% |             32062.07% | 2.5e-07 |      22 |
 | Data::Cmp::cmp_data               | 1k array of ints |    1480   | 0.676      |               257.77% |             31807.86% | 2.1e-07 |      20 |
 | Data::Compare::Compare            | small arrays     |   45000   | 0.022      |             10722.71% |               954.78% | 2.7e-08 |      20 |
 | JSON::PP                          | small arrays     |   65344.2 | 0.0153036  |             15713.54% |               621.88% |   0     |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | small arrays     |  137000   | 0.00732    |             32945.76% |               245.45% | 3.1e-09 |      23 |
 | Data::Cmp::Numeric::cmp_data      | small arrays     |  150669   | 0.00663705 |             36362.51% |               213.08% |   0     |      20 |
 | Data::Cmp::cmp_data               | small arrays     |  150000   | 0.0066     |             36518.71% |               211.74% |   1e-08 |      20 |
 | Data::Compare::Compare            | empty arrays     |  200000   | 0.005      |             48614.60% |               134.34% | 6.7e-09 |      20 |
 | JSON::PP                          | empty arrays     |  223767   | 0.00446893 |             54052.50% |               110.80% |   0     |      20 |
 | Data::Cmp::cmp_data               | empty arrays     |  460000   | 0.0022     |            110640.32% |                 3.08% | 3.3e-09 |      20 |
 | Data::Cmp::Numeric::cmp_data      | empty arrays     |  466000   | 0.00214    |            112756.31% |                 1.15% | 8.3e-10 |      20 |
 | Data::Cmp::StrOrNumeric::cmp_data | empty arrays     |  470000   | 0.0021     |            114055.54% |                 0.00% | 3.3e-09 |      20 |
 +-----------------------------------+------------------+-----------+------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                 Rate  DC:C 1k array of ints  J:P 1k array of ints  DCS:c_d 1k array of ints  DCN:c_d 1k array of ints  DC:c_d 1k array of ints  DC:C small arrays  J:P small arrays  DCS:c_d small arrays  DCN:c_d small arrays  DC:c_d small arrays  DC:C empty arrays  J:P empty arrays  DC:c_d empty arrays  DCN:c_d empty arrays  DCS:c_d empty arrays 
  DC:C 1k array of ints         410/s                     --                  -20%                      -62%                      -71%                     -71%               -99%              -99%                  -99%                  -99%                 -99%               -99%              -99%                 -99%                  -99%                  -99% 
  J:P 1k array of ints          525/s                    25%                    --                      -53%                      -64%                     -64%               -98%              -99%                  -99%                  -99%                 -99%               -99%              -99%                 -99%                  -99%                  -99% 
  DCS:c_d 1k array of ints     1120/s                   169%                  114%                        --                      -23%                     -24%               -97%              -98%                  -99%                  -99%                 -99%               -99%              -99%                 -99%                  -99%                  -99% 
  DCN:c_d 1k array of ints     1470/s                   251%                  180%                       30%                        --                       0%               -96%              -97%                  -98%                  -99%                 -99%               -99%              -99%                 -99%                  -99%                  -99% 
  DC:c_d 1k array of ints      1480/s                   255%                  182%                       31%                        0%                       --               -96%              -97%                  -98%                  -99%                 -99%               -99%              -99%                 -99%                  -99%                  -99% 
  DC:C small arrays           45000/s                 10809%                 8581%                     3954%                     3000%                    2972%                 --              -30%                  -66%                  -69%                 -70%               -77%              -79%                 -90%                  -90%                  -90% 
  J:P small arrays          65344.2/s                 15582%                12380%                     5728%                     4356%                    4317%                43%                --                  -52%                  -56%                 -56%               -67%              -70%                 -85%                  -86%                  -86% 
  DCS:c_d small arrays       137000/s                 32686%                25992%                    12085%                     9216%                    9134%               200%              109%                    --                   -9%                  -9%               -31%              -38%                 -69%                  -70%                  -71% 
  DCN:c_d small arrays       150669/s                 36060%                28677%                    13339%                    10175%                   10085%               231%              130%                   10%                    --                   0%               -24%              -32%                 -66%                  -67%                  -68% 
  DC:c_d small arrays        150000/s                 36263%                28839%                    13415%                    10233%                   10142%               233%              131%                   10%                    0%                   --               -24%              -32%                 -66%                  -67%                  -68% 
  DC:C empty arrays          200000/s                 47900%                38100%                    17740%                    13540%                   13420%               339%              206%                   46%                   32%                  32%                 --              -10%                 -56%                  -57%                  -58% 
  J:P empty arrays           223767/s                 53604%                42639%                    19860%                    15160%                   15026%               392%              242%                   63%                   48%                  47%                11%                --                 -50%                  -52%                  -53% 
  DC:c_d empty arrays        460000/s                108990%                86718%                    40445%                    30900%                   30627%               899%              595%                  232%                  201%                 200%               127%              103%                   --                   -2%                   -4% 
  DCN:c_d empty arrays       466000/s                112049%                89152%                    41582%                    31769%                   31488%               928%              615%                  242%                  210%                 208%               133%              108%                   2%                    --                   -1% 
  DCS:c_d empty arrays       470000/s                114185%                90852%                    42376%                    32376%                   32090%               947%              628%                  248%                  216%                 214%               138%              112%                   4%                    1%                    -- 
 
 Legends:
   DC:C 1k array of ints: dataset=1k array of ints participant=Data::Compare::Compare
   DC:C empty arrays: dataset=empty arrays participant=Data::Compare::Compare
   DC:C small arrays: dataset=small arrays participant=Data::Compare::Compare
   DC:c_d 1k array of ints: dataset=1k array of ints participant=Data::Cmp::cmp_data
   DC:c_d empty arrays: dataset=empty arrays participant=Data::Cmp::cmp_data
   DC:c_d small arrays: dataset=small arrays participant=Data::Cmp::cmp_data
   DCN:c_d 1k array of ints: dataset=1k array of ints participant=Data::Cmp::Numeric::cmp_data
   DCN:c_d empty arrays: dataset=empty arrays participant=Data::Cmp::Numeric::cmp_data
   DCN:c_d small arrays: dataset=small arrays participant=Data::Cmp::Numeric::cmp_data
   DCS:c_d 1k array of ints: dataset=1k array of ints participant=Data::Cmp::StrOrNumeric::cmp_data
   DCS:c_d empty arrays: dataset=empty arrays participant=Data::Cmp::StrOrNumeric::cmp_data
   DCS:c_d small arrays: dataset=small arrays participant=Data::Cmp::StrOrNumeric::cmp_data
   J:P 1k array of ints: dataset=1k array of ints participant=JSON::PP
   J:P empty arrays: dataset=empty arrays participant=JSON::PP
   J:P small arrays: dataset=small arrays participant=JSON::PP

Benchmark module startup overhead (C<< bencher -m Data::Cmp --module-startup >>):

 #table2#
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant             | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Data::Compare           |     28.3  |             22.3  |                 0.00% |               370.57% | 2.1e-05 |      20 |
 | JSON::PP                |     20.1  |             14.1  |                40.59% |               234.71% | 6.2e-06 |      20 |
 | Data::Cmp::StrOrNumeric |     10    |              4    |               183.55% |                65.96% |   1e-05 |      20 |
 | Data::Cmp               |      9.94 |              3.94 |               184.68% |                65.30% | 9.4e-06 |      20 |
 | Data::Cmp::Numeric      |      9.93 |              3.93 |               184.92% |                65.16% | 5.1e-06 |      20 |
 | perl -e1 (baseline)     |      6    |              0    |               370.57% |                 0.00% | 6.8e-06 |      21 |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                              Rate  Data::Compare  JSON::PP  Data::Cmp::StrOrNumeric  Data::Cmp  Data::Cmp::Numeric  perl -e1 (baseline) 
  Data::Compare             35.3/s             --      -28%                     -64%       -64%                -64%                 -78% 
  JSON::PP                  49.8/s            40%        --                     -50%       -50%                -50%                 -70% 
  Data::Cmp::StrOrNumeric  100.0/s           183%      101%                       --         0%                  0%                 -40% 
  Data::Cmp                100.6/s           184%      102%                       0%         --                  0%                 -39% 
  Data::Cmp::Numeric       100.7/s           184%      102%                       0%         0%                  --                 -39% 
  perl -e1 (baseline)      166.7/s           371%      235%                      66%        65%                 65%                   -- 
 
 Legends:
   Data::Cmp: mod_overhead_time=3.94 participant=Data::Cmp
   Data::Cmp::Numeric: mod_overhead_time=3.93 participant=Data::Cmp::Numeric
   Data::Cmp::StrOrNumeric: mod_overhead_time=4 participant=Data::Cmp::StrOrNumeric
   Data::Compare: mod_overhead_time=22.3 participant=Data::Compare
   JSON::PP: mod_overhead_time=14.1 participant=JSON::PP
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Data-Cmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Data-Cmp>.

=head1 SEE ALSO

L<Bencher::Scenario::Scalar::Cmp>

L<Bencher::Scenario::Serializers>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Data-Cmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
