package Bencher::Scenario::Log::ger::NullOutput;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

our $scenario = {
    summary => 'Benchmark Log::ger logging speed with the default/null output',
    modules => {
        'Log::ger' => {version=>'0.023'},
        'Log::ger::Format::MultilevelLog' => {},
        'Log::ger::Plugin::OptAway' => {},
        'Log::Any' => {},
        'Log::Fast' => {},
        'Log::Log4perl' => {},
        'Log::Log4perl::Tiny' => {},
        'Log::Contextual' => {},
        'Log::Contextual::SimpleLogger' => {},
        'Log::Dispatch' => {},
        'Log::Dispatch::Null' => {},
        'Log::Dispatchouli' => {},
        'Mojo::Log' => {},
        'XLog' => {},
    },
    participants => [
        {
            name => 'Log::ger-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger-100k_log_is_trace',
            perl_cmdline_template => ['-MLog::ger', '-e', 'for(1..100_000) { log_is_trace() }'],
        },
        {
            name => 'Log::ger+LGP:OptAway-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Plugin=OptAway', '-MLog::ger', '-e', 'for(1..100_000) { log_trace(q[]) }'],
        },
        {
            name => 'Log::ger+LGF:MutilevelLog-100k_log_trace',
            perl_cmdline_template => ['-MLog::ger::Format=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log("trace", q[]) }'],
        },
        {
            name => 'Log::ger+LGP:MutilevelLog-100k_log_6',
            perl_cmdline_template => ['-MLog::ger::Format=MultilevelLog', '-MLog::ger', '-e', 'for(1..100_000) { log(6, q[]) }'],
        },

        {
            name => 'Log::Fast-100k_DEBUG',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }'],
        },
        {
            name => 'Log::Fast-100k_is_debug',
            perl_cmdline_template => ['-MLog::Fast', '-e', '$LOG = Log::Fast->global; for(1..100_000) { $LOG->level() eq "DEBUG" }'],
        },

        {
            name => 'Log::Any-no_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-no_adapter-100k_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-e', 'my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }'],
        },
        {
            name => 'Log::Any-null_adapter-100k_log_trace',
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }'],
        },
        {
            name => 'Log::Any-null_adapter-100k_is_trace' ,
            perl_cmdline_template => ['-MLog::Any', '-MLog::Any::Adapter', '-e', 'Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }'],
        },

        {
            name => 'Log::Dispatch::Null-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatch', '-e', 'my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }'],
        },

        {
            name => 'Log::Log4perl-easy-100k_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl=:easy', '-e', 'Log::Log4perl->easy_init($ERROR); for(1..100_000) { TRACE "" }'],
        },

        {
            name => 'Log::Log4perl::Tiny-100k_trace' ,
            perl_cmdline_template => ['-MLog::Log4perl::Tiny=:easy', '-e', 'for(1..100_000) { TRACE "" }'],
        },

        {
            name => 'Log::Contextual+Log4perl-100k_trace' ,
            perl_cmdline_template => ['-e', 'use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..100_000) { log_trace {} }'],
        },
        {
            name => 'Log::Contextual+SimpleLogger-100k_trace' ,
            perl_cmdline_template => ['-MLog::Contextual::SimpleLogger', '-e', 'use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..100_000) { log_trace {} }'],
        },

        {
            name => 'Log::Dispatchouli-100k_debug' ,
            perl_cmdline_template => ['-MLog::Dispatchouli', '-e', '$logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }'],
        },

        {
            name => 'Mojo::Log-100k_debug' ,
            perl_cmdline_template => ['-MMojo::Log', '-e', '$log = Mojo::Log->new(level=>"warn"); for(1..100_000) { $log->debug("") }'],
        },

        {
            name => 'XLog-100k_debug' ,
            perl_cmdline_template => ['-MXLog', '-e', 'for(1..100_000) { XLog::debug("") }'],
        },
    ],
    precision => 6,
};

1;
# ABSTRACT: Benchmark Log::ger logging speed with the default/null output

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::NullOutput - Benchmark Log::ger logging speed with the default/null output

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::Log::ger::NullOutput (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::NullOutput

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.717

L<Log::Contextual> 0.008001

L<Log::Contextual::SimpleLogger> 0.008001

L<Log::Dispatch> 2.71

L<Log::Dispatch::Null> 2.71

L<Log::Dispatchouli> 3.007

L<Log::Fast> v2.0.1

L<Log::Log4perl> 1.57

L<Log::Log4perl::Tiny> 1.8.0

L<Log::ger> 0.042

L<Log::ger::Format::MultilevelLog> 0.042

L<Log::ger::Plugin::OptAway> 0.009

L<Mojo::Log>

L<XLog> 1.1.3

=head1 BENCHMARK PARTICIPANTS

=over

=item * Log::ger-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::ger-100k_log_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger -e for(1..100_000) { log_is_trace() }



=item * Log::ger+LGP:OptAway-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Plugin=OptAway -MLog::ger -e for(1..100_000) { log_trace(q[]) }



=item * Log::ger+LGF:MutilevelLog-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Format=MultilevelLog -MLog::ger -e for(1..100_000) { log("trace", q[]) }



=item * Log::ger+LGP:MutilevelLog-100k_log_6 (command)

Command line:

 #TEMPLATE: #perl -MLog::ger::Format=MultilevelLog -MLog::ger -e for(1..100_000) { log(6, q[]) }



=item * Log::Fast-100k_DEBUG (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; $LOG->level("INFO"); for(1..100_000) { $LOG->DEBUG(q()) }



=item * Log::Fast-100k_is_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Fast -e $LOG = Log::Fast->global; for(1..100_000) { $LOG->level() eq "DEBUG" }



=item * Log::Any-no_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Any-no_adapter-100k_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -e my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }



=item * Log::Any-null_adapter-100k_log_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->trace(q[]) }



=item * Log::Any-null_adapter-100k_is_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Any -MLog::Any::Adapter -e Log::Any::Adapter->set(q[Null]); my $log = Log::Any->get_logger; for(1..100_000) { $log->is_trace }



=item * Log::Dispatch::Null-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatch -e my $null = Log::Dispatch->new(outputs=>[["Null", min_level=>"debug"]]); for(1..100_000) { $null->debug("") }



=item * Log::Log4perl-easy-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl=:easy -e Log::Log4perl->easy_init($ERROR); for(1..100_000) { TRACE "" }



=item * Log::Log4perl::Tiny-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Log4perl::Tiny=:easy -e for(1..100_000) { TRACE "" }



=item * Log::Contextual+Log4perl-100k_trace (command)

Command line:

 #TEMPLATE: #perl -e use Log::Contextual ":log", "set_logger"; use Log::Log4perl ":easy"; Log::Log4perl->easy_init($DEBUG); my $logger = Log::Log4perl->get_logger; set_logger $logger; for(1..100_000) { log_trace {} }



=item * Log::Contextual+SimpleLogger-100k_trace (command)

Command line:

 #TEMPLATE: #perl -MLog::Contextual::SimpleLogger -e use Log::Contextual ":log", -logger=>Log::Contextual::SimpleLogger->new({levels=>["debug"]}); for(1..100_000) { log_trace {} }



=item * Log::Dispatchouli-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MLog::Dispatchouli -e $logger = Log::Dispatchouli->new({ident=>"ident", facility=>"facility", to_stdout=>1, debug=>0}); for(1..100_000) { $logger->log_debug("") }



=item * Mojo::Log-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MMojo::Log -e $log = Mojo::Log->new(level=>"warn"); for(1..100_000) { $log->debug("") }



=item * XLog-100k_debug (command)

Command line:

 #TEMPLATE: #perl -MXLog -e for(1..100_000) { XLog::debug("") }



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::NullOutput

Result formatted as table:

 #table1#
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                              | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | Log::Dispatch::Null-100k_debug           |      1.9  |     520   |                 0.00% |              3984.92% |   0.0018  |       6 |
 | Log::Contextual+Log4perl-100k_trace      |      2.2  |     460   |                12.02% |              3546.51% |   0.0013  |       6 |
 | Log::Contextual+SimpleLogger-100k_trace  |      2.2  |     440   |                15.99% |              3421.69% |   0.0018  |       6 |
 | Mojo::Log-100k_debug                     |      5.54 |     181   |               185.56% |              1330.48% |   0.00015 |       6 |
 | Log::Dispatchouli-100k_debug             |      5.97 |     168   |               207.90% |              1226.72% |   0.00016 |       6 |
 | Log::Log4perl::Tiny-100k_trace           |      9.74 |     103   |               402.66% |               712.66% | 5.2e-05   |       6 |
 | Log::Fast-100k_is_debug                  |     15.5  |      64.4 |               700.84% |               410.08% |   5e-05   |       6 |
 | Log::Any-null_adapter-100k_log_trace     |     16    |      63   |               717.02% |               399.98% | 8.5e-05   |       6 |
 | Log::Log4perl-easy-100k_trace            |     17.8  |      56.2 |               817.79% |               345.08% |   3e-05   |       6 |
 | Log::Any-no_adapter-100k_is_trace        |     23    |      44   |              1085.67% |               244.52% | 6.3e-05   |       6 |
 | Log::Any-null_adapter-100k_is_trace      |     23    |      43.4 |              1088.31% |               243.76% | 3.9e-05   |       6 |
 | Log::Fast-100k_DEBUG                     |     25.7  |      38.9 |              1225.64% |               208.15% | 1.1e-05   |       6 |
 | XLog-100k_debug                          |     35    |      28   |              1720.58% |               124.37% | 3.1e-05   |       6 |
 | Log::Any-no_adapter-100k_log_trace       |     41.1  |      24.3 |              2021.80% |                92.52% |   5e-06   |       6 |
 | Log::ger+LGP:OptAway-100k_log_trace      |     44    |      23   |              2166.65% |                80.22% | 2.5e-05   |       6 |
 | Log::ger+LGF:MutilevelLog-100k_log_trace |     49    |      21   |              2410.91% |                62.69% | 4.3e-05   |       6 |
 | Log::ger+LGP:MutilevelLog-100k_log_6     |     49    |      20   |              2423.68% |                61.86% | 3.2e-05   |       6 |
 | Log::ger-100k_log_trace                  |     75.4  |      13.3 |              3789.52% |                 5.02% | 5.2e-06   |       6 |
 | Log::ger-100k_log_is_trace               |     79.2  |      12.6 |              3984.92% |                 0.00% | 2.9e-06   |       6 |
 +------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                              Rate  Log::Dispatch::Null-100k_debug  Log::Contextual+Log4perl-100k_trace  Log::Contextual+SimpleLogger-100k_trace  Mojo::Log-100k_debug  Log::Dispatchouli-100k_debug  Log::Log4perl::Tiny-100k_trace  Log::Fast-100k_is_debug  Log::Any-null_adapter-100k_log_trace  Log::Log4perl-easy-100k_trace  Log::Any-no_adapter-100k_is_trace  Log::Any-null_adapter-100k_is_trace  Log::Fast-100k_DEBUG  XLog-100k_debug  Log::Any-no_adapter-100k_log_trace  Log::ger+LGP:OptAway-100k_log_trace  Log::ger+LGF:MutilevelLog-100k_log_trace  Log::ger+LGP:MutilevelLog-100k_log_6  Log::ger-100k_log_trace  Log::ger-100k_log_is_trace 
  Log::Dispatch::Null-100k_debug             1.9/s                              --                                 -11%                                     -15%                  -65%                          -67%                            -80%                     -87%                                  -87%                           -89%                               -91%                                 -91%                  -92%             -94%                                -95%                                 -95%                                      -95%                                  -96%                     -97%                        -97% 
  Log::Contextual+Log4perl-100k_trace        2.2/s                             13%                                   --                                      -4%                  -60%                          -63%                            -77%                     -86%                                  -86%                           -87%                               -90%                                 -90%                  -91%             -93%                                -94%                                 -95%                                      -95%                                  -95%                     -97%                        -97% 
  Log::Contextual+SimpleLogger-100k_trace    2.2/s                             18%                                   4%                                       --                  -58%                          -61%                            -76%                     -85%                                  -85%                           -87%                               -90%                                 -90%                  -91%             -93%                                -94%                                 -94%                                      -95%                                  -95%                     -96%                        -97% 
  Mojo::Log-100k_debug                      5.54/s                            187%                                 154%                                     143%                    --                           -7%                            -43%                     -64%                                  -65%                           -68%                               -75%                                 -76%                  -78%             -84%                                -86%                                 -87%                                      -88%                                  -88%                     -92%                        -93% 
  Log::Dispatchouli-100k_debug              5.97/s                            209%                                 173%                                     161%                    7%                            --                            -38%                     -61%                                  -62%                           -66%                               -73%                                 -74%                  -76%             -83%                                -85%                                 -86%                                      -87%                                  -88%                     -92%                        -92% 
  Log::Log4perl::Tiny-100k_trace            9.74/s                            404%                                 346%                                     327%                   75%                           63%                              --                     -37%                                  -38%                           -45%                               -57%                                 -57%                  -62%             -72%                                -76%                                 -77%                                      -79%                                  -80%                     -87%                        -87% 
  Log::Fast-100k_is_debug                   15.5/s                            707%                                 614%                                     583%                  181%                          160%                             59%                       --                                   -2%                           -12%                               -31%                                 -32%                  -39%             -56%                                -62%                                 -64%                                      -67%                                  -68%                     -79%                        -80% 
  Log::Any-null_adapter-100k_log_trace        16/s                            725%                                 630%                                     598%                  187%                          166%                             63%                       2%                                    --                           -10%                               -30%                                 -31%                  -38%             -55%                                -61%                                 -63%                                      -66%                                  -68%                     -78%                        -80% 
  Log::Log4perl-easy-100k_trace             17.8/s                            825%                                 718%                                     682%                  222%                          198%                             83%                      14%                                   12%                             --                               -21%                                 -22%                  -30%             -50%                                -56%                                 -59%                                      -62%                                  -64%                     -76%                        -77% 
  Log::Any-no_adapter-100k_is_trace           23/s                           1081%                                 945%                                     900%                  311%                          281%                            134%                      46%                                   43%                            27%                                 --                                  -1%                  -11%             -36%                                -44%                                 -47%                                      -52%                                  -54%                     -69%                        -71% 
  Log::Any-null_adapter-100k_is_trace         23/s                           1098%                                 959%                                     913%                  317%                          287%                            137%                      48%                                   45%                            29%                                 1%                                   --                  -10%             -35%                                -44%                                 -47%                                      -51%                                  -53%                     -69%                        -70% 
  Log::Fast-100k_DEBUG                      25.7/s                           1236%                                1082%                                    1031%                  365%                          331%                            164%                      65%                                   61%                            44%                                13%                                  11%                    --             -28%                                -37%                                 -40%                                      -46%                                  -48%                     -65%                        -67% 
  XLog-100k_debug                             35/s                           1757%                                1542%                                    1471%                  546%                          500%                            267%                     130%                                  125%                           100%                                57%                                  55%                   38%               --                                -13%                                 -17%                                      -25%                                  -28%                     -52%                        -55% 
  Log::Any-no_adapter-100k_log_trace        41.1/s                           2039%                                1793%                                    1710%                  644%                          591%                            323%                     165%                                  159%                           131%                                81%                                  78%                   60%              15%                                  --                                  -5%                                      -13%                                  -17%                     -45%                        -48% 
  Log::ger+LGP:OptAway-100k_log_trace         44/s                           2160%                                1900%                                    1813%                  686%                          630%                            347%                     180%                                  173%                           144%                                91%                                  88%                   69%              21%                                  5%                                   --                                       -8%                                  -13%                     -42%                        -45% 
  Log::ger+LGF:MutilevelLog-100k_log_trace    49/s                           2376%                                2090%                                    1995%                  761%                          700%                            390%                     206%                                  200%                           167%                               109%                                 106%                   85%              33%                                 15%                                   9%                                        --                                   -4%                     -36%                        -40% 
  Log::ger+LGP:MutilevelLog-100k_log_6        49/s                           2500%                                2200%                                    2100%                  805%                          740%                            415%                     222%                                  215%                           181%                               120%                                 117%                   94%              39%                                 21%                                  14%                                        5%                                    --                     -33%                        -37% 
  Log::ger-100k_log_trace                   75.4/s                           3809%                                3358%                                    3208%                 1260%                         1163%                            674%                     384%                                  373%                           322%                               230%                                 226%                  192%             110%                                 82%                                  72%                                       57%                                   50%                       --                         -5% 
  Log::ger-100k_log_is_trace                79.2/s                           4026%                                3550%                                    3392%                 1336%                         1233%                            717%                     411%                                  400%                           346%                               249%                                 244%                  208%             122%                                 92%                                  82%                                       66%                                   58%                       5%                          -- 
 
 Legends:
   Log::Any-no_adapter-100k_is_trace: participant=Log::Any-no_adapter-100k_is_trace
   Log::Any-no_adapter-100k_log_trace: participant=Log::Any-no_adapter-100k_log_trace
   Log::Any-null_adapter-100k_is_trace: participant=Log::Any-null_adapter-100k_is_trace
   Log::Any-null_adapter-100k_log_trace: participant=Log::Any-null_adapter-100k_log_trace
   Log::Contextual+Log4perl-100k_trace: participant=Log::Contextual+Log4perl-100k_trace
   Log::Contextual+SimpleLogger-100k_trace: participant=Log::Contextual+SimpleLogger-100k_trace
   Log::Dispatch::Null-100k_debug: participant=Log::Dispatch::Null-100k_debug
   Log::Dispatchouli-100k_debug: participant=Log::Dispatchouli-100k_debug
   Log::Fast-100k_DEBUG: participant=Log::Fast-100k_DEBUG
   Log::Fast-100k_is_debug: participant=Log::Fast-100k_is_debug
   Log::Log4perl-easy-100k_trace: participant=Log::Log4perl-easy-100k_trace
   Log::Log4perl::Tiny-100k_trace: participant=Log::Log4perl::Tiny-100k_trace
   Log::ger+LGF:MutilevelLog-100k_log_trace: participant=Log::ger+LGF:MutilevelLog-100k_log_trace
   Log::ger+LGP:MutilevelLog-100k_log_6: participant=Log::ger+LGP:MutilevelLog-100k_log_6
   Log::ger+LGP:OptAway-100k_log_trace: participant=Log::ger+LGP:OptAway-100k_log_trace
   Log::ger-100k_log_is_trace: participant=Log::ger-100k_log_is_trace
   Log::ger-100k_log_trace: participant=Log::ger-100k_log_trace
   Mojo::Log-100k_debug: participant=Mojo::Log-100k_debug
   XLog-100k_debug: participant=XLog-100k_debug

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

Not included here:

=over

=item * L<Log::Tiny>

Cannot do null output, must log to a file. (Technically you can use F</dev/null>, but.)

=back

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
