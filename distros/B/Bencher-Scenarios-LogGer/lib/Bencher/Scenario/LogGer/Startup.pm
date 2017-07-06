package Bencher::Scenario::LogGer::Startup;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Measure startup overhead of Log::ger vs other logging libraries',
    modules => {
        'Log::ger' => {version=>'0.011'},
        'Log::ger::Output' => {version=>'0.005'},
        'Log::ger::Layout::Pattern' => {version=>'0'},
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        {name=>"use Log::ger ()", module=>'Log::ger', perl_cmdline => ["-mLog::ger", "-e1"]},

        {name=>"use Log::ger" , module=>'Log::ger', perl_cmdline => ["-MLog::ger", "-e1"]},
        {name=>"use Log::ger + use LGP:OptAway", module=>'Log::ger::Plugin::OptAway', perl_cmdline => ["-MLog::ger::Plugin::OptAway", "-MLog::ger", "-e1"]},
        {name=>"use Log::ger + use LGO:Screen", module=>'Log::ger::Output::Screen', perl_cmdline => ["-MLog::ger", "-MLog::ger::Output=Screen", "-e1"]},
        {name=>"use Log::ger + use LGO:File", module=>'Log::ger::Output::File', perl_cmdline => ["-e", qq(use Log::ger::Output File => (path=>'$fname'); use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (0 outputs)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite; use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (2 outputs)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite => (outputs=>{Screen=>{}, File=>{conf=>{path=>'$fname'}}}); use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (2 outputs + pattern layouts)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite => (outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'$fname'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); use Log::ger)]},
        {name=>"use Log::ger::Like::LogAny" , module=>'Log::ger::Like::LogAny', perl_cmdline => ["-MLog::ger::Like::LogAny", "-e1"]},

        {name=>"use Log::Any" , module=>'Log::Any', perl_cmdline => ["-MLog::Any", "-e1"]},
        {name=>"use Log::Any + use LGA:Screen" , module=>'Log::Any::Adapter::Screen', perl_cmdline => ["-MLog::Any", "-MLog::Any::Adapter=Screen", "-e1"]},

        {name=>"use Log::Log4perl ()", module=>'Log::Log4perl', perl_cmdline => ["-mLog::Log4perl", '-e1']},
        {name=>"use Log::Log4perl + easy_init", module=>'Log::Log4perl', perl_cmdline => ["-MLog::Log4perl=:easy", '-e', 'Log::Log4perl->easy_init']},

        {name=>"use Log::Log4perl::Tiny ()", module=>'Log::Log4perl::Tiny', perl_cmdline => ["-mLog::Log4perl::Tiny", '-e1']},
        {name=>"use Log::Log4perl::Tiny :easy", module=>'Log::Log4perl::Tiny', perl_cmdline => ["-MLog::Log4perl::Tiny=:easy", '-e', 'Log::Log4perl->easy_init']},
    ],
};

1;
# ABSTRACT: Measure startup overhead of Log::ger vs other logging libraries

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::Startup - Measure startup overhead of Log::ger vs other logging libraries

=head1 VERSION

This document describes version 0.009 of Bencher::Scenario::LogGer::Startup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-02.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Startup

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.042

L<Log::Any::Adapter::Screen> 0.13

L<Log::Log4perl> 1.47

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.012

L<Log::ger::Layout::Pattern> 0.001

L<Log::ger::Like::LogAny> 0.001

L<Log::ger::Output> 0.012

L<Log::ger::Output::Composite> 0.007

L<Log::ger::Output::File> 0.002

L<Log::ger::Output::Screen> 0.005

L<Log::ger::Plugin::OptAway> 0.003

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * use Log::ger () (command)

L<Log::ger>



=item * use Log::ger (command)

L<Log::ger>



=item * use Log::ger + use LGP:OptAway (command)

L<Log::ger::Plugin::OptAway>



=item * use Log::ger + use LGO:Screen (command)

L<Log::ger::Output::Screen>



=item * use Log::ger + use LGO:File (command)

L<Log::ger::Output::File>



=item * use Log::ger + use LGO:Composite (0 outputs) (command)

L<Log::ger::Output::Composite>



=item * use Log::ger + use LGO:Composite (2 outputs) (command)

L<Log::ger::Output::Composite>



=item * use Log::ger + use LGO:Composite (2 outputs + pattern layouts) (command)

L<Log::ger::Output::Composite>



=item * use Log::ger::Like::LogAny (command)

L<Log::ger::Like::LogAny>



=item * use Log::Any (command)

L<Log::Any>



=item * use Log::Any + use LGA:Screen (command)

L<Log::Any::Adapter::Screen>



=item * use Log::Log4perl () (command)

L<Log::Log4perl>



=item * use Log::Log4perl + easy_init (command)

L<Log::Log4perl>



=item * use Log::Log4perl::Tiny () (command)

L<Log::Log4perl::Tiny>



=item * use Log::Log4perl::Tiny :easy (command)

L<Log::Log4perl::Tiny>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m LogGer::Startup --include-path archive/Log-Any-0.15/lib --multimodver Log::Any >>:

 #table1#
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                                                    | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | use Log::Log4perl + easy_init                                  |        |      25   |      40   |       1    | 5.4e-05 |      20 |
 | use Log::Log4perl ()                                           |        |      26.2 |      38.1 |       1.04 | 3.3e-05 |      20 |
 | use Log::Log4perl::Tiny :easy                                  |        |      50   |      20   |       2    | 5.1e-05 |      21 |
 | use Log::Log4perl::Tiny ()                                     |        |      51   |      20   |       2    | 2.8e-05 |      20 |
 | use Log::ger + use LGO:Composite (2 outputs + pattern layouts) |        |      51   |      20   |       2    | 2.4e-05 |      20 |
 | use Log::ger + use LGO:Composite (2 outputs)                   |        |      67   |      15   |       2.7  | 1.9e-05 |      22 |
 | use Log::ger + use LGO:Composite (0 outputs)                   |        |      72   |      14   |       2.8  | 2.7e-05 |      20 |
 | use Log::Any + use LGA:Screen                                  |        |      79   |      13   |       3.1  | 3.4e-05 |      21 |
 | use Log::Any                                                   | 1.042  |      97   |      10   |       3.9  | 3.6e-05 |      20 |
 | use Log::ger + use LGO:Screen                                  |        |      98   |      10   |       3.9  | 3.3e-05 |      20 |
 | use Log::ger + use LGO:File                                    |        |     100   |       9.7 |       4.1  | 2.5e-05 |      21 |
 | use Log::ger::Like::LogAny                                     |        |     120   |       8.5 |       4.7  | 1.1e-05 |      20 |
 | use Log::ger + use LGP:OptAway                                 |        |     140   |       7.1 |       5.6  | 2.8e-05 |      20 |
 | use Log::Any                                                   | 0.15   |     190   |       5.3 |       7.5  | 1.3e-05 |      20 |
 | use Log::ger                                                   |        |     230   |       4.4 |       9.1  | 8.9e-06 |      21 |
 | use Log::ger ()                                                |        |     240   |       4.2 |       9.5  |   1e-05 |      20 |
 | baseline                                                       |        |     470   |       2.1 |      19    | 4.2e-06 |      20 |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark with C<< bencher -m LogGer::Startup --include-participant-pattern 'Log::ger|baseline' --include-path archive/Log-ger-0.005/lib --include-path archive/Log-ger-0.006/lib --include-path archive/Log-ger-0.007/lib --include-path archive/Log-ger-0.008/lib --include-path archive/Log-ger-0.009/lib --include-path archive/Log-ger-0.010/lib --multimodver Log::ger >>:

 #table2#
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | participant                                                    | modver | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | use Log::ger + use LGO:Composite (2 outputs + pattern layouts) |        |      40   |     20    |       1    |   0.00088 |      23 |
 | use Log::ger + use LGO:Composite (2 outputs)                   |        |      70   |     14    |       1.7  | 1.5e-05   |      20 |
 | use Log::ger + use LGO:Composite (0 outputs)                   |        |      75   |     13    |       1.8  | 1.8e-05   |      20 |
 | use Log::ger::Like::LogAny                                     |        |      97.7 |     10.2  |       2.32 |   9e-06   |      20 |
 | use Log::ger + use LGO:Screen                                  |        |      98   |     10    |       2.3  | 3.8e-05   |      21 |
 | use Log::ger + use LGO:File                                    |        |     110   |      9.5  |       2.5  | 1.3e-05   |      20 |
 | use Log::ger + use LGP:OptAway                                 |        |     140   |      7    |       3.4  |   2e-05   |      22 |
 | use Log::ger ()                                                | 0.005  |     200   |      5    |       4    |   0.00013 |      20 |
 | use Log::ger                                                   | 0.012  |     230   |      4.3  |       5.5  | 6.1e-06   |      21 |
 | use Log::ger ()                                                | 0.012  |     240   |      4.1  |       5.8  | 7.4e-06   |      20 |
 | use Log::ger                                                   | 0.005  |     250   |      4    |       5.9  | 1.5e-05   |      20 |
 | use Log::ger                                                   | 0.008  |     272   |      3.67 |       6.48 | 3.3e-06   |      20 |
 | use Log::ger                                                   | 0.010  |     270   |      3.7  |       6.5  | 7.4e-06   |      21 |
 | use Log::ger                                                   | 0.006  |     270   |      3.6  |       6.5  | 1.1e-05   |      20 |
 | use Log::ger                                                   | 0.007  |     280   |      3.6  |       6.5  | 7.6e-06   |      20 |
 | use Log::ger                                                   | 0.009  |     280   |      3.6  |       6.6  | 9.2e-06   |      20 |
 | use Log::ger ()                                                | 0.006  |     280   |      3.6  |       6.6  | 6.7e-06   |      20 |
 | use Log::ger ()                                                | 0.010  |     290   |      3.5  |       6.8  | 8.5e-06   |      20 |
 | use Log::ger ()                                                | 0.008  |     290   |      3.5  |       6.8  | 1.4e-05   |      21 |
 | use Log::ger ()                                                | 0.007  |     290   |      3.5  |       6.9  | 8.5e-06   |      20 |
 | use Log::ger ()                                                | 0.009  |     290   |      3.4  |       6.9  | 9.2e-06   |      20 |
 | baseline                                                       |        |     500   |      2    |      12    | 7.4e-06   |      20 |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::Startup --module-startup >>):

 #table3#
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Log::Log4perl               | 1.4                          | 4.7                | 17             |     42    |                  36.92 |       1    |   0.00011 |      20 |
 | Log::Log4perl::Tiny         | 1.4                          | 4.7                | 17             |     22    |                  16.92 |       1.9  | 2.8e-05   |      20 |
 | Log::Any::Adapter::Screen   | 0.98                         | 4.3                | 16             |     15    |                   9.92 |       2.7  |   4e-05   |      20 |
 | Log::Any                    | 0.98                         | 4.3                | 16             |     13    |                   7.92 |       3.2  |   4e-05   |      20 |
 | Log::ger::Like::LogAny      | 0.98                         | 4.2                | 16             |     12    |                   6.92 |       3.6  | 2.4e-05   |      20 |
 | Log::ger::Output::Screen    | 0.84                         | 4.1                | 16             |     11    |                   5.92 |       3.8  | 3.5e-05   |      20 |
 | Log::ger::Output::Composite | 0.84                         | 4.1                | 16             |      8.6  |                   3.52 |       4.9  | 3.2e-05   |      20 |
 | Log::ger::Plugin::OptAway   | 1.1                          | 4.5                | 16             |      7.8  |                   2.72 |       5.4  | 4.3e-05   |      20 |
 | Log::ger::Output::File      | 1.4                          | 4.7                | 17             |      7.7  |                   2.62 |       5.4  | 2.7e-05   |      20 |
 | Log::ger                    | 1.1                          | 4.4                | 16             |      7.3  |                   2.22 |       5.8  | 7.8e-06   |      20 |
 | perl -e1 (baseline)         | 0.824                        | 4.16               | 16             |      5.08 |                   0    |       8.24 | 4.7e-06   |      20 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
