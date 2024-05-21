package Bencher::Scenario::Log::ger::OutputStartup;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use File::Temp qw(tempdir tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

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

This document describes version 0.020 of Bencher::Scenario::Log::ger::OutputStartup (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

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

L<Log::ger::Output::Array> 0.042

L<Log::ger::Output::ArrayRotate> 0.004

L<Log::ger::Output::Callback> 0.009

L<Log::ger::Output::Composite> 0.018

L<Log::ger::Output::DirWriteRotate> 0.004

L<Log::ger::Output::File> 0.012

L<Log::ger::Output::FileWriteRotate> 0.005

L<Log::ger::Output::LogAny> 0.009

L<Log::ger::Output::Null> 0.042

L<Log::ger::Output::Screen> 0.019

L<Log::ger::Output::String> 0.042

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

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::OutputStartup

Result formatted as table:

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | init-with-FileWriteRotate |      23.7 |     42.3  |                 0.00% |               516.86% | 1.7e-05 |      20 |
 | init-with-Syslog          |      32   |     31.2  |                35.29% |               355.94% |   2e-05 |      20 |
 | init-with-Composite       |      37.2 |     26.9  |                57.41% |               291.88% | 1.8e-05 |      20 |
 | init-with-File            |      45   |     22.2  |                90.12% |               224.46% | 9.1e-06 |      21 |
 | init-with-LogAny          |      50.8 |     19.7  |               114.55% |               187.51% | 1.2e-05 |      20 |
 | load-File                 |      54.5 |     18.4  |               130.22% |               167.94% | 1.2e-05 |      20 |
 | init-with-DirWriteRotate  |      59   |     17    |               149.21% |               147.53% | 1.1e-05 |      20 |
 | init-with-Screen          |      68.8 |     14.5  |               190.95% |               112.01% | 9.2e-06 |      20 |
 | init-with-String          |      71.2 |     14    |               200.95% |               104.97% | 1.2e-05 |      20 |
 | init-with-Callback        |      71.4 |     14    |               201.96% |               104.29% | 3.4e-06 |      20 |
 | init-with-ArrayRotate     |      71.5 |     14    |               202.35% |               104.02% |   6e-06 |      20 |
 | init-with-Array           |      71.5 |     14    |               202.36% |               104.01% | 7.8e-06 |      20 |
 | init-with-Null            |      71.8 |     13.9  |               203.70% |               103.12% | 5.5e-06 |      20 |
 | load-Composite            |      75.9 |     13.2  |               220.93% |                92.21% | 1.1e-05 |      21 |
 | load-Screen               |      79.5 |     12.6  |               236.17% |                83.49% | 5.4e-06 |      20 |
 | load-Syslog               |      81.9 |     12.2  |               246.01% |                78.27% | 4.8e-06 |      22 |
 | load-Callback             |     107   |      9.36 |               351.42% |                36.65% | 3.8e-06 |      20 |
 | load-LogAny               |     107   |      9.31 |               354.19% |                35.81% | 4.9e-06 |      20 |
 | load-FileWriteRotate      |     108   |      9.3  |               354.71% |                35.66% | 5.3e-06 |      20 |
 | load-String               |     108   |      9.29 |               354.87% |                35.61% | 5.1e-06 |      20 |
 | load-Array                |     108   |      9.26 |               356.38% |                35.16% | 3.6e-06 |      21 |
 | load-DirWriteRotate       |     108   |      9.25 |               356.91% |                35.00% | 4.6e-06 |      20 |
 | load-ArrayRotate          |     108   |      9.25 |               356.95% |                34.99% | 6.2e-06 |      20 |
 | load-Null                 |     142   |      7.03 |               501.71% |                 2.52% | 5.2e-06 |      20 |
 | baseline                  |     146   |      6.85 |               516.86% |                 0.00% | 5.1e-06 |      20 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                               Rate  init-with-FileWriteRotate  init-with-Syslog  init-with-Composite  init-with-File  init-with-LogAny  load-File  init-with-DirWriteRotate  init-with-Screen  init-with-String  init-with-Callback  init-with-ArrayRotate  init-with-Array  init-with-Null  load-Composite  load-Screen  load-Syslog  load-Callback  load-LogAny  load-FileWriteRotate  load-String  load-Array  load-DirWriteRotate  load-ArrayRotate  load-Null  baseline 
  init-with-FileWriteRotate  23.7/s                         --              -26%                 -36%            -47%              -53%       -56%                      -59%              -65%              -66%                -66%                   -66%             -66%            -67%            -68%         -70%         -71%           -77%         -77%                  -78%         -78%        -78%                 -78%              -78%       -83%      -83% 
  init-with-Syslog             32/s                        35%                --                 -13%            -28%              -36%       -41%                      -45%              -53%              -55%                -55%                   -55%             -55%            -55%            -57%         -59%         -60%           -70%         -70%                  -70%         -70%        -70%                 -70%              -70%       -77%      -78% 
  init-with-Composite        37.2/s                        57%               15%                   --            -17%              -26%       -31%                      -36%              -46%              -47%                -47%                   -47%             -47%            -48%            -50%         -53%         -54%           -65%         -65%                  -65%         -65%        -65%                 -65%              -65%       -73%      -74% 
  init-with-File               45/s                        90%               40%                  21%              --              -11%       -17%                      -23%              -34%              -36%                -36%                   -36%             -36%            -37%            -40%         -43%         -45%           -57%         -58%                  -58%         -58%        -58%                 -58%              -58%       -68%      -69% 
  init-with-LogAny           50.8/s                       114%               58%                  36%             12%                --        -6%                      -13%              -26%              -28%                -28%                   -28%             -28%            -29%            -32%         -36%         -38%           -52%         -52%                  -52%         -52%        -52%                 -53%              -53%       -64%      -65% 
  load-File                  54.5/s                       129%               69%                  46%             20%                7%         --                       -7%              -21%              -23%                -23%                   -23%             -23%            -24%            -28%         -31%         -33%           -49%         -49%                  -49%         -49%        -49%                 -49%              -49%       -61%      -62% 
  init-with-DirWriteRotate     59/s                       148%               83%                  58%             30%               15%         8%                        --              -14%              -17%                -17%                   -17%             -17%            -18%            -22%         -25%         -28%           -44%         -45%                  -45%         -45%        -45%                 -45%              -45%       -58%      -59% 
  init-with-Screen           68.8/s                       191%              115%                  85%             53%               35%        26%                       17%                --               -3%                 -3%                    -3%              -3%             -4%             -8%         -13%         -15%           -35%         -35%                  -35%         -35%        -36%                 -36%              -36%       -51%      -52% 
  init-with-String           71.2/s                       202%              122%                  92%             58%               40%        31%                       21%                3%                --                  0%                     0%               0%              0%             -5%          -9%         -12%           -33%         -33%                  -33%         -33%        -33%                 -33%              -33%       -49%      -51% 
  init-with-Callback         71.4/s                       202%              122%                  92%             58%               40%        31%                       21%                3%                0%                  --                     0%               0%              0%             -5%          -9%         -12%           -33%         -33%                  -33%         -33%        -33%                 -33%              -33%       -49%      -51% 
  init-with-ArrayRotate      71.5/s                       202%              122%                  92%             58%               40%        31%                       21%                3%                0%                  0%                     --               0%              0%             -5%          -9%         -12%           -33%         -33%                  -33%         -33%        -33%                 -33%              -33%       -49%      -51% 
  init-with-Array            71.5/s                       202%              122%                  92%             58%               40%        31%                       21%                3%                0%                  0%                     0%               --              0%             -5%          -9%         -12%           -33%         -33%                  -33%         -33%        -33%                 -33%              -33%       -49%      -51% 
  init-with-Null             71.8/s                       204%              124%                  93%             59%               41%        32%                       22%                4%                0%                  0%                     0%               0%              --             -5%          -9%         -12%           -32%         -33%                  -33%         -33%        -33%                 -33%              -33%       -49%      -50% 
  load-Composite             75.9/s                       220%              136%                 103%             68%               49%        39%                       28%                9%                6%                  6%                     6%               6%              5%              --          -4%          -7%           -29%         -29%                  -29%         -29%        -29%                 -29%              -29%       -46%      -48% 
  load-Screen                79.5/s                       235%              147%                 113%             76%               56%        46%                       34%               15%               11%                 11%                    11%              11%             10%              4%           --          -3%           -25%         -26%                  -26%         -26%        -26%                 -26%              -26%       -44%      -45% 
  load-Syslog                81.9/s                       246%              155%                 120%             81%               61%        50%                       39%               18%               14%                 14%                    14%              14%             13%              8%           3%           --           -23%         -23%                  -23%         -23%        -24%                 -24%              -24%       -42%      -43% 
  load-Callback               107/s                       351%              233%                 187%            137%              110%        96%                       81%               54%               49%                 49%                    49%              49%             48%             41%          34%          30%             --           0%                    0%           0%         -1%                  -1%               -1%       -24%      -26% 
  load-LogAny                 107/s                       354%              235%                 188%            138%              111%        97%                       82%               55%               50%                 50%                    50%              50%             49%             41%          35%          31%             0%           --                    0%           0%          0%                   0%                0%       -24%      -26% 
  load-FileWriteRotate        108/s                       354%              235%                 189%            138%              111%        97%                       82%               55%               50%                 50%                    50%              50%             49%             41%          35%          31%             0%           0%                    --           0%          0%                   0%                0%       -24%      -26% 
  load-String                 108/s                       355%              235%                 189%            138%              112%        98%                       82%               56%               50%                 50%                    50%              50%             49%             42%          35%          31%             0%           0%                    0%           --          0%                   0%                0%       -24%      -26% 
  load-Array                  108/s                       356%              236%                 190%            139%              112%        98%                       83%               56%               51%                 51%                    51%              51%             50%             42%          36%          31%             1%           0%                    0%           0%          --                   0%                0%       -24%      -26% 
  load-DirWriteRotate         108/s                       357%              237%                 190%            140%              112%        98%                       83%               56%               51%                 51%                    51%              51%             50%             42%          36%          31%             1%           0%                    0%           0%          0%                   --                0%       -24%      -25% 
  load-ArrayRotate            108/s                       357%              237%                 190%            140%              112%        98%                       83%               56%               51%                 51%                    51%              51%             50%             42%          36%          31%             1%           0%                    0%           0%          0%                   0%                --       -24%      -25% 
  load-Null                   142/s                       501%              343%                 282%            215%              180%       161%                      141%              106%               99%                 99%                    99%              99%             97%             87%          79%          73%            33%          32%                   32%          32%         31%                  31%               31%         --       -2% 
  baseline                    146/s                       517%              355%                 292%            224%              187%       168%                      148%              111%              104%                104%                   104%             104%            102%             92%          83%          78%            36%          35%                   35%          35%         35%                  35%               35%         2%        -- 
 
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
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Output::File            |     18.4  |             11.55 |                 0.00% |               168.14% | 1.1e-05 |      20 |
 | Log::ger::Output::Composite       |     13.2  |              6.35 |                39.28% |                92.52% | 5.1e-06 |      20 |
 | Log::ger::Output::Screen          |     12.6  |              5.75 |                45.94% |                83.73% | 9.5e-06 |      20 |
 | Log::ger::Output::Syslog          |     12.3  |              5.45 |                49.93% |                78.85% | 2.5e-06 |      22 |
 | Log::ger::Output::Callback        |      9.4  |              2.55 |                95.36% |                37.25% | 5.6e-06 |      20 |
 | Log::ger::Output::String          |      9.33 |              2.48 |                96.90% |                36.18% | 6.2e-06 |      20 |
 | Log::ger::Output::LogAny          |      9.33 |              2.48 |                96.94% |                36.15% | 5.4e-06 |      20 |
 | Log::ger::Output::ArrayRotate     |      9.3  |              2.45 |                97.49% |                35.77% | 5.3e-06 |      20 |
 | Log::ger::Output::Array           |      9.29 |              2.44 |                97.69% |                35.63% | 5.8e-06 |      20 |
 | Log::ger::Output::FileWriteRotate |      9.29 |              2.44 |                97.71% |                35.62% | 4.2e-06 |      20 |
 | Log::ger::Output::DirWriteRotate  |      9.27 |              2.42 |                98.17% |                35.31% | 2.6e-06 |      20 |
 | Log::ger::Output::Null            |      7.05 |              0.2  |               160.34% |                 3.00% | 5.1e-06 |      20 |
 | perl -e1 (baseline)               |      6.85 |              0    |               168.14% |                 0.00% |   2e-06 |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                        Rate  Log::ger::Output::File  Log::ger::Output::Composite  Log::ger::Output::Screen  Log::ger::Output::Syslog  Log::ger::Output::Callback  Log::ger::Output::String  Log::ger::Output::LogAny  Log::ger::Output::ArrayRotate  Log::ger::Output::Array  Log::ger::Output::FileWriteRotate  Log::ger::Output::DirWriteRotate  Log::ger::Output::Null  perl -e1 (baseline) 
  Log::ger::Output::File              54.3/s                      --                         -28%                      -31%                      -33%                        -48%                      -49%                      -49%                           -49%                     -49%                               -49%                              -49%                    -61%                 -62% 
  Log::ger::Output::Composite         75.8/s                     39%                           --                       -4%                       -6%                        -28%                      -29%                      -29%                           -29%                     -29%                               -29%                              -29%                    -46%                 -48% 
  Log::ger::Output::Screen            79.4/s                     46%                           4%                        --                       -2%                        -25%                      -25%                      -25%                           -26%                     -26%                               -26%                              -26%                    -44%                 -45% 
  Log::ger::Output::Syslog            81.3/s                     49%                           7%                        2%                        --                        -23%                      -24%                      -24%                           -24%                     -24%                               -24%                              -24%                    -42%                 -44% 
  Log::ger::Output::Callback         106.4/s                     95%                          40%                       34%                       30%                          --                        0%                        0%                            -1%                      -1%                                -1%                               -1%                    -25%                 -27% 
  Log::ger::Output::String           107.2/s                     97%                          41%                       35%                       31%                          0%                        --                        0%                             0%                       0%                                 0%                                0%                    -24%                 -26% 
  Log::ger::Output::LogAny           107.2/s                     97%                          41%                       35%                       31%                          0%                        0%                        --                             0%                       0%                                 0%                                0%                    -24%                 -26% 
  Log::ger::Output::ArrayRotate      107.5/s                     97%                          41%                       35%                       32%                          1%                        0%                        0%                             --                       0%                                 0%                                0%                    -24%                 -26% 
  Log::ger::Output::Array            107.6/s                     98%                          42%                       35%                       32%                          1%                        0%                        0%                             0%                       --                                 0%                                0%                    -24%                 -26% 
  Log::ger::Output::FileWriteRotate  107.6/s                     98%                          42%                       35%                       32%                          1%                        0%                        0%                             0%                       0%                                 --                                0%                    -24%                 -26% 
  Log::ger::Output::DirWriteRotate   107.9/s                     98%                          42%                       35%                       32%                          1%                        0%                        0%                             0%                       0%                                 0%                                --                    -23%                 -26% 
  Log::ger::Output::Null             141.8/s                    160%                          87%                       78%                       74%                         33%                       32%                       32%                            31%                      31%                                31%                               31%                      --                  -2% 
  perl -e1 (baseline)                146.0/s                    168%                          92%                       83%                       79%                         37%                       36%                       36%                            35%                      35%                                35%                               35%                      2%                   -- 
 
 Legends:
   Log::ger::Output::Array: mod_overhead_time=2.44 participant=Log::ger::Output::Array
   Log::ger::Output::ArrayRotate: mod_overhead_time=2.45 participant=Log::ger::Output::ArrayRotate
   Log::ger::Output::Callback: mod_overhead_time=2.55 participant=Log::ger::Output::Callback
   Log::ger::Output::Composite: mod_overhead_time=6.35 participant=Log::ger::Output::Composite
   Log::ger::Output::DirWriteRotate: mod_overhead_time=2.42 participant=Log::ger::Output::DirWriteRotate
   Log::ger::Output::File: mod_overhead_time=11.55 participant=Log::ger::Output::File
   Log::ger::Output::FileWriteRotate: mod_overhead_time=2.44 participant=Log::ger::Output::FileWriteRotate
   Log::ger::Output::LogAny: mod_overhead_time=2.48 participant=Log::ger::Output::LogAny
   Log::ger::Output::Null: mod_overhead_time=0.2 participant=Log::ger::Output::Null
   Log::ger::Output::Screen: mod_overhead_time=5.75 participant=Log::ger::Output::Screen
   Log::ger::Output::String: mod_overhead_time=2.48 participant=Log::ger::Output::String
   Log::ger::Output::Syslog: mod_overhead_time=5.45 participant=Log::ger::Output::Syslog
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Log-ger>.

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

This software is copyright (c) 2024, 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
