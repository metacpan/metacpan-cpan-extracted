package Bencher::Scenario::Log::ger::Overhead;

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-ger'; # DIST
our $VERSION = '0.019'; # VERSION

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Measure startup overhead of various codes',
    modules => {
        'Log::Any' => {},
        'Log::ger' => {version=>'0.019'},
        'Log::ger::App' => {version=>'0.002'},
        'Log::ger::Output' => {version=>'0.005'},
        'Log::ger::Layout::Pattern' => {version=>'0'},
        'Log::Contextual' => {version=>'0'},
        'Log::Dispatch' => {version=>'0'},
        'Log::Dispatch::Null' => {version=>'0'},
        'Log::Log4perl' => {version=>'0'},
        'Log::Log4perl::Tiny' => {version=>'0'},
        'Log::Dispatchouli' => {version=>'0'},
        'Mojo::Log' => {version=>'0'},
        'XLog' => {},
    },
    code_startup => 1,
    participants => [
        # a benchmark for Log::ger: strict/warnings
        {code_template=>'use strict;'},
        {code_template=>'use warnings;'},
        {code_template=>'use strict; use warnings;'},

        {code_template=>'use Log::ger ();'},
        {code_template=>'use Log::ger;'},
        {code_template=>'use Log::ger; Log::ger->get_logger;'},
        {code_template=>'use Log::ger::App;'},
        {code_template=>'use Log::ger::App; use Log::ger;'},
        {code_template=>'use Log::ger::Plugin::OptAway; use Log::ger;'},
        {code_template=>'use Log::ger::Like::LogAny;'},
        {code_template=>'use Log::ger::Like::Log4perl;'},
        {code_template=>'use Log::ger::App;'},

        {code_template=>'use Log::Any;'},
        {code_template=>'use Log::Any q($log);'},

        {code_template=>'use Log::Contextual qw(:log);'},

        {code_template=>'use Log::Log4perl;'},

        {code_template=>'use Log::Log4perl::Tiny;'},

        {code_template=>'use Log::Dispatch;'},
        {code_template=>'use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])', tags=>['output']},

        {code_template=>'use Log::Dispatchouli;'},

        {code_template=>'use Log::ger::Output::Screen;', tags=>['output']},
        {code_template=>'use Log::ger::Output::Composite;', tags=>['output']},

        {code_template=>'use Mojo::Log;'},
        {code_template=>'use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")'},

        {code_template=>'use XLog;'},

        # TODO: Lg + Composite (2 outputs)
        # TODO: Lg + Composite (2 outputs + pattern layouts)
        # TODO: Log::Any + Screen
        # TODO: Log::Log4perl + easy_init
    ],
};

1;
# ABSTRACT: Measure startup overhead of various codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::Overhead - Measure startup overhead of various codes

=head1 VERSION

This document describes version 0.019 of Bencher::Scenario::Log::ger::Overhead (from Perl distribution Bencher-Scenarios-Log-ger), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.717

L<Log::Contextual> 0.008001

L<Log::Dispatch> 2.71

L<Log::Dispatch::Null> 2.71

L<Log::Dispatchouli> 3.007

L<Log::Log4perl> 1.57

L<Log::Log4perl::Tiny> 1.8.0

L<Log::ger> 0.040

L<Log::ger::App> 0.024

L<Log::ger::Layout::Pattern> 0.008

L<Log::ger::Output> 0.040

L<Mojo::Log>

L<XLog> 1.1.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * use strict; (perl_code)

Code template:

 use strict;



=item * use warnings; (perl_code)

Code template:

 use warnings;



=item * use strict; use warnings; (perl_code)

Code template:

 use strict; use warnings;



=item * use Log::ger (); (perl_code)

Code template:

 use Log::ger ();



=item * use Log::ger; (perl_code)

Code template:

 use Log::ger;



=item * use Log::ger; Log::ger->get_logger; (perl_code)

Code template:

 use Log::ger; Log::ger->get_logger;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::ger::App; use Log::ger; (perl_code)

Code template:

 use Log::ger::App; use Log::ger;



=item * use Log::ger::Plugin::OptAway; use Log::ger; (perl_code)

Code template:

 use Log::ger::Plugin::OptAway; use Log::ger;



=item * use Log::ger::Like::LogAny; (perl_code)

Code template:

 use Log::ger::Like::LogAny;



=item * use Log::ger::Like::Log4perl; (perl_code)

Code template:

 use Log::ger::Like::Log4perl;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::Any; (perl_code)

Code template:

 use Log::Any;



=item * use Log::Any q($log); (perl_code)

Code template:

 use Log::Any q($log);



=item * use Log::Contextual qw(:log); (perl_code)

Code template:

 use Log::Contextual qw(:log);



=item * use Log::Log4perl; (perl_code)

Code template:

 use Log::Log4perl;



=item * use Log::Log4perl::Tiny; (perl_code)

Code template:

 use Log::Log4perl::Tiny;



=item * use Log::Dispatch; (perl_code)

Code template:

 use Log::Dispatch;



=item * use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu (perl_code) [output]

Code template:

 use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])



=item * use Log::Dispatchouli; (perl_code)

Code template:

 use Log::Dispatchouli;



=item * use Log::ger::Output::Screen; (perl_code) [output]

Code template:

 use Log::ger::Output::Screen;



=item * use Log::ger::Output::Composite; (perl_code) [output]

Code template:

 use Log::ger::Output::Composite;



=item * use Mojo::Log; (perl_code)

Code template:

 use Mojo::Log;



=item * use Mojo::Log; my $log=Mojo::Log->new(level=>"warn") (perl_code)

Code template:

 use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")



=item * use XLog; (perl_code)

Code template:

 use XLog;



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::Overhead

Result formatted as table:

 #table1#
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | participant                                                      | time (ms) | code_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |    140    |             132.97 |                 0.00% |              1869.72% |   0.00031 |      21 |
 | use Mojo::Log;                                                   |    136    |             128.97 |                 1.43% |              1842.00% | 7.1e-05   |      20 |
 | use Log::Dispatchouli;                                           |     87.8  |              80.77 |                57.65% |              1149.39% | 6.9e-05   |      21 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |     80.4  |              73.37 |                72.17% |              1044.05% | 3.4e-05   |      20 |
 | use Log::Dispatch;                                               |     75.7  |              68.67 |                82.89% |               976.99% | 6.7e-05   |      20 |
 | use Log::Contextual qw(:log);                                    |     71.5  |              64.47 |                93.43% |               918.32% | 3.9e-05   |      20 |
 | use Log::Log4perl;                                               |     36.4  |              29.37 |               280.22% |               418.05% |   2e-05   |      20 |
 | use Log::ger::App; use Log::ger;                                 |     33.9  |              26.87 |               307.91% |               382.88% | 1.9e-05   |      20 |
 | use XLog;                                                        |     24.8  |              17.77 |               456.95% |               253.66% | 1.2e-05   |      20 |
 | use Log::ger::App;                                               |     24.8  |              17.77 |               458.51% |               252.67% | 1.4e-05   |      20 |
 | use Log::Log4perl::Tiny;                                         |     19.8  |              12.77 |               597.64% |               182.34% | 1.6e-05   |      20 |
 | use Log::ger::Like::Log4perl;                                    |     17.8  |              10.77 |               676.50% |               153.67% | 1.1e-05   |      20 |
 | use Log::Any q($log);                                            |     15    |               7.97 |               822.39% |               113.55% | 3.6e-06   |      20 |
 | use Log::Any;                                                    |     14.5  |               7.47 |               854.46% |               106.37% | 6.3e-06   |      20 |
 | use Log::ger::Output::Composite;                                 |     13.3  |               6.27 |               942.17% |                89.00% | 6.4e-06   |      20 |
 | use Log::ger::Output::Screen;                                    |     12.7  |               5.67 |               989.51% |                80.79% | 3.7e-06   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |     10.1  |               3.07 |              1264.67% |                44.34% | 5.1e-06   |      20 |
 | use strict; use warnings;                                        |      9.25 |               2.22 |              1396.26% |                31.64% | 4.7e-06   |      20 |
 | use warnings;                                                    |      8.96 |               1.93 |              1445.22% |                27.47% |   4e-06   |      20 |
 | use Log::ger::Like::LogAny;                                      |      8    |               0.97 |              1628.98% |                13.92% | 2.5e-06   |      20 |
 | use Log::ger; Log::ger->get_logger;                              |      7.82 |               0.79 |              1669.18% |                11.33% | 4.1e-06   |      20 |
 | use Log::ger;                                                    |      7.82 |               0.79 |              1669.66% |                11.31% | 5.4e-06   |      20 |
 | use Log::ger ();                                                 |      7.71 |               0.68 |              1695.02% |                 9.73% | 2.7e-06   |      20 |
 | use strict;                                                      |      7.54 |               0.51 |              1736.46% |                 7.26% | 3.8e-06   |      20 |
 | perl -e1 (baseline)                                              |      7.03 |               0    |              1869.72% |                 0.00% | 5.7e-06   |      20 |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                                       Rate  use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")  use Mojo::Log;  use Log::Dispatchouli;  use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu  use Log::Dispatch;  use Log::Contextual qw(:log);  use Log::Log4perl;  use Log::ger::App; use Log::ger;  use XLog;  use Log::ger::App;  use Log::Log4perl::Tiny;  use Log::ger::Like::Log4perl;  use Log::Any q($log);  use Log::Any;  use Log::ger::Output::Composite;  use Log::ger::Output::Screen;  use Log::ger::Plugin::OptAway; use Log::ger;  use strict; use warnings;  use warnings;  use Log::ger::Like::LogAny;  use Log::ger; Log::ger->get_logger;  use Log::ger;  use Log::ger ();  use strict;  perl -e1 (baseline) 
  use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")                7.1/s                                                    --             -2%                    -37%                                                              -42%                -45%                           -48%                -74%                              -75%       -82%                -82%                      -85%                           -87%                   -89%           -89%                              -90%                           -90%                                          -92%                       -93%           -93%                         -94%                                 -94%           -94%              -94%         -94%                 -94% 
  use Mojo::Log;                                                      7.4/s                                                    2%              --                    -35%                                                              -40%                -44%                           -47%                -73%                              -75%       -81%                -81%                      -85%                           -86%                   -88%           -89%                              -90%                           -90%                                          -92%                       -93%           -93%                         -94%                                 -94%           -94%              -94%         -94%                 -94% 
  use Log::Dispatchouli;                                             11.4/s                                                   59%             54%                      --                                                               -8%                -13%                           -18%                -58%                              -61%       -71%                -71%                      -77%                           -79%                   -82%           -83%                              -84%                           -85%                                          -88%                       -89%           -89%                         -90%                                 -91%           -91%              -91%         -91%                 -91% 
  use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu   12.4/s                                                   74%             69%                      9%                                                                --                 -5%                           -11%                -54%                              -57%       -69%                -69%                      -75%                           -77%                   -81%           -81%                              -83%                           -84%                                          -87%                       -88%           -88%                         -90%                                 -90%           -90%              -90%         -90%                 -91% 
  use Log::Dispatch;                                                 13.2/s                                                   84%             79%                     15%                                                                6%                  --                            -5%                -51%                              -55%       -67%                -67%                      -73%                           -76%                   -80%           -80%                              -82%                           -83%                                          -86%                       -87%           -88%                         -89%                                 -89%           -89%              -89%         -90%                 -90% 
  use Log::Contextual qw(:log);                                      14.0/s                                                   95%             90%                     22%                                                               12%                  5%                             --                -49%                              -52%       -65%                -65%                      -72%                           -75%                   -79%           -79%                              -81%                           -82%                                          -85%                       -87%           -87%                         -88%                                 -89%           -89%              -89%         -89%                 -90% 
  use Log::Log4perl;                                                 27.5/s                                                  284%            273%                    141%                                                              120%                107%                            96%                  --                               -6%       -31%                -31%                      -45%                           -51%                   -58%           -60%                              -63%                           -65%                                          -72%                       -74%           -75%                         -78%                                 -78%           -78%              -78%         -79%                 -80% 
  use Log::ger::App; use Log::ger;                                   29.5/s                                                  312%            301%                    158%                                                              137%                123%                           110%                  7%                                --       -26%                -26%                      -41%                           -47%                   -55%           -57%                              -60%                           -62%                                          -70%                       -72%           -73%                         -76%                                 -76%           -76%              -77%         -77%                 -79% 
  use XLog;                                                          40.3/s                                                  464%            448%                    254%                                                              224%                205%                           188%                 46%                               36%         --                  0%                      -20%                           -28%                   -39%           -41%                              -46%                           -48%                                          -59%                       -62%           -63%                         -67%                                 -68%           -68%              -68%         -69%                 -71% 
  use Log::ger::App;                                                 40.3/s                                                  464%            448%                    254%                                                              224%                205%                           188%                 46%                               36%         0%                  --                      -20%                           -28%                   -39%           -41%                              -46%                           -48%                                          -59%                       -62%           -63%                         -67%                                 -68%           -68%              -68%         -69%                 -71% 
  use Log::Log4perl::Tiny;                                           50.5/s                                                  607%            586%                    343%                                                              306%                282%                           261%                 83%                               71%        25%                 25%                        --                           -10%                   -24%           -26%                              -32%                           -35%                                          -48%                       -53%           -54%                         -59%                                 -60%           -60%              -61%         -61%                 -64% 
  use Log::ger::Like::Log4perl;                                      56.2/s                                                  686%            664%                    393%                                                              351%                325%                           301%                104%                               90%        39%                 39%                       11%                             --                   -15%           -18%                              -25%                           -28%                                          -43%                       -48%           -49%                         -55%                                 -56%           -56%              -56%         -57%                 -60% 
  use Log::Any q($log);                                              66.7/s                                                  833%            806%                    485%                                                              436%                404%                           376%                142%                              125%        65%                 65%                       32%                            18%                     --            -3%                              -11%                           -15%                                          -32%                       -38%           -40%                         -46%                                 -47%           -47%              -48%         -49%                 -53% 
  use Log::Any;                                                      69.0/s                                                  865%            837%                    505%                                                              454%                422%                           393%                151%                              133%        71%                 71%                       36%                            22%                     3%             --                               -8%                           -12%                                          -30%                       -36%           -38%                         -44%                                 -46%           -46%              -46%         -48%                 -51% 
  use Log::ger::Output::Composite;                                   75.2/s                                                  952%            922%                    560%                                                              504%                469%                           437%                173%                              154%        86%                 86%                       48%                            33%                    12%             9%                                --                            -4%                                          -24%                       -30%           -32%                         -39%                                 -41%           -41%              -42%         -43%                 -47% 
  use Log::ger::Output::Screen;                                      78.7/s                                                 1002%            970%                    591%                                                              533%                496%                           462%                186%                              166%        95%                 95%                       55%                            40%                    18%            14%                                4%                             --                                          -20%                       -27%           -29%                         -37%                                 -38%           -38%              -39%         -40%                 -44% 
  use Log::ger::Plugin::OptAway; use Log::ger;                       99.0/s                                                 1286%           1246%                    769%                                                              696%                649%                           607%                260%                              235%       145%                145%                       96%                            76%                    48%            43%                               31%                            25%                                            --                        -8%           -11%                         -20%                                 -22%           -22%              -23%         -25%                 -30% 
  use strict; use warnings;                                         108.1/s                                                 1413%           1370%                    849%                                                              769%                718%                           672%                293%                              266%       168%                168%                      114%                            92%                    62%            56%                               43%                            37%                                            9%                         --            -3%                         -13%                                 -15%           -15%              -16%         -18%                 -24% 
  use warnings;                                                     111.6/s                                                 1462%           1417%                    879%                                                              797%                744%                           697%                306%                              278%       176%                176%                      120%                            98%                    67%            61%                               48%                            41%                                           12%                         3%             --                         -10%                                 -12%           -12%              -13%         -15%                 -21% 
  use Log::ger::Like::LogAny;                                       125.0/s                                                 1650%           1600%                    997%                                                              905%                846%                           793%                355%                              323%       210%                210%                      147%                           122%                    87%            81%                               66%                            58%                                           26%                        15%            12%                           --                                  -2%            -2%               -3%          -5%                 -12% 
  use Log::ger; Log::ger->get_logger;                               127.9/s                                                 1690%           1639%                   1022%                                                              928%                868%                           814%                365%                              333%       217%                217%                      153%                           127%                    91%            85%                               70%                            62%                                           29%                        18%            14%                           2%                                   --             0%               -1%          -3%                 -10% 
  use Log::ger;                                                     127.9/s                                                 1690%           1639%                   1022%                                                              928%                868%                           814%                365%                              333%       217%                217%                      153%                           127%                    91%            85%                               70%                            62%                                           29%                        18%            14%                           2%                                   0%             --               -1%          -3%                 -10% 
  use Log::ger ();                                                  129.7/s                                                 1715%           1663%                   1038%                                                              942%                881%                           827%                372%                              339%       221%                221%                      156%                           130%                    94%            88%                               72%                            64%                                           30%                        19%            16%                           3%                                   1%             1%                --          -2%                  -8% 
  use strict;                                                       132.6/s                                                 1756%           1703%                   1064%                                                              966%                903%                           848%                382%                              349%       228%                228%                      162%                           136%                    98%            92%                               76%                            68%                                           33%                        22%            18%                           6%                                   3%             3%                2%           --                  -6% 
  perl -e1 (baseline)                                               142.2/s                                                 1891%           1834%                   1148%                                                             1043%                976%                           917%                417%                              382%       252%                252%                      181%                           153%                   113%           106%                               89%                            80%                                           43%                        31%            27%                          13%                                  11%            11%                9%           7%                   -- 
 
 Legends:
   perl -e1 (baseline): code_overhead_time=0 participant=perl -e1 (baseline)
   use Log::Any q($log);: code_overhead_time=7.97 participant=use Log::Any q($log);
   use Log::Any;: code_overhead_time=7.47 participant=use Log::Any;
   use Log::Contextual qw(:log);: code_overhead_time=64.47 participant=use Log::Contextual qw(:log);
   use Log::Dispatch;: code_overhead_time=68.67 participant=use Log::Dispatch;
   use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu: code_overhead_time=73.37 participant=use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu
   use Log::Dispatchouli;: code_overhead_time=80.77 participant=use Log::Dispatchouli;
   use Log::Log4perl::Tiny;: code_overhead_time=12.77 participant=use Log::Log4perl::Tiny;
   use Log::Log4perl;: code_overhead_time=29.37 participant=use Log::Log4perl;
   use Log::ger ();: code_overhead_time=0.68 participant=use Log::ger ();
   use Log::ger::App;: code_overhead_time=17.77 participant=use Log::ger::App;
   use Log::ger::App; use Log::ger;: code_overhead_time=26.87 participant=use Log::ger::App; use Log::ger;
   use Log::ger::Like::Log4perl;: code_overhead_time=10.77 participant=use Log::ger::Like::Log4perl;
   use Log::ger::Like::LogAny;: code_overhead_time=0.97 participant=use Log::ger::Like::LogAny;
   use Log::ger::Output::Composite;: code_overhead_time=6.27 participant=use Log::ger::Output::Composite;
   use Log::ger::Output::Screen;: code_overhead_time=5.67 participant=use Log::ger::Output::Screen;
   use Log::ger::Plugin::OptAway; use Log::ger;: code_overhead_time=3.07 participant=use Log::ger::Plugin::OptAway; use Log::ger;
   use Log::ger;: code_overhead_time=0.79 participant=use Log::ger;
   use Log::ger; Log::ger->get_logger;: code_overhead_time=0.79 participant=use Log::ger; Log::ger->get_logger;
   use Mojo::Log;: code_overhead_time=128.97 participant=use Mojo::Log;
   use Mojo::Log; my $log=Mojo::Log->new(level=>"warn"): code_overhead_time=132.97 participant=use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")
   use XLog;: code_overhead_time=17.77 participant=use XLog;
   use strict;: code_overhead_time=0.51 participant=use strict;
   use strict; use warnings;: code_overhead_time=2.22 participant=use strict; use warnings;
   use warnings;: code_overhead_time=1.93 participant=use warnings;

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
