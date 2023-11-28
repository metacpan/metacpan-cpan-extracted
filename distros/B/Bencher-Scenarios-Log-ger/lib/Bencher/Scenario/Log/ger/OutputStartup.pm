package Bencher::Scenario::Log::ger::OutputStartup;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use File::Temp qw(tempdir tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-ger'; # DIST
our $VERSION = '0.019'; # VERSION

my $str;
my $ary = [];
my ($fh, $fname) = tempfile();
my $dname = tempdir(CLEANUP => 1);

our %output_modules = (
    Null => {},
    String => { string => \$str },
    Array => { array => $ary },

    ArrayRotate => { array => $ary },
    File => { path => $fname },
    Screen => {},
    Callback => {},
    FileWriteRotate => { dir => $dname, prefix => 'prefix' },
    DirWriteRotate => { path => $dname },
    LogAny => {},
    #LogDispatchOutput => { output => 'ArrayWithLimits', args => {array => $ary} }, # Log::Dispatch::ArrayWithLimits already removed from CPAN
    Composite => { outputs => {Screen => {conf=>{}}, File => {conf=>{path=>$fname}}} },
    Syslog => { ident => 'test' },
);

our $scenario = {
    modules => {
        'Log::ger::Output::Composite' => {version=>'0.016'},
        'Log::ger::Output::File' => {version=>'0.002'},
        'Log::ger::Output::LogAny' => {version=>'0.003'},
        'Log::ger::Output::Screen' => {version=>'0.018'},
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        map {
            (
                +{
                    name => "load-$_",
                    module => "Log::ger::Output::$_",
                    perl_cmdline => ["-mLog::ger::Output::$_", "-e1"],
                },
                +{
                    name => "init-with-$_",
                    module => "Log::ger::Output::$_",
                    #perl_cmdline => ["-e", "use Log::ger::Output '$_'; use Log::ger"],
                    perl_cmdline => ["-e", "use Log::ger::Output '$_' => %{ +".dmp($output_modules{$_})." }; use Log::ger"],
                },
            )
        } sort keys %output_modules,
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::OutputStartup

=head1 VERSION

This document describes version 0.019 of Bencher::Scenario::Log::ger::OutputStartup (from Perl distribution Bencher-Scenarios-Log-ger), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::OutputStartup

To run module startup overhead benchmark:

 % bencher --module-startup -m Log::ger::OutputStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Output::Array> 0.040

L<Log::ger::Output::ArrayRotate> 0.004

L<Log::ger::Output::Callback> 0.009

L<Log::ger::Output::Composite> 0.017

L<Log::ger::Output::DirWriteRotate> 0.004

L<Log::ger::Output::File> 0.012

L<Log::ger::Output::FileWriteRotate> 0.005

L<Log::ger::Output::LogAny> 0.009

L<Log::ger::Output::Null> 0.040

L<Log::ger::Output::Screen> 0.019

L<Log::ger::Output::String> 0.040

L<Log::ger::Output::Syslog> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * load-Array (command)

L<Log::ger::Output::Array>



=item * init-with-Array (command)

L<Log::ger::Output::Array>



=item * load-ArrayRotate (command)

L<Log::ger::Output::ArrayRotate>



=item * init-with-ArrayRotate (command)

L<Log::ger::Output::ArrayRotate>



=item * load-Callback (command)

L<Log::ger::Output::Callback>



=item * init-with-Callback (command)

L<Log::ger::Output::Callback>



=item * load-Composite (command)

L<Log::ger::Output::Composite>



=item * init-with-Composite (command)

L<Log::ger::Output::Composite>



=item * load-DirWriteRotate (command)

L<Log::ger::Output::DirWriteRotate>



=item * init-with-DirWriteRotate (command)

L<Log::ger::Output::DirWriteRotate>



=item * load-File (command)

L<Log::ger::Output::File>



=item * init-with-File (command)

L<Log::ger::Output::File>



=item * load-FileWriteRotate (command)

L<Log::ger::Output::FileWriteRotate>



=item * init-with-FileWriteRotate (command)

L<Log::ger::Output::FileWriteRotate>



=item * load-LogAny (command)

L<Log::ger::Output::LogAny>



=item * init-with-LogAny (command)

L<Log::ger::Output::LogAny>



=item * load-Null (command)

L<Log::ger::Output::Null>



=item * init-with-Null (command)

L<Log::ger::Output::Null>



=item * load-Screen (command)

L<Log::ger::Output::Screen>



=item * init-with-Screen (command)

L<Log::ger::Output::Screen>



=item * load-String (command)

L<Log::ger::Output::String>



=item * init-with-String (command)

L<Log::ger::Output::String>



=item * load-Syslog (command)

L<Log::ger::Output::Syslog>



=item * init-with-Syslog (command)

L<Log::ger::Output::Syslog>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::OutputStartup

Result formatted as table:

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | init-with-FileWriteRotate |      23.7 |     42.1  |                 0.00% |               504.45% | 2.2e-05 |      21 |
 | init-with-Syslog          |      31.8 |     31.4  |                34.10% |               350.73% | 1.9e-05 |      20 |
 | init-with-Composite       |      37.2 |     26.9  |                56.91% |               285.22% | 1.5e-05 |      20 |
 | init-with-File            |      45   |     22.2  |                89.43% |               219.09% | 1.1e-05 |      20 |
 | init-with-LogAny          |      50.8 |     19.7  |               113.88% |               182.61% | 1.3e-05 |      20 |
 | load-File                 |      54.4 |     18.4  |               129.37% |               163.53% | 8.7e-06 |      20 |
 | init-with-DirWriteRotate  |      58.8 |     17    |               147.88% |               143.85% | 7.4e-06 |      20 |
 | init-with-Screen          |      68.5 |     14.6  |               188.62% |               109.43% |   4e-06 |      20 |
 | init-with-String          |      70.8 |     14.1  |               198.19% |               102.71% | 4.2e-06 |      20 |
 | init-with-Callback        |      70.8 |     14.1  |               198.39% |               102.57% | 6.9e-06 |      20 |
 | init-with-ArrayRotate     |      71   |     14.1  |               198.99% |               102.16% | 4.1e-06 |      21 |
 | init-with-Array           |      71.1 |     14.1  |               199.53% |               101.80% | 4.1e-06 |      20 |
 | init-with-Null            |      71.3 |     14    |               200.58% |               101.09% | 5.8e-06 |      20 |
 | load-Composite            |      75.5 |     13.2  |               218.26% |                89.92% |   5e-06 |      20 |
 | load-Screen               |      79   |     12.7  |               232.71% |                81.68% | 6.2e-06 |      20 |
 | load-Syslog               |      80.8 |     12.4  |               240.60% |                77.46% | 8.2e-06 |      20 |
 | load-Callback             |     106   |      9.47 |               345.10% |                35.80% | 3.5e-06 |      20 |
 | load-FileWriteRotate      |     106   |      9.4  |               348.35% |                34.82% | 6.9e-06 |      21 |
 | load-String               |     106   |      9.4  |               348.42% |                34.80% | 3.7e-06 |      20 |
 | load-LogAny               |     106   |      9.4  |               348.45% |                34.79% | 2.6e-06 |      20 |
 | load-ArrayRotate          |     107   |      9.39 |               348.92% |                34.64% | 4.8e-06 |      20 |
 | load-DirWriteRotate       |     107   |      9.36 |               349.94% |                34.34% | 5.9e-06 |      20 |
 | load-Array                |     107   |      9.36 |               350.16% |                34.27% | 3.9e-06 |      20 |
 | load-Null                 |     140   |      7.12 |               491.65% |                 2.16% | 2.5e-06 |      20 |
 | baseline                  |     140   |      7    |               504.45% |                 0.00% |   7e-06 |      20 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                               Rate  init-with-FileWriteRotate  init-with-Syslog  init-with-Composite  init-with-File  init-with-LogAny  load-File  init-with-DirWriteRotate  init-with-Screen  init-with-String  init-with-Callback  init-with-ArrayRotate  init-with-Array  init-with-Null  load-Composite  load-Screen  load-Syslog  load-Callback  load-FileWriteRotate  load-String  load-LogAny  load-ArrayRotate  load-DirWriteRotate  load-Array  load-Null  baseline 
  init-with-FileWriteRotate  23.7/s                         --              -25%                 -36%            -47%              -53%       -56%                      -59%              -65%              -66%                -66%                   -66%             -66%            -66%            -68%         -69%         -70%           -77%                  -77%         -77%         -77%              -77%                 -77%        -77%       -83%      -83% 
  init-with-Syslog           31.8/s                        34%                --                 -14%            -29%              -37%       -41%                      -45%              -53%              -55%                -55%                   -55%             -55%            -55%            -57%         -59%         -60%           -69%                  -70%         -70%         -70%              -70%                 -70%        -70%       -77%      -77% 
  init-with-Composite        37.2/s                        56%               16%                   --            -17%              -26%       -31%                      -36%              -45%              -47%                -47%                   -47%             -47%            -47%            -50%         -52%         -53%           -64%                  -65%         -65%         -65%              -65%                 -65%        -65%       -73%      -73% 
  init-with-File               45/s                        89%               41%                  21%              --              -11%       -17%                      -23%              -34%              -36%                -36%                   -36%             -36%            -36%            -40%         -42%         -44%           -57%                  -57%         -57%         -57%              -57%                 -57%        -57%       -67%      -68% 
  init-with-LogAny           50.8/s                       113%               59%                  36%             12%                --        -6%                      -13%              -25%              -28%                -28%                   -28%             -28%            -28%            -32%         -35%         -37%           -51%                  -52%         -52%         -52%              -52%                 -52%        -52%       -63%      -64% 
  load-File                  54.4/s                       128%               70%                  46%             20%                7%         --                       -7%              -20%              -23%                -23%                   -23%             -23%            -23%            -28%         -30%         -32%           -48%                  -48%         -48%         -48%              -48%                 -49%        -49%       -61%      -61% 
  init-with-DirWriteRotate   58.8/s                       147%               84%                  58%             30%               15%         8%                        --              -14%              -17%                -17%                   -17%             -17%            -17%            -22%         -25%         -27%           -44%                  -44%         -44%         -44%              -44%                 -44%        -44%       -58%      -58% 
  init-with-Screen           68.5/s                       188%              115%                  84%             52%               34%        26%                       16%                --               -3%                 -3%                    -3%              -3%             -4%             -9%         -13%         -15%           -35%                  -35%         -35%         -35%              -35%                 -35%        -35%       -51%      -52% 
  init-with-String           70.8/s                       198%              122%                  90%             57%               39%        30%                       20%                3%                --                  0%                     0%               0%              0%             -6%          -9%         -12%           -32%                  -33%         -33%         -33%              -33%                 -33%        -33%       -49%      -50% 
  init-with-Callback         70.8/s                       198%              122%                  90%             57%               39%        30%                       20%                3%                0%                  --                     0%               0%              0%             -6%          -9%         -12%           -32%                  -33%         -33%         -33%              -33%                 -33%        -33%       -49%      -50% 
  init-with-ArrayRotate        71/s                       198%              122%                  90%             57%               39%        30%                       20%                3%                0%                  0%                     --               0%              0%             -6%          -9%         -12%           -32%                  -33%         -33%         -33%              -33%                 -33%        -33%       -49%      -50% 
  init-with-Array            71.1/s                       198%              122%                  90%             57%               39%        30%                       20%                3%                0%                  0%                     0%               --              0%             -6%          -9%         -12%           -32%                  -33%         -33%         -33%              -33%                 -33%        -33%       -49%      -50% 
  init-with-Null             71.3/s                       200%              124%                  92%             58%               40%        31%                       21%                4%                0%                  0%                     0%               0%              --             -5%          -9%         -11%           -32%                  -32%         -32%         -32%              -32%                 -33%        -33%       -49%      -50% 
  load-Composite             75.5/s                       218%              137%                 103%             68%               49%        39%                       28%               10%                6%                  6%                     6%               6%              6%              --          -3%          -6%           -28%                  -28%         -28%         -28%              -28%                 -29%        -29%       -46%      -46% 
  load-Screen                  79/s                       231%              147%                 111%             74%               55%        44%                       33%               14%               11%                 11%                    11%              11%             10%              3%           --          -2%           -25%                  -25%         -25%         -25%              -26%                 -26%        -26%       -43%      -44% 
  load-Syslog                80.8/s                       239%              153%                 116%             79%               58%        48%                       37%               17%               13%                 13%                    13%              13%             12%              6%           2%           --           -23%                  -24%         -24%         -24%              -24%                 -24%        -24%       -42%      -43% 
  load-Callback               106/s                       344%              231%                 184%            134%              108%        94%                       79%               54%               48%                 48%                    48%              48%             47%             39%          34%          30%             --                    0%           0%           0%                0%                  -1%         -1%       -24%      -26% 
  load-FileWriteRotate        106/s                       347%              234%                 186%            136%              109%        95%                       80%               55%               50%                 50%                    50%              50%             48%             40%          35%          31%             0%                    --           0%           0%                0%                   0%          0%       -24%      -25% 
  load-String                 106/s                       347%              234%                 186%            136%              109%        95%                       80%               55%               50%                 50%                    50%              50%             48%             40%          35%          31%             0%                    0%           --           0%                0%                   0%          0%       -24%      -25% 
  load-LogAny                 106/s                       347%              234%                 186%            136%              109%        95%                       80%               55%               50%                 50%                    50%              50%             48%             40%          35%          31%             0%                    0%           0%           --                0%                   0%          0%       -24%      -25% 
  load-ArrayRotate            107/s                       348%              234%                 186%            136%              109%        95%                       81%               55%               50%                 50%                    50%              50%             49%             40%          35%          32%             0%                    0%           0%           0%                --                   0%          0%       -24%      -25% 
  load-DirWriteRotate         107/s                       349%              235%                 187%            137%              110%        96%                       81%               55%               50%                 50%                    50%              50%             49%             41%          35%          32%             1%                    0%           0%           0%                0%                   --          0%       -23%      -25% 
  load-Array                  107/s                       349%              235%                 187%            137%              110%        96%                       81%               55%               50%                 50%                    50%              50%             49%             41%          35%          32%             1%                    0%           0%           0%                0%                   0%          --       -23%      -25% 
  load-Null                   140/s                       491%              341%                 277%            211%              176%       158%                      138%              105%               98%                 98%                    98%              98%             96%             85%          78%          74%            33%                   32%          32%          32%               31%                  31%         31%         --       -1% 
  baseline                    140/s                       501%              348%                 284%            217%              181%       162%                      142%              108%              101%                101%                   101%             101%            100%             88%          81%          77%            35%                   34%          34%          34%               34%                  33%         33%         1%        -- 
 
 Legends:
   baseline: participant=baseline
   init-with-Array: participant=init-with-Array
   init-with-ArrayRotate: participant=init-with-ArrayRotate
   init-with-Callback: participant=init-with-Callback
   init-with-Composite: participant=init-with-Composite
   init-with-DirWriteRotate: participant=init-with-DirWriteRotate
   init-with-File: participant=init-with-File
   init-with-FileWriteRotate: participant=init-with-FileWriteRotate
   init-with-LogAny: participant=init-with-LogAny
   init-with-Null: participant=init-with-Null
   init-with-Screen: participant=init-with-Screen
   init-with-String: participant=init-with-String
   init-with-Syslog: participant=init-with-Syslog
   load-Array: participant=load-Array
   load-ArrayRotate: participant=load-ArrayRotate
   load-Callback: participant=load-Callback
   load-Composite: participant=load-Composite
   load-DirWriteRotate: participant=load-DirWriteRotate
   load-File: participant=load-File
   load-FileWriteRotate: participant=load-FileWriteRotate
   load-LogAny: participant=load-LogAny
   load-Null: participant=load-Null
   load-Screen: participant=load-Screen
   load-String: participant=load-String
   load-Syslog: participant=load-Syslog

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m Log::ger::OutputStartup --module-startup

Result formatted as table:

 #table2#
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Log::ger::Output::File            |     18    |             11    |                 0.00% |               162.80% | 1.9e-05   |      20 |
 | Log::ger::Output::Composite       |     14    |              7    |                27.91% |               105.46% |   0.00012 |      27 |
 | Log::ger::Output::Screen          |     12.7  |              5.7  |                45.08% |                81.14% | 7.5e-06   |      20 |
 | Log::ger::Output::Syslog          |     12.3  |              5.3  |                49.37% |                75.94% | 3.9e-06   |      20 |
 | Log::ger::Output::Callback        |      9.48 |              2.48 |                94.36% |                35.21% | 3.6e-06   |      21 |
 | Log::ger::Output::LogAny          |      9.43 |              2.43 |                95.41% |                34.49% | 2.6e-06   |      20 |
 | Log::ger::Output::String          |      9.42 |              2.42 |                95.72% |                34.27% |   3e-06   |      20 |
 | Log::ger::Output::FileWriteRotate |      9.4  |              2.4  |                96.08% |                34.02% | 3.2e-06   |      20 |
 | Log::ger::Output::Array           |      9.4  |              2.4  |                96.19% |                33.95% | 4.1e-06   |      20 |
 | Log::ger::Output::ArrayRotate     |      9.39 |              2.39 |                96.34% |                33.84% |   3e-06   |      20 |
 | Log::ger::Output::DirWriteRotate  |      9.39 |              2.39 |                96.35% |                33.84% | 5.2e-06   |      20 |
 | Log::ger::Output::Null            |      7.18 |              0.18 |               156.89% |                 2.30% | 2.2e-06   |      21 |
 | perl -e1 (baseline)               |      7    |              0    |               162.80% |                 0.00% | 1.4e-05   |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                        Rate  Log::ger::Output::File  Log::ger::Output::Composite  Log::ger::Output::Screen  Log::ger::Output::Syslog  Log::ger::Output::Callback  Log::ger::Output::LogAny  Log::ger::Output::String  Log::ger::Output::FileWriteRotate  Log::ger::Output::Array  Log::ger::Output::ArrayRotate  Log::ger::Output::DirWriteRotate  Log::ger::Output::Null  perl -e1 (baseline) 
  Log::ger::Output::File              55.6/s                      --                         -22%                      -29%                      -31%                        -47%                      -47%                      -47%                               -47%                     -47%                           -47%                              -47%                    -60%                 -61% 
  Log::ger::Output::Composite         71.4/s                     28%                           --                       -9%                      -12%                        -32%                      -32%                      -32%                               -32%                     -32%                           -32%                              -32%                    -48%                 -50% 
  Log::ger::Output::Screen            78.7/s                     41%                          10%                        --                       -3%                        -25%                      -25%                      -25%                               -25%                     -25%                           -26%                              -26%                    -43%                 -44% 
  Log::ger::Output::Syslog            81.3/s                     46%                          13%                        3%                        --                        -22%                      -23%                      -23%                               -23%                     -23%                           -23%                              -23%                    -41%                 -43% 
  Log::ger::Output::Callback         105.5/s                     89%                          47%                       33%                       29%                          --                        0%                        0%                                 0%                       0%                             0%                                0%                    -24%                 -26% 
  Log::ger::Output::LogAny           106.0/s                     90%                          48%                       34%                       30%                          0%                        --                        0%                                 0%                       0%                             0%                                0%                    -23%                 -25% 
  Log::ger::Output::String           106.2/s                     91%                          48%                       34%                       30%                          0%                        0%                        --                                 0%                       0%                             0%                                0%                    -23%                 -25% 
  Log::ger::Output::FileWriteRotate  106.4/s                     91%                          48%                       35%                       30%                          0%                        0%                        0%                                 --                       0%                             0%                                0%                    -23%                 -25% 
  Log::ger::Output::Array            106.4/s                     91%                          48%                       35%                       30%                          0%                        0%                        0%                                 0%                       --                             0%                                0%                    -23%                 -25% 
  Log::ger::Output::ArrayRotate      106.5/s                     91%                          49%                       35%                       30%                          0%                        0%                        0%                                 0%                       0%                             --                                0%                    -23%                 -25% 
  Log::ger::Output::DirWriteRotate   106.5/s                     91%                          49%                       35%                       30%                          0%                        0%                        0%                                 0%                       0%                             0%                                --                    -23%                 -25% 
  Log::ger::Output::Null             139.3/s                    150%                          94%                       76%                       71%                         32%                       31%                       31%                                30%                      30%                            30%                               30%                      --                  -2% 
  perl -e1 (baseline)                142.9/s                    157%                         100%                       81%                       75%                         35%                       34%                       34%                                34%                      34%                            34%                               34%                      2%                   -- 
 
 Legends:
   Log::ger::Output::Array: mod_overhead_time=2.4 participant=Log::ger::Output::Array
   Log::ger::Output::ArrayRotate: mod_overhead_time=2.39 participant=Log::ger::Output::ArrayRotate
   Log::ger::Output::Callback: mod_overhead_time=2.48 participant=Log::ger::Output::Callback
   Log::ger::Output::Composite: mod_overhead_time=7 participant=Log::ger::Output::Composite
   Log::ger::Output::DirWriteRotate: mod_overhead_time=2.39 participant=Log::ger::Output::DirWriteRotate
   Log::ger::Output::File: mod_overhead_time=11 participant=Log::ger::Output::File
   Log::ger::Output::FileWriteRotate: mod_overhead_time=2.4 participant=Log::ger::Output::FileWriteRotate
   Log::ger::Output::LogAny: mod_overhead_time=2.43 participant=Log::ger::Output::LogAny
   Log::ger::Output::Null: mod_overhead_time=0.18 participant=Log::ger::Output::Null
   Log::ger::Output::Screen: mod_overhead_time=5.7 participant=Log::ger::Output::Screen
   Log::ger::Output::String: mod_overhead_time=2.42 participant=Log::ger::Output::String
   Log::ger::Output::Syslog: mod_overhead_time=5.3 participant=Log::ger::Output::Syslog
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-ger>.

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

This software is copyright (c) 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
