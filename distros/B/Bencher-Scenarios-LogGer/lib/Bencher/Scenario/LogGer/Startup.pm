package Bencher::Scenario::LogGer::Startup;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Measure startup overhead of Log::ger vs other logging libraries',
    modules => {
        'Log::ger' => {version=>'0.015'},
        'Log::ger::App' => {version=>'0.002'},
        'Log::ger::Output' => {version=>'0.005'},
        'Log::ger::Layout::Pattern' => {version=>'0'},
    },
    participants => [
        {name=>"baseline", perl_cmdline => ["-e1"]},

        {name=>"use Log::ger ()", module=>'Log::ger', perl_cmdline => ["-mLog::ger", "-e1"]},

        {name=>"use Log::ger" , module=>'Log::ger', perl_cmdline => ["-MLog::ger", "-e1"]},
        {name=>"use Log::ger + get_logger()" , module=>'Log::ger', perl_cmdline => ["-mLog::ger", "-e", '$log = Log::ger->get_logger()']},
        {name=>"use Log::ger + use LGP:OptAway", module=>'Log::ger::Plugin::OptAway', perl_cmdline => ["-MLog::ger::Plugin::OptAway", "-MLog::ger", "-e1"]},
        {name=>"use Log::ger + use LGO:Screen", module=>'Log::ger::Output::Screen', perl_cmdline => ["-MLog::ger", "-MLog::ger::Output=Screen", "-e1"]},
        {name=>"use Log::ger + use LGO:File", module=>'Log::ger::Output::File', perl_cmdline => ["-e", qq(use Log::ger::Output File => (path=>'$fname'); use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (0 outputs)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite; use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (2 outputs)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite => (outputs=>{Screen=>{}, File=>{conf=>{path=>'$fname'}}}); use Log::ger)]},
        {name=>"use Log::ger + use LGO:Composite (2 outputs + pattern layouts)", module=>'Log::ger::Output::Composite', perl_cmdline => ["-e", qq(use Log::ger::Output Composite => (outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'$fname'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); use Log::ger)]},
        {name=>"use Log::ger::Like::LogAny" , module=>'Log::ger::Like::LogAny', perl_cmdline => ["-MLog::ger::Like::LogAny", "-e1"]},
        {name=>"use Log::ger::Like::Log4perl" , module=>'Log::ger::Like::Log4perl', perl_cmdline => ["-MLog::ger::Like::Log4perl", "-e1"]},
        {name=>"use Log::ger::App" , module=>'Log::ger::App', perl_cmdline => ["-MLog::ger::App", "-e1"]},

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

This document describes version 0.010 of Bencher::Scenario::LogGer::Startup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-13.

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

L<Log::ger> 0.016

L<Log::ger::App> 0.002

L<Log::ger::Layout::Pattern> 0.001

L<Log::ger::Like::Log4perl> 0.001

L<Log::ger::Like::LogAny> 0.003

L<Log::ger::Output> 0.016

L<Log::ger::Output::Composite> 0.007

L<Log::ger::Output::File> 0.002

L<Log::ger::Output::Screen> 0.005

L<Log::ger::Plugin::OptAway> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * use Log::ger () (command)

L<Log::ger>



=item * use Log::ger (command)

L<Log::ger>



=item * use Log::ger + get_logger() (command)

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



=item * use Log::ger::Like::Log4perl (command)

L<Log::ger::Like::Log4perl>



=item * use Log::ger::App (command)

L<Log::ger::App>



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

Benchmark with C<< bencher -m LogGer::Startup --include-path archive/Log-Any-0.15/lib --include-path archive/Log-Any-1.00/lib --multimodver Log::Any >>:

 #table1#
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | participant                                                    | modver | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+
 | use Log::Log4perl + easy_init                                  |        |        25 |      41   |        1   |   0.00013 |      20 |
 | use Log::Log4perl ()                                           |        |        25 |      40   |        1   |   0.00018 |      20 |
 | use Log::ger + use LGO:Composite (2 outputs + pattern layouts) |        |        49 |      21   |        2   | 8.4e-05   |      20 |
 | use Log::Log4perl::Tiny :easy                                  |        |        49 |      20   |        2   | 8.5e-05   |      20 |
 | use Log::Log4perl::Tiny ()                                     |        |        49 |      20   |        2   |   0.0001  |      20 |
 | use Log::Any                                                   | 1.00   |        49 |      20   |        2   |   0.00014 |      20 |
 | use Log::ger + use LGO:Composite (2 outputs)                   |        |        63 |      16   |        2.6 |   3e-05   |      20 |
 | use Log::ger + use LGO:Composite (0 outputs)                   |        |        67 |      15   |        2.7 |   0.0001  |      20 |
 | use Log::ger::Like::Log4perl                                   |        |        70 |      14   |        2.8 | 7.8e-05   |      20 |
 | use Log::ger::App                                              |        |        73 |      14   |        3   | 2.8e-05   |      20 |
 | use Log::Any + use LGA:Screen                                  |        |        77 |      13   |        3.1 | 3.5e-05   |      20 |
 | use Log::Any                                                   | 1.042  |        91 |      11   |        3.7 |   2e-05   |      20 |
 | use Log::ger + use LGO:Screen                                  |        |        94 |      11   |        3.8 | 2.2e-05   |      20 |
 | use Log::ger + use LGO:File                                    |        |        95 |      10   |        3.9 | 2.5e-05   |      21 |
 | use Log::ger + use LGP:OptAway                                 |        |       160 |       6.3 |        6.4 | 2.1e-05   |      20 |
 | use Log::Any                                                   | 0.15   |       170 |       6   |        6.7 | 2.5e-05   |      21 |
 | use Log::ger + get_logger()                                    |        |       290 |       3.4 |       12   | 1.7e-05   |      20 |
 | use Log::ger                                                   |        |       300 |       3.3 |       12   | 8.5e-06   |      20 |
 | use Log::ger ()                                                |        |       310 |       3.2 |       13   | 5.1e-06   |      20 |
 | use Log::ger::Like::LogAny                                     |        |       360 |       2.7 |       15   | 1.1e-05   |      20 |
 | baseline                                                       |        |       440 |       2.3 |       18   | 7.8e-06   |      20 |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+-----------+---------+


Benchmark with C<< bencher -m LogGer::Startup --include-participant-pattern 'Log::ger|baseline' --include-path archive/Log-ger-0.005/lib --include-path archive/Log-ger-0.006/lib --include-path archive/Log-ger-0.007/lib --include-path archive/Log-ger-0.008/lib --include-path archive/Log-ger-0.009/lib --include-path archive/Log-ger-0.010/lib --include-path archive/Log-ger-0.011/lib --include-path archive/Log-ger-0.012/lib --include-path archive/Log-ger-0.016/lib --multimodver Log::ger >>:

 #table2#
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | participant                                                    | modver | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+
 | use Log::ger + use LGO:Composite (2 outputs + pattern layouts) |        |        50 |      20   |        1   | 5.5e-05 |      20 |
 | use Log::ger + use LGO:Composite (2 outputs)                   |        |        63 |      16   |        1.3 | 5.7e-05 |      20 |
 | use Log::ger + use LGO:Composite (0 outputs)                   |        |        71 |      14   |        1.4 | 2.5e-05 |      20 |
 | use Log::ger::Like::Log4perl                                   |        |        71 |      14   |        1.4 | 2.1e-05 |      20 |
 | use Log::ger::App                                              |        |        75 |      13   |        1.5 | 3.8e-05 |      20 |
 | use Log::ger + use LGO:Screen                                  |        |        94 |      11   |        1.9 | 1.6e-05 |      21 |
 | use Log::ger + use LGO:File                                    |        |        96 |      10   |        1.9 | 1.4e-05 |      20 |
 | use Log::ger + use LGP:OptAway                                 |        |       170 |       5.8 |        3.5 | 1.7e-05 |      22 |
 | use Log::ger                                                   | 0.011  |       210 |       4.8 |        4.2 |   9e-06 |      20 |
 | use Log::ger + get_logger()                                    | 0.011  |       210 |       4.7 |        4.3 | 1.1e-05 |      20 |
 | use Log::ger + get_logger()                                    | 0.012  |       210 |       4.7 |        4.3 | 1.1e-05 |      20 |
 | use Log::ger ()                                                | 0.011  |       220 |       4.6 |        4.3 | 1.9e-05 |      20 |
 | use Log::ger                                                   | 0.012  |       220 |       4.6 |        4.4 | 9.8e-06 |      21 |
 | use Log::ger ()                                                | 0.012  |       230 |       4.4 |        4.6 | 8.4e-06 |      21 |
 | use Log::ger + get_logger()                                    | 0.008  |       250 |       4   |        5.1 | 6.5e-06 |      20 |
 | use Log::ger + get_logger()                                    | 0.006  |       260 |       3.9 |        5.1 | 1.2e-05 |      20 |
 | use Log::ger + get_logger()                                    | 0.009  |       260 |       3.9 |        5.1 |   6e-06 |      22 |
 | use Log::ger + get_logger()                                    | 0.005  |       260 |       3.9 |        5.2 | 1.1e-05 |      20 |
 | use Log::ger ()                                                | 0.007  |       260 |       3.9 |        5.2 | 1.2e-05 |      20 |
 | use Log::ger + get_logger()                                    | 0.007  |       260 |       3.9 |        5.2 | 6.9e-06 |      20 |
 | use Log::ger + get_logger()                                    | 0.010  |       260 |       3.9 |        5.2 | 9.4e-06 |      23 |
 | use Log::ger                                                   | 0.005  |       260 |       3.9 |        5.2 | 8.3e-06 |      20 |
 | use Log::ger ()                                                | 0.009  |       260 |       3.9 |        5.2 | 1.1e-05 |      20 |
 | use Log::ger ()                                                | 0.008  |       260 |       3.9 |        5.2 | 1.6e-05 |      20 |
 | use Log::ger                                                   | 0.009  |       260 |       3.9 |        5.2 | 4.7e-06 |      20 |
 | use Log::ger                                                   | 0.008  |       260 |       3.9 |        5.2 | 9.6e-06 |      21 |
 | use Log::ger                                                   | 0.006  |       260 |       3.9 |        5.2 | 7.6e-06 |      20 |
 | use Log::ger ()                                                | 0.006  |       260 |       3.9 |        5.2 | 1.1e-05 |      20 |
 | use Log::ger                                                   | 0.010  |       260 |       3.8 |        5.2 | 9.1e-06 |      20 |
 | use Log::ger                                                   | 0.007  |       260 |       3.8 |        5.3 | 1.1e-05 |      20 |
 | use Log::ger ()                                                | 0.010  |       270 |       3.8 |        5.4 | 6.8e-06 |      21 |
 | use Log::ger ()                                                | 0.005  |       270 |       3.8 |        5.4 | 1.5e-05 |      20 |
 | use Log::ger                                                   | 0.016  |       320 |       3.1 |        6.5 | 1.4e-05 |      20 |
 | use Log::ger + get_logger()                                    | 0.016  |       320 |       3.1 |        6.5 | 7.1e-06 |      20 |
 | use Log::ger ()                                                | 0.016  |       330 |       3.1 |        6.6 | 1.1e-05 |      21 |
 | use Log::ger::Like::LogAny                                     |        |       380 |       2.6 |        7.7 | 4.1e-06 |      21 |
 | baseline                                                       |        |       450 |       2.2 |        9   | 8.3e-06 |      20 |
 +----------------------------------------------------------------+--------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::Startup --module-startup >>):

 #table3#
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::Log4perl               | 0.84                         | 4.2                | 16             |      45   |     38.1               |        1   | 8.5e-05 |      20 |
 | Log::Log4perl::Tiny         | 0.88                         | 4.1                | 16             |      24   |     17.1               |        1.8 |   9e-05 |      20 |
 | Log::ger::Like::Log4perl    | 0.98                         | 4.2                | 16             |      18   |     11.1               |        2.5 | 3.1e-05 |      21 |
 | Log::ger::App               | 0.98                         | 4.3                | 16             |      18   |     11.1               |        2.5 | 5.8e-05 |      20 |
 | Log::Any::Adapter::Screen   | 0.84                         | 4.2                | 16             |      17   |     10.1               |        2.6 | 7.2e-05 |      20 |
 | Log::Any                    | 0.98                         | 4.3                | 16             |      15   |      8.1               |        3   | 3.6e-05 |      20 |
 | Log::ger::Output::Screen    | 0.9                          | 4.2                | 16             |      13   |      6.1               |        3.4 | 3.4e-05 |      20 |
 | Log::ger::Output::Composite | 1.4                          | 4.8                | 17             |      11   |      4.1               |        4.3 | 3.8e-05 |      20 |
 | Log::ger::Plugin::OptAway   | 0.9                          | 4.2                | 16             |       9.8 |      2.9               |        4.6 | 2.3e-05 |      21 |
 | Log::ger::Output::File      | 0.85                         | 4.2                | 16             |       9.7 |      2.8               |        4.6 | 2.3e-05 |      20 |
 | Log::ger                    | 0.91                         | 4.2                | 16             |       7.6 |      0.699999999999999 |        5.9 |   1e-05 |      20 |
 | Log::ger::Like::LogAny      | 0.84                         | 4.1                | 16             |       7.3 |      0.399999999999999 |        6.1 | 3.2e-05 |      20 |
 | perl -e1 (baseline)         | 0.82                         | 4.1                | 16             |       6.9 |      0                 |        6.6 | 1.8e-05 |      21 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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
