package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2018-12-20'; # DATE
our $VERSION = '0.014'; # VERSION

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
        'Log::ger::Output::Composite' => {version=>'0.005'},
        'Log::ger::Output::File' => {version=>'0.002'},
        'Log::ger::Output::LogAny' => {version=>'0.003'},
        'Log::ger::Output::Screen' => {version=>'0.007'},
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

This document describes version 0.014 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2018-12-20.

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

L<Log::ger::Output::Array> 0.025

L<Log::ger::Output::ArrayRotate> 0.001

L<Log::ger::Output::Callback> 0.004

L<Log::ger::Output::Composite> 0.007

L<Log::ger::Output::DirWriteRotate> 0.002

L<Log::ger::Output::File> 0.006

L<Log::ger::Output::FileWriteRotate> 0.002

L<Log::ger::Output::LogAny> 0.006

L<Log::ger::Output::Null> 0.025

L<Log::ger::Output::Screen> 0.007

L<Log::ger::Output::String> 0.025

L<Log::ger::Output::Syslog> 0.001

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

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | participant               | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | init-with-FileWriteRotate |        21 |      47   |        1   |   0.00012 |      20 |
 | init-with-Syslog          |        31 |      33   |        1.4 | 7.6e-05   |      21 |
 | init-with-LogAny          |        49 |      20   |        2.3 |   0.00016 |      21 |
 | init-with-Composite       |        55 |      18   |        2.6 | 5.3e-05   |      21 |
 | init-with-DirWriteRotate  |        59 |      17   |        2.8 | 3.6e-05   |      21 |
 | init-with-Screen          |        74 |      13   |        3.5 | 3.2e-05   |      20 |
 | init-with-File            |        75 |      13   |        3.5 | 4.7e-05   |      20 |
 | init-with-String          |        75 |      13   |        3.5 | 3.3e-05   |      22 |
 | init-with-ArrayRotate     |        75 |      13   |        3.5 | 4.2e-05   |      20 |
 | init-with-Array           |        76 |      13   |        3.5 | 2.2e-05   |      20 |
 | init-with-Callback        |        77 |      13   |        3.6 | 3.4e-05   |      20 |
 | init-with-Null            |        78 |      13   |        3.6 | 1.4e-05   |      20 |
 | load-Screen               |        84 |      12   |        3.9 | 4.7e-05   |      20 |
 | load-Composite            |       110 |       9.2 |        5.1 | 3.2e-05   |      20 |
 | load-Syslog               |       120 |       8.4 |        5.6 | 2.5e-05   |      20 |
 | load-File                 |       120 |       8.3 |        5.6 | 2.3e-05   |      20 |
 | load-Callback             |       120 |       8.3 |        5.6 | 4.1e-05   |      20 |
 | load-FileWriteRotate      |       120 |       8.2 |        5.7 | 5.3e-05   |      20 |
 | load-String               |       120 |       8.2 |        5.7 |   2e-05   |      20 |
 | load-Array                |       120 |       8.2 |        5.7 | 4.8e-05   |      20 |
 | load-DirWriteRotate       |       120 |       8.2 |        5.7 | 2.6e-05   |      20 |
 | load-ArrayRotate          |       120 |       8.1 |        5.7 |   3e-05   |      20 |
 | load-LogAny               |       120 |       8.1 |        5.8 | 2.3e-05   |      20 |
 | load-Null                 |       170 |       5.8 |        8   | 4.1e-05   |      20 |
 | baseline                  |       180 |       5.5 |        8.4 | 3.3e-05   |      20 |
 +---------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-----------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                       | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Output::Screen          |      12   |                    6.5 |        1   | 2.8e-05 |      20 |
 | Log::ger::Output::Composite       |       9.5 |                    4   |        1.3 | 3.2e-05 |      21 |
 | Log::ger::Output::File            |       8.8 |                    3.3 |        1.4 | 4.5e-05 |      20 |
 | Log::ger::Output::DirWriteRotate  |       8.6 |                    3.1 |        1.4 | 5.1e-05 |      20 |
 | Log::ger::Output::FileWriteRotate |       8.4 |                    2.9 |        1.4 | 4.1e-05 |      20 |
 | Log::ger::Output::Callback        |       8.4 |                    2.9 |        1.4 | 6.7e-05 |      21 |
 | Log::ger::Output::LogAny          |       8.3 |                    2.8 |        1.4 | 3.9e-05 |      20 |
 | Log::ger::Output::ArrayRotate     |       8.2 |                    2.7 |        1.4 | 3.1e-05 |      21 |
 | Log::ger::Output::Syslog          |       8.2 |                    2.7 |        1.5 | 2.1e-05 |      20 |
 | Log::ger::Output::Array           |       8.2 |                    2.7 |        1.5 | 3.2e-05 |      20 |
 | Log::ger::Output::String          |       8.1 |                    2.6 |        1.5 | 2.3e-05 |      20 |
 | Log::ger::Output::Null            |       5.9 |                    0.4 |        2   | 5.5e-05 |      21 |
 | perl -e1 (baseline)               |       5.5 |                    0   |        2.2 | 4.1e-05 |      20 |
 +-----------------------------------+-----------+------------------------+------------+---------+---------+


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

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
