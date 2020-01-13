package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2020-01-13'; # DATE
our $VERSION = '0.016'; # VERSION

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

This document describes version 0.016 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2020-01-13.

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

L<Log::ger::Output::Composite> 0.010

L<Log::ger::Output::DirWriteRotate> 0.002

L<Log::ger::Output::File> 0.009

L<Log::ger::Output::FileWriteRotate> 0.003

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

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant               | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | init-with-FileWriteRotate |      25.1 |     39.9  |                 0.00% |               479.44% | 2.5e-05 |      20 |
 | init-with-Syslog          |      33.9 |     29.5  |                35.43% |               327.87% | 2.1e-05 |      21 |
 | init-with-Composite       |      41.5 |     24.1  |                65.64% |               249.81% | 8.1e-06 |      20 |
 | init-with-File            |      47.7 |     21    |                90.40% |               204.33% | 1.2e-05 |      21 |
 | init-with-LogAny          |      54.1 |     18.5  |               115.93% |               168.35% | 1.4e-05 |      21 |
 | load-File                 |      57.4 |     17.4  |               128.97% |               153.06% | 7.9e-06 |      22 |
 | init-with-DirWriteRotate  |      64   |     16    |               154.96% |               127.27% | 4.3e-05 |      20 |
 | init-with-Screen          |      74   |     13.5  |               195.32% |                96.21% |   5e-06 |      20 |
 | init-with-String          |      74.9 |     13.4  |               198.94% |                93.83% | 6.7e-06 |      20 |
 | init-with-Array           |      75   |     13    |               199.19% |                93.67% | 1.4e-05 |      20 |
 | init-with-ArrayRotate     |      75.3 |     13.3  |               200.45% |                92.86% | 6.1e-06 |      20 |
 | init-with-Callback        |      75.5 |     13.2  |               201.40% |                92.25% | 6.6e-06 |      20 |
 | init-with-Null            |      75.7 |     13.2  |               201.99% |                91.87% | 9.4e-06 |      20 |
 | load-Composite            |      80.5 |     12.4  |               221.14% |                80.43% | 3.5e-06 |      20 |
 | load-Screen               |      84.5 |     11.8  |               237.47% |                71.70% | 3.8e-06 |      20 |
 | load-Syslog               |     111   |      8.97 |               344.88% |                30.25% | 3.6e-06 |      20 |
 | load-String               |     112   |      8.93 |               347.16% |                29.58% | 4.4e-06 |      21 |
 | load-Callback             |     112   |      8.93 |               347.19% |                29.57% | 5.4e-06 |      20 |
 | load-LogAny               |     112   |      8.91 |               347.81% |                29.40% | 5.5e-06 |      21 |
 | load-DirWriteRotate       |     112   |      8.9  |               348.32% |                29.25% | 3.8e-06 |      20 |
 | load-FileWriteRotate      |     112   |      8.9  |               348.42% |                29.22% | 4.1e-06 |      20 |
 | load-ArrayRotate          |     112   |      8.9  |               348.56% |                29.18% | 2.9e-06 |      20 |
 | load-Array                |     112   |      8.89 |               349.03% |                29.04% | 6.1e-06 |      20 |
 | load-Null                 |     143   |      6.98 |               472.19% |                 1.27% |   5e-06 |      20 |
 | baseline                  |     150   |      6.9  |               479.44% |                 0.00% | 1.2e-05 |      20 |
 +---------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Log::ger::Output::File            |     17.5  |             10.67 |                 0.00% |               156.04% | 1.6e-05 |      20 |
 | Log::ger::Output::Composite       |     12.5  |              5.67 |                40.14% |                82.70% | 6.7e-06 |      20 |
 | Log::ger::Output::Screen          |     11.8  |              4.97 |                47.72% |                73.33% | 8.1e-06 |      20 |
 | Log::ger::Output::Syslog          |      9.04 |              2.21 |                93.34% |                32.43% | 3.4e-06 |      20 |
 | Log::ger::Output::String          |      8.97 |              2.14 |                94.84% |                31.41% | 6.7e-06 |      20 |
 | Log::ger::Output::Callback        |      8.95 |              2.12 |                95.25% |                31.13% |   6e-06 |      20 |
 | Log::ger::Output::ArrayRotate     |      8.93 |              2.1  |                95.64% |                30.88% | 5.6e-06 |      20 |
 | Log::ger::Output::LogAny          |      8.93 |              2.1  |                95.78% |                30.78% | 4.4e-06 |      20 |
 | Log::ger::Output::FileWriteRotate |      8.92 |              2.09 |                95.92% |                30.68% | 5.8e-06 |      20 |
 | Log::ger::Output::Array           |      8.9  |              2.07 |                96.47% |                30.32% | 4.1e-06 |      20 |
 | Log::ger::Output::DirWriteRotate  |      8.89 |              2.06 |                96.58% |                30.25% | 4.1e-06 |      20 |
 | Log::ger::Output::Null            |      7.11 |              0.28 |               145.99% |                 4.08% | 5.2e-06 |      20 |
 | perl -e1 (baseline)               |      6.83 |              0    |               156.04% |                 0.00% | 2.7e-06 |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


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

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
