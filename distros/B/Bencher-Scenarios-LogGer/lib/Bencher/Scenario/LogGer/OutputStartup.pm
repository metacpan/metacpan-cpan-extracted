package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2019-09-18'; # DATE
our $VERSION = '0.015'; # VERSION

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

This document describes version 0.015 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2019-09-18.

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

L<Log::ger::Output::Array> 0.028

L<Log::ger::Output::ArrayRotate> 0.001

L<Log::ger::Output::Callback> 0.004

L<Log::ger::Output::Composite> 0.009

L<Log::ger::Output::DirWriteRotate> 0.002

L<Log::ger::Output::File> 0.007

L<Log::ger::Output::FileWriteRotate> 0.002

L<Log::ger::Output::LogAny> 0.006

L<Log::ger::Output::Null> 0.028

L<Log::ger::Output::Screen> 0.008

L<Log::ger::Output::String> 0.028

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | participant               | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | init-with-Syslog          |      10.6 |     94.4  |       1    | 7.3e-05   |      20 |
 | init-with-ArrayRotate     |      24.7 |     40.4  |       2.34 | 2.1e-05   |      20 |
 | init-with-Callback        |      24.7 |     40.4  |       2.34 | 3.7e-05   |      20 |
 | init-with-FileWriteRotate |      25   |     40    |       2.3  | 7.9e-05   |      23 |
 | load-Composite            |      28.2 |     35.4  |       2.66 | 1.6e-05   |      20 |
 | init-with-String          |      33   |     30    |       3.1  |   0.00022 |      30 |
 | load-Syslog               |      43   |     23    |       4.1  | 2.7e-05   |      20 |
 | load-Callback             |      44   |     22.7  |       4.15 | 2.2e-05   |      20 |
 | load-ArrayRotate          |      44   |     22.7  |       4.16 | 1.6e-05   |      20 |
 | init-with-LogAny          |      54   |     18    |       5.1  | 2.7e-05   |      20 |
 | init-with-Composite       |      60   |     17    |       5.6  | 2.9e-05   |      20 |
 | init-with-DirWriteRotate  |      65   |     15    |       6.1  | 2.6e-05   |      20 |
 | init-with-Screen          |      74   |     13.5  |       6.99 | 3.8e-06   |      20 |
 | init-with-File            |      74   |     14    |       7    | 2.5e-05   |      20 |
 | init-with-Array           |      75.1 |     13.3  |       7.09 | 8.3e-06   |      20 |
 | init-with-Null            |      76   |     13    |       7.2  | 1.6e-05   |      20 |
 | load-Screen               |      89   |     11    |       8.4  | 1.5e-05   |      21 |
 | load-File                 |     120   |      8.5  |      11    | 1.3e-05   |      20 |
 | load-LogAny               |     120   |      8.4  |      11    | 3.4e-05   |      20 |
 | load-String               |     120   |      8.4  |      11    | 1.8e-05   |      20 |
 | load-FileWriteRotate      |     120   |      8.3  |      11    | 1.5e-05   |      20 |
 | load-Array                |     120   |      8.3  |      11    | 1.6e-05   |      20 |
 | load-DirWriteRotate       |     121   |      8.27 |      11.4  | 7.8e-06   |      20 |
 | load-Null                 |     160   |      6.4  |      15    | 2.1e-05   |      20 |
 | baseline                  |     160   |      6.2  |      15    | 1.3e-05   |      20 |
 +---------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-----------------------------------+-----------+------------------------+------------+-----------+---------+
 | participant                       | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------------+-----------+------------------------+------------+-----------+---------+
 | Log::ger::Output::Composite       |      13   |                    6.8 |        1   |   0.00012 |      21 |
 | Log::ger::Output::Screen          |      11   |                    4.8 |        1.1 | 2.2e-05   |      21 |
 | Log::ger::Output::File            |       8.5 |                    2.3 |        1.5 | 1.5e-05   |      20 |
 | Log::ger::Output::DirWriteRotate  |       8.4 |                    2.2 |        1.5 | 1.2e-05   |      20 |
 | Log::ger::Output::Syslog          |       8.4 |                    2.2 |        1.5 | 1.4e-05   |      20 |
 | Log::ger::Output::LogAny          |       8.3 |                    2.1 |        1.5 | 2.4e-05   |      21 |
 | Log::ger::Output::ArrayRotate     |       8.3 |                    2.1 |        1.5 | 1.6e-05   |      20 |
 | Log::ger::Output::FileWriteRotate |       8.3 |                    2.1 |        1.5 | 2.1e-05   |      20 |
 | Log::ger::Output::Callback        |       8.3 |                    2.1 |        1.5 | 1.3e-05   |      20 |
 | Log::ger::Output::Array           |       8.3 |                    2.1 |        1.5 | 1.3e-05   |      20 |
 | Log::ger::Output::String          |       8.3 |                    2.1 |        1.5 | 1.1e-05   |      20 |
 | Log::ger::Output::Null            |       6.5 |                    0.3 |        2   | 1.4e-05   |      20 |
 | perl -e1 (baseline)               |       6.2 |                    0   |        2.1 | 1.2e-05   |      20 |
 +-----------------------------------+-----------+------------------------+------------+-----------+---------+


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

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
