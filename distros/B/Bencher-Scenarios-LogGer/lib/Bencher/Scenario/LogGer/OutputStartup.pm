package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.018'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use File::Temp qw(tempdir tempfile);

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
        'Log::ger::Output::Composite' => {version=>'0.009'},
        'Log::ger::Output::File' => {version=>'0.002'},
        'Log::ger::Output::LogAny' => {version=>'0.003'},
        'Log::ger::Output::Screen' => {version=>'0.015'},
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

Bencher::Scenario::LogGer::OutputStartup

=head1 VERSION

This document describes version 0.018 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2021-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::OutputStartup

To run module startup overhead benchmark:

 % bencher --module-startup -m LogGer::OutputStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::ger::Output::Array> 0.038

L<Log::ger::Output::ArrayRotate> 0.004

L<Log::ger::Output::Callback> 0.009

L<Log::ger::Output::Composite> 0.017

L<Log::ger::Output::DirWriteRotate> 0.004

L<Log::ger::Output::File> 0.012

L<Log::ger::Output::FileWriteRotate> 0.005

L<Log::ger::Output::LogAny> 0.009

L<Log::ger::Output::Null> 0.038

L<Log::ger::Output::Screen> 0.017

L<Log::ger::Output::String> 0.038

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant               | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | init-with-FileWriteRotate |      24.5 |      40.8 |                 0.00% |               419.66% | 3.2e-05   |      20 |
 | init-with-Syslog          |      30   |      30   |                22.84% |               323.05% |   0.00039 |      20 |
 | init-with-Composite       |      37   |      27   |                49.99% |               246.46% |   0.00017 |      20 |
 | init-with-LogAny          |      50   |      20   |                85.65% |               179.91% |   0.00052 |      21 |
 | init-with-File            |      46   |      22   |                88.04% |               176.35% | 3.9e-05   |      20 |
 | load-File                 |      55   |      18   |               126.03% |               129.90% | 2.7e-05   |      20 |
 | init-with-String          |      60   |      20   |               139.06% |               117.38% |   0.00031 |      20 |
 | init-with-DirWriteRotate  |      59   |      17   |               142.60% |               114.20% | 4.5e-05   |      20 |
 | load-Syslog               |      70   |      20   |               167.55% |                94.22% |   0.00021 |      21 |
 | init-with-ArrayRotate     |      70   |      20   |               169.45% |                92.86% |   0.0002  |      20 |
 | init-with-Callback        |      70   |      14   |               185.99% |                81.70% | 2.9e-05   |      21 |
 | init-with-Screen          |      71   |      14   |               187.77% |                80.58% | 2.4e-05   |      21 |
 | init-with-Array           |      71   |      14   |               189.04% |                79.79% | 4.7e-05   |      20 |
 | init-with-Null            |      73.1 |      13.7 |               198.08% |                74.34% | 1.2e-05   |      20 |
 | load-Composite            |      76   |      13   |               208.29% |                68.56% | 4.5e-05   |      20 |
 | load-Screen               |      77   |      13   |               214.36% |                65.31% | 6.7e-05   |      20 |
 | load-ArrayRotate          |      80   |      10   |               235.24% |                55.01% |   0.00022 |      20 |
 | load-DirWriteRotate       |      98   |      10   |               298.64% |                30.36% | 9.5e-05   |      23 |
 | load-Array                |     100   |       9.7 |               320.40% |                23.61% | 2.9e-05   |      20 |
 | load-FileWriteRotate      |     100   |       9.6 |               323.18% |                22.80% | 2.6e-05   |      20 |
 | load-String               |     100   |       9.6 |               325.47% |                22.14% | 1.4e-05   |      20 |
 | load-Callback             |     100   |       9.6 |               325.63% |                22.09% | 2.5e-05   |      20 |
 | load-LogAny               |     100   |       9.6 |               325.84% |                22.03% | 3.6e-05   |      20 |
 | load-Null                 |     120   |       8.1 |               401.85% |                 3.55% | 1.1e-05   |      20 |
 | baseline                  |     130   |       7.8 |               419.66% |                 0.00% |   4e-05   |      22 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | Log::ger::Output::File            |      20   |              12   |                 0.00% |               157.86% |   0.00028 |      22 |
 | Log::ger::Output::Composite       |      13   |               5   |                57.70% |                63.51% |   2e-05   |      20 |
 | Log::ger::Output::Screen          |      12   |               4   |                67.62% |                53.84% | 2.1e-05   |      20 |
 | Log::ger::Output::Syslog          |      12.2 |               4.2 |                70.24% |                51.47% | 1.1e-05   |      20 |
 | Log::ger::Output::LogAny          |      10   |               2   |                98.10% |                30.17% | 7.6e-05   |      20 |
 | Log::ger::Output::FileWriteRotate |      10   |               2   |               106.36% |                24.96% | 6.4e-05   |      20 |
 | Log::ger::Output::DirWriteRotate  |       9.8 |               1.8 |               111.55% |                21.89% | 1.8e-05   |      23 |
 | Log::ger::Output::Array           |       9.8 |               1.8 |               111.64% |                21.84% | 1.3e-05   |      20 |
 | Log::ger::Output::Callback        |       9.8 |               1.8 |               111.73% |                21.79% | 1.2e-05   |      21 |
 | Log::ger::Output::String          |       9.7 |               1.7 |               113.89% |                20.56% | 3.2e-05   |      20 |
 | Log::ger::Output::ArrayRotate     |       9.7 |               1.7 |               114.16% |                20.41% | 2.8e-05   |      20 |
 | Log::ger::Output::Null            |       8.5 |               0.5 |               144.87% |                 5.31% | 4.8e-05   |      20 |
 | perl -e1 (baseline)               |       8   |               0   |               157.86% |                 0.00% | 8.1e-06   |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
