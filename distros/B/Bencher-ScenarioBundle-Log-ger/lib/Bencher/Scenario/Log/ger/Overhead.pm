package Bencher::Scenario::Log::ger::Overhead;

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

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

This document describes version 0.020 of Bencher::Scenario::Log::ger::Overhead (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

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

L<Log::ger> 0.042

L<Log::ger::App> 0.025

L<Log::ger::Layout::Pattern> 0.009

L<Log::ger::Output> 0.042

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

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::Overhead

Result formatted as table:

 #table1#
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | participant                                                      | time (ms) | code_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | use Mojo::Log;                                                   |    140    |             133.13 |                 0.00% |              1915.30% |   0.00015 |      20 |
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |    138    |             131.13 |                 0.50% |              1905.28% | 7.8e-05   |      20 |
 | use Log::Dispatchouli;                                           |     87.6  |              80.73 |                58.05% |              1175.08% | 4.4e-05   |      20 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |     80.6  |              73.73 |                71.86% |              1072.63% | 2.6e-05   |      20 |
 | use Log::Dispatch;                                               |     75.8  |              68.93 |                82.77% |              1002.64% | 6.2e-05   |      20 |
 | use Log::Contextual qw(:log);                                    |     71.8  |              64.93 |                92.85% |               945.00% | 4.6e-05   |      20 |
 | use Log::Log4perl;                                               |     36.3  |              29.43 |               282.12% |               427.40% | 2.2e-05   |      20 |
 | use Log::ger::App; use Log::ger;                                 |     34    |              27.13 |               307.76% |               394.24% | 1.2e-05   |      20 |
 | use XLog;                                                        |     24.8  |              17.93 |               458.87% |               260.61% |   8e-06   |      20 |
 | use Log::ger::App;                                               |     24.7  |              17.83 |               460.82% |               259.35% | 1.7e-05   |      21 |
 | use Log::Log4perl::Tiny;                                         |     19.8  |              12.93 |               599.98% |               187.91% | 1.3e-05   |      20 |
 | use Log::ger::Like::Log4perl;                                    |     17.8  |              10.93 |               679.80% |               158.44% | 1.3e-05   |      21 |
 | use Log::Any q($log);                                            |     14.9  |               8.03 |               826.79% |               117.45% |   1e-05   |      20 |
 | use Log::Any;                                                    |     14.4  |               7.53 |               861.11% |               109.68% | 5.3e-06   |      20 |
 | use Log::ger::Output::Composite;                                 |     13.2  |               6.33 |               949.29% |                92.06% | 9.5e-06   |      20 |
 | use Log::ger::Output::Screen;                                    |     12.6  |               5.73 |               996.31% |                83.83% | 8.3e-06   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |     10.1  |               3.23 |              1276.61% |                46.40% | 6.8e-06   |      20 |
 | use warnings;                                                    |      9.2  |               2.33 |              1404.76% |                33.93% |   4e-05   |      20 |
 | use strict; use warnings;                                        |      9.14 |               2.27 |              1415.55% |                32.98% | 7.5e-06   |      20 |
 | use Log::ger::Like::LogAny;                                      |      7.88 |               1.01 |              1657.78% |                14.65% | 3.1e-06   |      20 |
 | use Log::ger; Log::ger->get_logger;                              |      7.74 |               0.87 |              1689.83% |                12.60% | 3.1e-06   |      21 |
 | use Log::ger;                                                    |      7.69 |               0.82 |              1701.58% |                11.86% | 4.1e-06   |      20 |
 | use Log::ger ();                                                 |      7.62 |               0.75 |              1717.49% |                10.88% |   3e-06   |      20 |
 | use strict;                                                      |      7.32 |               0.45 |              1792.74% |                 6.48% | 6.1e-06   |      20 |
 | perl -e1 (baseline)                                              |      6.87 |               0    |              1915.30% |                 0.00% | 2.9e-06   |      22 |
 +------------------------------------------------------------------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                                       Rate  use Mojo::Log;  use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")  use Log::Dispatchouli;  use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu  use Log::Dispatch;  use Log::Contextual qw(:log);  use Log::Log4perl;  use Log::ger::App; use Log::ger;  use XLog;  use Log::ger::App;  use Log::Log4perl::Tiny;  use Log::ger::Like::Log4perl;  use Log::Any q($log);  use Log::Any;  use Log::ger::Output::Composite;  use Log::ger::Output::Screen;  use Log::ger::Plugin::OptAway; use Log::ger;  use warnings;  use strict; use warnings;  use Log::ger::Like::LogAny;  use Log::ger; Log::ger->get_logger;  use Log::ger;  use Log::ger ();  use strict;  perl -e1 (baseline) 
  use Mojo::Log;                                                      7.1/s              --                                                   -1%                    -37%                                                              -42%                -45%                           -48%                -74%                              -75%       -82%                -82%                      -85%                           -87%                   -89%           -89%                              -90%                           -91%                                          -92%           -93%                       -93%                         -94%                                 -94%           -94%              -94%         -94%                 -95% 
  use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")                7.2/s              1%                                                    --                    -36%                                                              -41%                -45%                           -47%                -73%                              -75%       -82%                -82%                      -85%                           -87%                   -89%           -89%                              -90%                           -90%                                          -92%           -93%                       -93%                         -94%                                 -94%           -94%              -94%         -94%                 -95% 
  use Log::Dispatchouli;                                             11.4/s             59%                                                   57%                      --                                                               -7%                -13%                           -18%                -58%                              -61%       -71%                -71%                      -77%                           -79%                   -82%           -83%                              -84%                           -85%                                          -88%           -89%                       -89%                         -91%                                 -91%           -91%              -91%         -91%                 -92% 
  use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu   12.4/s             73%                                                   71%                      8%                                                                --                 -5%                           -10%                -54%                              -57%       -69%                -69%                      -75%                           -77%                   -81%           -82%                              -83%                           -84%                                          -87%           -88%                       -88%                         -90%                                 -90%           -90%              -90%         -90%                 -91% 
  use Log::Dispatch;                                                 13.2/s             84%                                                   82%                     15%                                                                6%                  --                            -5%                -52%                              -55%       -67%                -67%                      -73%                           -76%                   -80%           -81%                              -82%                           -83%                                          -86%           -87%                       -87%                         -89%                                 -89%           -89%              -89%         -90%                 -90% 
  use Log::Contextual qw(:log);                                      13.9/s             94%                                                   92%                     22%                                                               12%                  5%                             --                -49%                              -52%       -65%                -65%                      -72%                           -75%                   -79%           -79%                              -81%                           -82%                                          -85%           -87%                       -87%                         -89%                                 -89%           -89%              -89%         -89%                 -90% 
  use Log::Log4perl;                                                 27.5/s            285%                                                  280%                    141%                                                              122%                108%                            97%                  --                               -6%       -31%                -31%                      -45%                           -50%                   -58%           -60%                              -63%                           -65%                                          -72%           -74%                       -74%                         -78%                                 -78%           -78%              -79%         -79%                 -81% 
  use Log::ger::App; use Log::ger;                                   29.4/s            311%                                                  305%                    157%                                                              137%                122%                           111%                  6%                                --       -27%                -27%                      -41%                           -47%                   -56%           -57%                              -61%                           -62%                                          -70%           -72%                       -73%                         -76%                                 -77%           -77%              -77%         -78%                 -79% 
  use XLog;                                                          40.3/s            464%                                                  456%                    253%                                                              224%                205%                           189%                 46%                               37%         --                  0%                      -20%                           -28%                   -39%           -41%                              -46%                           -49%                                          -59%           -62%                       -63%                         -68%                                 -68%           -68%              -69%         -70%                 -72% 
  use Log::ger::App;                                                 40.5/s            466%                                                  458%                    254%                                                              226%                206%                           190%                 46%                               37%         0%                  --                      -19%                           -27%                   -39%           -41%                              -46%                           -48%                                          -59%           -62%                       -62%                         -68%                                 -68%           -68%              -69%         -70%                 -72% 
  use Log::Log4perl::Tiny;                                           50.5/s            607%                                                  596%                    342%                                                              307%                282%                           262%                 83%                               71%        25%                 24%                        --                           -10%                   -24%           -27%                              -33%                           -36%                                          -48%           -53%                       -53%                         -60%                                 -60%           -61%              -61%         -63%                 -65% 
  use Log::ger::Like::Log4perl;                                      56.2/s            686%                                                  675%                    392%                                                              352%                325%                           303%                103%                               91%        39%                 38%                       11%                             --                   -16%           -19%                              -25%                           -29%                                          -43%           -48%                       -48%                         -55%                                 -56%           -56%              -57%         -58%                 -61% 
  use Log::Any q($log);                                              67.1/s            839%                                                  826%                    487%                                                              440%                408%                           381%                143%                              128%        66%                 65%                       32%                            19%                     --            -3%                              -11%                           -15%                                          -32%           -38%                       -38%                         -47%                                 -48%           -48%              -48%         -50%                 -53% 
  use Log::Any;                                                      69.4/s            872%                                                  858%                    508%                                                              459%                426%                           398%                152%                              136%        72%                 71%                       37%                            23%                     3%             --                               -8%                           -12%                                          -29%           -36%                       -36%                         -45%                                 -46%           -46%              -47%         -49%                 -52% 
  use Log::ger::Output::Composite;                                   75.8/s            960%                                                  945%                    563%                                                              510%                474%                           443%                175%                              157%        87%                 87%                       50%                            34%                    12%             9%                                --                            -4%                                          -23%           -30%                       -30%                         -40%                                 -41%           -41%              -42%         -44%                 -47% 
  use Log::ger::Output::Screen;                                      79.4/s           1011%                                                  995%                    595%                                                              539%                501%                           469%                188%                              169%        96%                 96%                       57%                            41%                    18%            14%                                4%                             --                                          -19%           -26%                       -27%                         -37%                                 -38%           -38%              -39%         -41%                 -45% 
  use Log::ger::Plugin::OptAway; use Log::ger;                       99.0/s           1286%                                                 1266%                    767%                                                              698%                650%                           610%                259%                              236%       145%                144%                       96%                            76%                    47%            42%                               30%                            24%                                            --            -8%                        -9%                         -21%                                 -23%           -23%              -24%         -27%                 -31% 
  use warnings;                                                     108.7/s           1421%                                                 1400%                    852%                                                              776%                723%                           680%                294%                              269%       169%                168%                      115%                            93%                    61%            56%                               43%                            36%                                            9%             --                         0%                         -14%                                 -15%           -16%              -17%         -20%                 -25% 
  use strict; use warnings;                                         109.4/s           1431%                                                 1409%                    858%                                                              781%                729%                           685%                297%                              271%       171%                170%                      116%                            94%                    63%            57%                               44%                            37%                                           10%             0%                         --                         -13%                                 -15%           -15%              -16%         -19%                 -24% 
  use Log::ger::Like::LogAny;                                       126.9/s           1676%                                                 1651%                   1011%                                                              922%                861%                           811%                360%                              331%       214%                213%                      151%                           125%                    89%            82%                               67%                            59%                                           28%            16%                        15%                           --                                  -1%            -2%               -3%          -7%                 -12% 
  use Log::ger; Log::ger->get_logger;                               129.2/s           1708%                                                 1682%                   1031%                                                              941%                879%                           827%                368%                              339%       220%                219%                      155%                           129%                    92%            86%                               70%                            62%                                           30%            18%                        18%                           1%                                   --             0%               -1%          -5%                 -11% 
  use Log::ger;                                                     130.0/s           1720%                                                 1694%                   1039%                                                              948%                885%                           833%                372%                              342%       222%                221%                      157%                           131%                    93%            87%                               71%                            63%                                           31%            19%                        18%                           2%                                   0%             --                0%          -4%                 -10% 
  use Log::ger ();                                                  131.2/s           1737%                                                 1711%                   1049%                                                              957%                894%                           842%                376%                              346%       225%                224%                      159%                           133%                    95%            88%                               73%                            65%                                           32%            20%                        19%                           3%                                   1%             0%                --          -3%                  -9% 
  use strict;                                                       136.6/s           1812%                                                 1785%                   1096%                                                             1001%                935%                           880%                395%                              364%       238%                237%                      170%                           143%                   103%            96%                               80%                            72%                                           37%            25%                        24%                           7%                                   5%             5%                4%           --                  -6% 
  perl -e1 (baseline)                                               145.6/s           1937%                                                 1908%                   1175%                                                             1073%               1003%                           945%                428%                              394%       260%                259%                      188%                           159%                   116%           109%                               92%                            83%                                           47%            33%                        33%                          14%                                  12%            11%               10%           6%                   -- 
 
 Legends:
   perl -e1 (baseline): code_overhead_time=0 participant=perl -e1 (baseline)
   use Log::Any q($log);: code_overhead_time=8.03 participant=use Log::Any q($log);
   use Log::Any;: code_overhead_time=7.53 participant=use Log::Any;
   use Log::Contextual qw(:log);: code_overhead_time=64.93 participant=use Log::Contextual qw(:log);
   use Log::Dispatch;: code_overhead_time=68.93 participant=use Log::Dispatch;
   use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu: code_overhead_time=73.73 participant=use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu
   use Log::Dispatchouli;: code_overhead_time=80.73 participant=use Log::Dispatchouli;
   use Log::Log4perl::Tiny;: code_overhead_time=12.93 participant=use Log::Log4perl::Tiny;
   use Log::Log4perl;: code_overhead_time=29.43 participant=use Log::Log4perl;
   use Log::ger ();: code_overhead_time=0.75 participant=use Log::ger ();
   use Log::ger::App;: code_overhead_time=17.83 participant=use Log::ger::App;
   use Log::ger::App; use Log::ger;: code_overhead_time=27.13 participant=use Log::ger::App; use Log::ger;
   use Log::ger::Like::Log4perl;: code_overhead_time=10.93 participant=use Log::ger::Like::Log4perl;
   use Log::ger::Like::LogAny;: code_overhead_time=1.01 participant=use Log::ger::Like::LogAny;
   use Log::ger::Output::Composite;: code_overhead_time=6.33 participant=use Log::ger::Output::Composite;
   use Log::ger::Output::Screen;: code_overhead_time=5.73 participant=use Log::ger::Output::Screen;
   use Log::ger::Plugin::OptAway; use Log::ger;: code_overhead_time=3.23 participant=use Log::ger::Plugin::OptAway; use Log::ger;
   use Log::ger;: code_overhead_time=0.82 participant=use Log::ger;
   use Log::ger; Log::ger->get_logger;: code_overhead_time=0.87 participant=use Log::ger; Log::ger->get_logger;
   use Mojo::Log;: code_overhead_time=133.13 participant=use Mojo::Log;
   use Mojo::Log; my $log=Mojo::Log->new(level=>"warn"): code_overhead_time=131.13 participant=use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")
   use XLog;: code_overhead_time=17.93 participant=use XLog;
   use strict;: code_overhead_time=0.45 participant=use strict;
   use strict; use warnings;: code_overhead_time=2.27 participant=use strict; use warnings;
   use warnings;: code_overhead_time=2.33 participant=use warnings;

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
