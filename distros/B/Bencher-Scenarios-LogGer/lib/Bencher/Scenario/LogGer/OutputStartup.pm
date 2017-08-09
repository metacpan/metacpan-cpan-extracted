package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2017-08-04'; # DATE
our $VERSION = '0.012'; # VERSION

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

This document describes version 0.012 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-08-04.

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

L<Log::ger::Output::Array> 0.023

L<Log::ger::Output::ArrayRotate> 0.001

L<Log::ger::Output::Callback> 0.002

L<Log::ger::Output::Composite> 0.007

L<Log::ger::Output::DirWriteRotate> 0.002

L<Log::ger::Output::File> 0.006

L<Log::ger::Output::FileWriteRotate> 0.002

L<Log::ger::Output::LogAny> 0.006

L<Log::ger::Output::Null> 0.023

L<Log::ger::Output::Screen> 0.007

L<Log::ger::Output::String> 0.023

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

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | participant               | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------------------+-----------+-----------+------------+-----------+---------+
 | init-with-FileWriteRotate |        18 |      57   |        1   |   0.00021 |      20 |
 | init-with-Syslog          |        26 |      38   |        1.5 | 8.2e-05   |      20 |
 | init-with-LogAny          |        42 |      24   |        2.4 | 5.3e-05   |      20 |
 | init-with-Composite       |        47 |      21   |        2.7 | 7.2e-05   |      20 |
 | init-with-DirWriteRotate  |        51 |      20   |        2.9 | 4.6e-05   |      20 |
 | init-with-ArrayRotate     |        65 |      15   |        3.7 | 7.4e-05   |      21 |
 | init-with-Screen          |        65 |      15   |        3.7 | 6.7e-05   |      20 |
 | init-with-File            |        65 |      15   |        3.7 | 3.8e-05   |      20 |
 | init-with-String          |        65 |      15   |        3.7 | 1.8e-05   |      20 |
 | init-with-Null            |        66 |      15   |        3.7 | 6.7e-05   |      20 |
 | init-with-Array           |        66 |      15   |        3.8 | 3.9e-05   |      20 |
 | init-with-Callback        |        67 |      15   |        3.8 | 2.5e-05   |      20 |
 | load-Screen               |        76 |      13   |        4.3 | 5.9e-05   |      20 |
 | load-Composite            |       100 |       9.8 |        5.8 | 4.7e-05   |      20 |
 | load-LogAny               |       110 |       9.2 |        6.1 | 7.4e-05   |      20 |
 | load-Callback             |       110 |       9.2 |        6.2 | 4.4e-05   |      20 |
 | load-String               |       110 |       9.1 |        6.2 | 5.8e-05   |      20 |
 | load-Array                |       110 |       9.1 |        6.2 | 5.4e-05   |      20 |
 | load-ArrayRotate          |       110 |       9.1 |        6.2 | 4.2e-05   |      20 |
 | load-Syslog               |       110 |       9.1 |        6.2 | 2.3e-05   |      20 |
 | load-FileWriteRotate      |       110 |       9.1 |        6.2 | 6.8e-05   |      21 |
 | load-File                 |       110 |       9   |        6.3 | 2.4e-05   |      20 |
 | load-DirWriteRotate       |       110 |       8.9 |        6.4 | 4.2e-05   |      20 |
 | load-Null                 |       150 |       6.5 |        8.7 | 3.6e-05   |      20 |
 | baseline                  |       170 |       6   |        9.4 | 4.4e-05   |      20 |
 +---------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-----------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                       | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Output::Screen          | 840                          | 4.2                | 20             |      13   |                    7   |        1   | 2.5e-05 |      20 |
 | Log::ger::Output::Composite       | 840                          | 4.2                | 20             |       9.9 |                    3.9 |        1.3 | 5.5e-05 |      20 |
 | Log::ger::Output::String          | 844                          | 4.2                | 20             |       9.3 |                    3.3 |        1.4 | 3.5e-05 |      20 |
 | Log::ger::Output::ArrayRotate     | 840                          | 4.2                | 20             |       9.3 |                    3.3 |        1.4 | 5.5e-05 |      20 |
 | Log::ger::Output::Syslog          | 844                          | 4.3                | 20             |       9.2 |                    3.2 |        1.4 | 5.1e-05 |      20 |
 | Log::ger::Output::Callback        | 844                          | 4.3                | 20             |       9.2 |                    3.2 |        1.4 | 5.7e-05 |      20 |
 | Log::ger::Output::File            | 840                          | 4.3                | 20             |       9.1 |                    3.1 |        1.4 | 3.2e-05 |      20 |
 | Log::ger::Output::FileWriteRotate | 936                          | 4.4                | 20             |       9.1 |                    3.1 |        1.4 | 6.1e-05 |      20 |
 | Log::ger::Output::Array           | 836                          | 4.3                | 20             |       9   |                    3   |        1.4 |   6e-05 |      21 |
 | Log::ger::Output::LogAny          | 932                          | 4.3                | 20             |       9   |                    3   |        1.4 |   4e-05 |      22 |
 | Log::ger::Output::DirWriteRotate  | 844                          | 4.2                | 20             |       8.9 |                    2.9 |        1.5 | 3.7e-05 |      22 |
 | Log::ger::Output::Null            | 840                          | 4                  | 20             |       6   |                    0   |        2   | 7.9e-05 |      21 |
 | perl -e1 (baseline)               | 572                          | 3.9                | 20             |       6   |                    0   |        2.2 | 5.5e-05 |      21 |
 +-----------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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
