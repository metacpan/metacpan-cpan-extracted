package Bencher::Scenario::Data::Sah::Validate;

use strict;

require Data::Sah;
require DateTime;
require Time::Moment;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-Data-Sah'; # DIST
our $VERSION = '0.071'; # VERSION

my $return_types = ['bool', 'str', 'full'];

our $scenario = {
    summary => 'Benchmark validation',
    modules => {
        'Data::Sah' => {version=>'0.84'},
    },
    participants => [
        {
            name => 'gen_validator',
            code_template => 'state $v = Data::Sah::gen_validator(<schema>, {return_type => <return_type>}); $v->(<data>)',
        },
    ],
    datasets => [
        {
            name => 'int',
            args => {
                schema => 'int',
                'data@' => [undef, 1, "a"],
                'return_type@' => $return_types,
            },
        },
        {
            name => 'int*',
            args => {
                schema => 'int*',
                'data@' => [undef, 1, "a"],
                'return_type@' => $return_types,
            },
        },
        {
            name => 'str+2clause',
            args => {
                schema => ['str', min_len=>1, max_len=>5],
                'data@' => [undef, "abc", ""],
                'return_type@' => $return_types,
            },
        },
        {
            name => 'date (coerce to float(epoch))',
            args => {
                schema => ['date'],
                'data@' => [undef, "abc", 1463371843, "2016-05-16", DateTime->now,
                            #Time::Moment->now, # disabled for now, error
                        ],
                'return_type@' => $return_types,
            },
        },
        # XXX: date (coerce to DateTime)
        # XXX: date (coerce to Time::Moment)
    ],
};

1;
# ABSTRACT: Benchmark validation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Data::Sah::Validate - Benchmark validation

=head1 VERSION

This document describes version 0.071 of Bencher::Scenario::Data::Sah::Validate (from Perl distribution Bencher-Scenarios-Data-Sah), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Data::Sah::Validate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::Sah> 0.914

=head1 BENCHMARK PARTICIPANTS

=over

=item * gen_validator (perl_code)

Code template:

 state $v = Data::Sah::gen_validator(<schema>, {return_type => <return_type>}); $v->(<data>)



=back

=head1 BENCHMARK DATASETS

=over

=item * int

=item * int*

=item * str+2clause

=item * date (coerce to float(epoch))

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Data::Sah::Validate >>):

 #table1#
 +-------------------------------+---------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                       | arg_data            | arg_return_type | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+---------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | date (coerce to float(epoch)) | 2023-01-19T07:18:22 | str             |     22000 | 45        |                 0.00% |             30930.60% | 6.7e-08 |      20 |
 | date (coerce to float(epoch)) | 2023-01-19T07:18:22 | full            |     22000 | 45        |                 0.17% |             30876.85% | 5.3e-08 |      20 |
 | date (coerce to float(epoch)) | 2023-01-19T07:18:22 | bool            |     22000 | 44        |                 0.88% |             30659.74% | 1.1e-07 |      20 |
 | date (coerce to float(epoch)) | 2016-05-16          | full            |     98000 | 10        |               339.89% |              6954.16% | 1.7e-08 |      20 |
 | date (coerce to float(epoch)) | 2016-05-16          | str             |    100000 |  9.9      |               353.47% |              6742.85% | 2.6e-08 |      21 |
 | date (coerce to float(epoch)) | 2016-05-16          | bool            |    100000 |  9.6      |               366.67% |              6549.31% | 1.3e-08 |      20 |
 | date (coerce to float(epoch)) | abc                 | full            |    638669 |  1.56576  |              2765.90% |               982.75% |   0     |      20 |
 | date (coerce to float(epoch)) | 1463371843          | full            |    740000 |  1.4      |              3211.12% |               837.16% | 1.7e-09 |      20 |
 | int*                          | a                   | full            |    970000 |  1        |              4231.25% |               616.44% | 1.7e-09 |      20 |
 | int                           | a                   | full            |    967320 |  1.0338   |              4240.65% |               614.88% | 5.8e-12 |      20 |
 | date (coerce to float(epoch)) | 1463371843          | str             |    993170 |  1.0069   |              4356.65% |               596.28% |   5e-12 |      28 |
 | date (coerce to float(epoch)) | 1463371843          | bool            |   1050000 |  0.948    |              4631.57% |               555.82% | 4.2e-10 |      20 |
 | int*                          |                     | full            |   1120000 |  0.896    |              4909.75% |               519.40% | 4.2e-10 |      20 |
 | date (coerce to float(epoch)) | abc                 | str             |   1180000 |  0.849    |              5187.44% |               486.87% | 3.6e-10 |      27 |
 | int*                          | 1                   | full            |   1000000 |  0.8      |              5722.58% |               432.94% | 1.7e-08 |      20 |
 | date (coerce to float(epoch)) | abc                 | bool            |   1300000 |  0.76     |              5835.19% |               422.82% | 1.7e-09 |      20 |
 | int                           | 1                   | full            |   1500000 |  0.666    |              6639.79% |               360.41% | 2.1e-10 |      20 |
 | int                           |                     | full            |   1910000 |  0.524    |              8465.85% |               262.26% |   2e-10 |      22 |
 | date (coerce to float(epoch)) |                     | full            |   1950000 |  0.512    |              8670.75% |               253.80% | 2.1e-10 |      20 |
 | int*                          | a                   | str             |   3140000 |  0.318    |             13998.28% |               120.10% |   1e-10 |      20 |
 | int*                          | 1                   | str             |   3200000 |  0.31     |             14335.08% |               114.97% | 8.3e-10 |      20 |
 | int                           | a                   | str             |   3220000 |  0.31     |             14368.98% |               114.46% |   1e-10 |      20 |
 | int                           | 1                   | str             |   3300000 |  0.3      |             14888.36% |               107.03% | 4.2e-10 |      20 |
 | int*                          | 1                   | bool            |   4000000 |  0.3      |             17785.21% |                73.50% | 2.9e-09 |      24 |
 | int                           | a                   | bool            |   4370000 |  0.229    |             19520.21% |                58.16% |   1e-10 |      20 |
 | int*                          | a                   | bool            |   4432000 |  0.2256   |             19788.13% |                56.03% | 5.7e-12 |      20 |
 | int                           | 1                   | bool            |   4595000 |  0.2176   |             20518.67% |                50.50% | 5.8e-12 |      20 |
 | str+2clause                   | abc                 | bool            |   4599000 |  0.2175   |             20535.56% |                50.37% | 5.8e-12 |      20 |
 | int*                          |                     | str             |   4600010 |  0.217391 |             20541.62% |                50.33% |   0     |      20 |
 | date (coerce to float(epoch)) |                     | str             |   4800000 |  0.208    |             21440.98% |                44.05% | 9.9e-11 |      24 |
 | int                           |                     | str             |   4908000 |  0.2038   |             21921.51% |                40.91% | 5.8e-12 |      20 |
 | str+2clause                   |                     | bool            |   6530000 |  0.1531   |             29203.95% |                 5.89% | 5.8e-12 |      20 |
 | date (coerce to float(epoch)) |                     | bool            |   6700000 |  0.15     |             30085.22% |                 2.80% | 1.6e-10 |      20 |
 | int*                          |                     | bool            |   6700000 |  0.15     |             30135.32% |                 2.63% | 2.1e-10 |      20 |
 | int                           |                     | bool            |   6900000 |  0.14     |             30930.60% |                 0.00% | 4.7e-10 |      20 |
 +-------------------------------+---------------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                                               Rate  date (coerce to float(epoch)) 2023-01-19T07:18:22 str  date (coerce to float(epoch)) 2023-01-19T07:18:22 full  date (coerce to float(epoch)) 2023-01-19T07:18:22 bool  date (coerce to float(epoch)) 2016-05-16 full  date (coerce to float(epoch)) 2016-05-16 str  date (coerce to float(epoch)) 2016-05-16 bool  date (coerce to float(epoch)) abc full  date (coerce to float(epoch)) 1463371843 full  int a full  date (coerce to float(epoch)) 1463371843 str  int* a full  date (coerce to float(epoch)) 1463371843 bool  int*  full  date (coerce to float(epoch)) abc str  int* 1 full  date (coerce to float(epoch)) abc bool  int 1 full  int  full  date (coerce to float(epoch))  full  int* a str  int* 1 str  int a str  int 1 str  int* 1 bool  int a bool  int* a bool  int 1 bool  str+2clause abc bool  int*  str  date (coerce to float(epoch))  str  int  str  str+2clause  bool  date (coerce to float(epoch))  bool  int*  bool  int  bool 
  date (coerce to float(epoch)) 2023-01-19T07:18:22 str     22000/s                                                     --                                                      0%                                                     -2%                                           -77%                                          -78%                                           -78%                                    -96%                                           -96%        -97%                                          -97%         -97%                                           -97%        -98%                                   -98%         -98%                                    -98%        -98%       -98%                                 -98%        -99%        -99%       -99%       -99%         -99%        -99%         -99%        -99%                  -99%       -99%                                -99%      -99%               -99%                                 -99%        -99%       -99% 
  date (coerce to float(epoch)) 2023-01-19T07:18:22 full    22000/s                                                     0%                                                      --                                                     -2%                                           -77%                                          -78%                                           -78%                                    -96%                                           -96%        -97%                                          -97%         -97%                                           -97%        -98%                                   -98%         -98%                                    -98%        -98%       -98%                                 -98%        -99%        -99%       -99%       -99%         -99%        -99%         -99%        -99%                  -99%       -99%                                -99%      -99%               -99%                                 -99%        -99%       -99% 
  date (coerce to float(epoch)) 2023-01-19T07:18:22 bool    22000/s                                                     2%                                                      2%                                                      --                                           -77%                                          -77%                                           -78%                                    -96%                                           -96%        -97%                                          -97%         -97%                                           -97%        -97%                                   -98%         -98%                                    -98%        -98%       -98%                                 -98%        -99%        -99%       -99%       -99%         -99%        -99%         -99%        -99%                  -99%       -99%                                -99%      -99%               -99%                                 -99%        -99%       -99% 
  date (coerce to float(epoch)) 2016-05-16 full             98000/s                                                   350%                                                    350%                                                    340%                                             --                                           -1%                                            -4%                                    -84%                                           -86%        -89%                                          -89%         -90%                                           -90%        -91%                                   -91%         -92%                                    -92%        -93%       -94%                                 -94%        -96%        -96%       -96%       -97%         -97%        -97%         -97%        -97%                  -97%       -97%                                -97%      -97%               -98%                                 -98%        -98%       -98% 
  date (coerce to float(epoch)) 2016-05-16 str             100000/s                                                   354%                                                    354%                                                    344%                                             1%                                            --                                            -3%                                    -84%                                           -85%        -89%                                          -89%         -89%                                           -90%        -90%                                   -91%         -91%                                    -92%        -93%       -94%                                 -94%        -96%        -96%       -96%       -96%         -96%        -97%         -97%        -97%                  -97%       -97%                                -97%      -97%               -98%                                 -98%        -98%       -98% 
  date (coerce to float(epoch)) 2016-05-16 bool            100000/s                                                   368%                                                    368%                                                    358%                                             4%                                            3%                                             --                                    -83%                                           -85%        -89%                                          -89%         -89%                                           -90%        -90%                                   -91%         -91%                                    -92%        -93%       -94%                                 -94%        -96%        -96%       -96%       -96%         -96%        -97%         -97%        -97%                  -97%       -97%                                -97%      -97%               -98%                                 -98%        -98%       -98% 
  date (coerce to float(epoch)) abc full                   638669/s                                                  2774%                                                   2774%                                                   2710%                                           538%                                          532%                                           513%                                      --                                           -10%        -33%                                          -35%         -36%                                           -39%        -42%                                   -45%         -48%                                    -51%        -57%       -66%                                 -67%        -79%        -80%       -80%       -80%         -80%        -85%         -85%        -86%                  -86%       -86%                                -86%      -86%               -90%                                 -90%        -90%       -91% 
  date (coerce to float(epoch)) 1463371843 full            740000/s                                                  3114%                                                   3114%                                                   3042%                                           614%                                          607%                                           585%                                     11%                                             --        -26%                                          -28%         -28%                                           -32%        -36%                                   -39%         -42%                                    -45%        -52%       -62%                                 -63%        -77%        -77%       -77%       -78%         -78%        -83%         -83%        -84%                  -84%       -84%                                -85%      -85%               -89%                                 -89%        -89%       -90% 
  int a full                                               967320/s                                                  4252%                                                   4252%                                                   4156%                                           867%                                          857%                                           828%                                     51%                                            35%          --                                           -2%          -3%                                            -8%        -13%                                   -17%         -22%                                    -26%        -35%       -49%                                 -50%        -69%        -70%       -70%       -70%         -70%        -77%         -78%        -78%                  -78%       -78%                                -79%      -80%               -85%                                 -85%        -85%       -86% 
  date (coerce to float(epoch)) 1463371843 str             993170/s                                                  4369%                                                   4369%                                                   4269%                                           893%                                          883%                                           853%                                     55%                                            39%          2%                                            --           0%                                            -5%        -11%                                   -15%         -20%                                    -24%        -33%       -47%                                 -49%        -68%        -69%       -69%       -70%         -70%        -77%         -77%        -78%                  -78%       -78%                                -79%      -79%               -84%                                 -85%        -85%       -86% 
  int* a full                                              970000/s                                                  4400%                                                   4400%                                                   4300%                                           900%                                          890%                                           860%                                     56%                                            39%          3%                                            0%           --                                            -5%        -10%                                   -15%         -19%                                    -24%        -33%       -47%                                 -48%        -68%        -69%       -69%       -70%         -70%        -77%         -77%        -78%                  -78%       -78%                                -79%      -79%               -84%                                 -85%        -85%       -86% 
  date (coerce to float(epoch)) 1463371843 bool           1050000/s                                                  4646%                                                   4646%                                                   4541%                                           954%                                          944%                                           912%                                     65%                                            47%          9%                                            6%           5%                                             --         -5%                                   -10%         -15%                                    -19%        -29%       -44%                                 -45%        -66%        -67%       -67%       -68%         -68%        -75%         -76%        -77%                  -77%       -77%                                -78%      -78%               -83%                                 -84%        -84%       -85% 
  int*  full                                              1120000/s                                                  4922%                                                   4922%                                                   4810%                                          1016%                                         1004%                                           971%                                     74%                                            56%         15%                                           12%          11%                                             5%          --                                    -5%         -10%                                    -15%        -25%       -41%                                 -42%        -64%        -65%       -65%       -66%         -66%        -74%         -74%        -75%                  -75%       -75%                                -76%      -77%               -82%                                 -83%        -83%       -84% 
  date (coerce to float(epoch)) abc str                   1180000/s                                                  5200%                                                   5200%                                                   5082%                                          1077%                                         1066%                                          1030%                                     84%                                            64%         21%                                           18%          17%                                            11%          5%                                     --          -5%                                    -10%        -21%       -38%                                 -39%        -62%        -63%       -63%       -64%         -64%        -73%         -73%        -74%                  -74%       -74%                                -75%      -75%               -81%                                 -82%        -82%       -83% 
  int* 1 full                                             1000000/s                                                  5525%                                                   5525%                                                   5400%                                          1150%                                         1137%                                          1099%                                     95%                                            74%         29%                                           25%          25%                                            18%         11%                                     6%           --                                     -5%        -16%       -34%                                 -36%        -60%        -61%       -61%       -62%         -62%        -71%         -71%        -72%                  -72%       -72%                                -74%      -74%               -80%                                 -81%        -81%       -82% 
  date (coerce to float(epoch)) abc bool                  1300000/s                                                  5821%                                                   5821%                                                   5689%                                          1215%                                         1202%                                          1163%                                    106%                                            84%         36%                                           32%          31%                                            24%         17%                                    11%           5%                                      --        -12%       -31%                                 -32%        -58%        -59%       -59%       -60%         -60%        -69%         -70%        -71%                  -71%       -71%                                -72%      -73%               -79%                                 -80%        -80%       -81% 
  int 1 full                                              1500000/s                                                  6656%                                                   6656%                                                   6506%                                          1401%                                         1386%                                          1341%                                    135%                                           110%         55%                                           51%          50%                                            42%         34%                                    27%          20%                                     14%          --       -21%                                 -23%        -52%        -53%       -53%       -54%         -54%        -65%         -66%        -67%                  -67%       -67%                                -68%      -69%               -77%                                 -77%        -77%       -78% 
  int  full                                               1910000/s                                                  8487%                                                   8487%                                                   8296%                                          1808%                                         1789%                                          1732%                                    198%                                           167%         97%                                           92%          90%                                            80%         70%                                    62%          52%                                     45%         27%         --                                  -2%        -39%        -40%       -40%       -42%         -42%        -56%         -56%        -58%                  -58%       -58%                                -60%      -61%               -70%                                 -71%        -71%       -73% 
  date (coerce to float(epoch))  full                     1950000/s                                                  8689%                                                   8689%                                                   8493%                                          1853%                                         1833%                                          1775%                                    205%                                           173%        101%                                           96%          95%                                            85%         75%                                    65%          56%                                     48%         30%         2%                                   --        -37%        -39%       -39%       -41%         -41%        -55%         -55%        -57%                  -57%       -57%                                -59%      -60%               -70%                                 -70%        -70%       -72% 
  int* a str                                              3140000/s                                                 14050%                                                  14050%                                                  13736%                                          3044%                                         3013%                                          2918%                                    392%                                           340%        225%                                          216%         214%                                           198%        181%                                   166%         151%                                    138%        109%        64%                                  61%          --         -2%        -2%        -5%          -5%        -27%         -29%        -31%                  -31%       -31%                                -34%      -35%               -51%                                 -52%        -52%       -55% 
  int* 1 str                                              3200000/s                                                 14416%                                                  14416%                                                  14093%                                          3125%                                         3093%                                          2996%                                    405%                                           351%        233%                                          224%         222%                                           205%        189%                                   173%         158%                                    145%        114%        69%                                  65%          2%          --         0%        -3%          -3%        -26%         -27%        -29%                  -29%       -29%                                -32%      -34%               -50%                                 -51%        -51%       -54% 
  int a str                                               3220000/s                                                 14416%                                                  14416%                                                  14093%                                          3125%                                         3093%                                          2996%                                    405%                                           351%        233%                                          224%         222%                                           205%        189%                                   173%         158%                                    145%        114%        69%                                  65%          2%          0%         --        -3%          -3%        -26%         -27%        -29%                  -29%       -29%                                -32%      -34%               -50%                                 -51%        -51%       -54% 
  int 1 str                                               3300000/s                                                 14900%                                                  14900%                                                  14566%                                          3233%                                         3200%                                          3100%                                    421%                                           366%        244%                                          235%         233%                                           216%        198%                                   183%         166%                                    153%        122%        74%                                  70%          6%          3%         3%         --           0%        -23%         -24%        -27%                  -27%       -27%                                -30%      -32%               -48%                                 -50%        -50%       -53% 
  int* 1 bool                                             4000000/s                                                 14900%                                                  14900%                                                  14566%                                          3233%                                         3200%                                          3100%                                    421%                                           366%        244%                                          235%         233%                                           216%        198%                                   183%         166%                                    153%        122%        74%                                  70%          6%          3%         3%         0%           --        -23%         -24%        -27%                  -27%       -27%                                -30%      -32%               -48%                                 -50%        -50%       -53% 
  int a bool                                              4370000/s                                                 19550%                                                  19550%                                                  19113%                                          4266%                                         4223%                                          4092%                                    583%                                           511%        351%                                          339%         336%                                           313%        291%                                   270%         249%                                    231%        190%       128%                                 123%         38%         35%        35%        31%          31%          --          -1%         -4%                   -5%        -5%                                 -9%      -11%               -33%                                 -34%        -34%       -38% 
  int* a bool                                             4432000/s                                                 19846%                                                  19846%                                                  19403%                                          4332%                                         4288%                                          4155%                                    594%                                           520%        358%                                          346%         343%                                           320%        297%                                   276%         254%                                    236%        195%       132%                                 126%         40%         37%        37%        32%          32%          1%           --         -3%                   -3%        -3%                                 -7%       -9%               -32%                                 -33%        -33%       -37% 
  int 1 bool                                              4595000/s                                                 20580%                                                  20580%                                                  20120%                                          4495%                                         4449%                                          4311%                                    619%                                           543%        375%                                          362%         359%                                           335%        311%                                   290%         267%                                    249%        206%       140%                                 135%         46%         42%        42%        37%          37%          5%           3%          --                    0%         0%                                 -4%       -6%               -29%                                 -31%        -31%       -35% 
  str+2clause abc bool                                    4599000/s                                                 20589%                                                  20589%                                                  20129%                                          4497%                                         4451%                                          4313%                                    619%                                           543%        375%                                          362%         359%                                           335%        311%                                   290%         267%                                    249%        206%       140%                                 135%         46%         42%        42%        37%          37%          5%           3%          0%                    --         0%                                 -4%       -6%               -29%                                 -31%        -31%       -35% 
  int*  str                                               4600010/s                                                 20600%                                                  20600%                                                  20140%                                          4500%                                         4454%                                          4316%                                    620%                                           544%        375%                                          363%         360%                                           336%        312%                                   290%         268%                                    249%        206%       141%                                 135%         46%         42%        42%        38%          38%          5%           3%          0%                    0%         --                                 -4%       -6%               -29%                                 -30%        -30%       -35% 
  date (coerce to float(epoch))  str                      4800000/s                                                 21534%                                                  21534%                                                  21053%                                          4707%                                         4659%                                          4515%                                    652%                                           573%        397%                                          384%         380%                                           355%        330%                                   308%         284%                                    265%        220%       151%                                 146%         52%         49%        49%        44%          44%         10%           8%          4%                    4%         4%                                  --       -2%               -26%                                 -27%        -27%       -32% 
  int  str                                                4908000/s                                                 21980%                                                  21980%                                                  21489%                                          4806%                                         4757%                                          4610%                                    668%                                           586%        407%                                          394%         390%                                           365%        339%                                   316%         292%                                    272%        226%       157%                                 151%         56%         52%        52%        47%          47%         12%          10%          6%                    6%         6%                                  2%        --               -24%                                 -26%        -26%       -31% 
  str+2clause  bool                                       6530000/s                                                 29292%                                                  29292%                                                  28639%                                          6431%                                         6366%                                          6170%                                    922%                                           814%        575%                                          557%         553%                                           519%        485%                                   454%         422%                                    396%        335%       242%                                 234%        107%        102%       102%        95%          95%         49%          47%         42%                   42%        41%                                 35%       33%                 --                                  -2%         -2%        -8% 
  date (coerce to float(epoch))  bool                     6700000/s                                                 29900%                                                  29900%                                                  29233%                                          6566%                                         6500%                                          6300%                                    943%                                           833%        589%                                          571%         566%                                           532%        497%                                   466%         433%                                    406%        344%       249%                                 241%        112%        106%       106%       100%         100%         52%          50%         45%                   44%        44%                                 38%       35%                 2%                                   --          0%        -6% 
  int*  bool                                              6700000/s                                                 29900%                                                  29900%                                                  29233%                                          6566%                                         6500%                                          6300%                                    943%                                           833%        589%                                          571%         566%                                           532%        497%                                   466%         433%                                    406%        344%       249%                                 241%        112%        106%       106%       100%         100%         52%          50%         45%                   44%        44%                                 38%       35%                 2%                                   0%          --        -6% 
  int  bool                                               6900000/s                                                 32042%                                                  32042%                                                  31328%                                          7042%                                         6971%                                          6757%                                   1018%                                           899%        638%                                          619%         614%                                           577%        540%                                   506%         471%                                    442%        375%       274%                                 265%        127%        121%       121%       114%         114%         63%          61%         55%                   55%        55%                                 48%       45%                 9%                                   7%          7%         -- 
 
 Legends:
   date (coerce to float(epoch))  bool: arg_data= arg_return_type=bool dataset=date (coerce to float(epoch))
   date (coerce to float(epoch))  full: arg_data= arg_return_type=full dataset=date (coerce to float(epoch))
   date (coerce to float(epoch))  str: arg_data= arg_return_type=str dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 1463371843 bool: arg_data=1463371843 arg_return_type=bool dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 1463371843 full: arg_data=1463371843 arg_return_type=full dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 1463371843 str: arg_data=1463371843 arg_return_type=str dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2016-05-16 bool: arg_data=2016-05-16 arg_return_type=bool dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2016-05-16 full: arg_data=2016-05-16 arg_return_type=full dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2016-05-16 str: arg_data=2016-05-16 arg_return_type=str dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2023-01-19T07:18:22 bool: arg_data=2023-01-19T07:18:22 arg_return_type=bool dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2023-01-19T07:18:22 full: arg_data=2023-01-19T07:18:22 arg_return_type=full dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) 2023-01-19T07:18:22 str: arg_data=2023-01-19T07:18:22 arg_return_type=str dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) abc bool: arg_data=abc arg_return_type=bool dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) abc full: arg_data=abc arg_return_type=full dataset=date (coerce to float(epoch))
   date (coerce to float(epoch)) abc str: arg_data=abc arg_return_type=str dataset=date (coerce to float(epoch))
   int  bool: arg_data= arg_return_type=bool dataset=int
   int  full: arg_data= arg_return_type=full dataset=int
   int  str: arg_data= arg_return_type=str dataset=int
   int 1 bool: arg_data=1 arg_return_type=bool dataset=int
   int 1 full: arg_data=1 arg_return_type=full dataset=int
   int 1 str: arg_data=1 arg_return_type=str dataset=int
   int a bool: arg_data=a arg_return_type=bool dataset=int
   int a full: arg_data=a arg_return_type=full dataset=int
   int a str: arg_data=a arg_return_type=str dataset=int
   int*  bool: arg_data= arg_return_type=bool dataset=int*
   int*  full: arg_data= arg_return_type=full dataset=int*
   int*  str: arg_data= arg_return_type=str dataset=int*
   int* 1 bool: arg_data=1 arg_return_type=bool dataset=int*
   int* 1 full: arg_data=1 arg_return_type=full dataset=int*
   int* 1 str: arg_data=1 arg_return_type=str dataset=int*
   int* a bool: arg_data=a arg_return_type=bool dataset=int*
   int* a full: arg_data=a arg_return_type=full dataset=int*
   int* a str: arg_data=a arg_return_type=str dataset=int*
   str+2clause  bool: arg_data= arg_return_type=bool dataset=str+2clause
   str+2clause abc bool: arg_data=abc arg_return_type=bool dataset=str+2clause

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Data-Sah>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
