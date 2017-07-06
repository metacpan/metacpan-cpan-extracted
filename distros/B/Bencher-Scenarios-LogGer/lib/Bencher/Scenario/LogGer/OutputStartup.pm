package Bencher::Scenario::LogGer::OutputStartup;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.009'; # VERSION

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

    ArrayWithLimits => { array => $ary },
    File => { path => $fname },
    Screen => {},
    Callback => {},
    FileWriteRotate => { dir => $dname, prefix => 'prefix' },
    DirWriteRotate => { path => $dname },
    LogAny => {},
    LogDispatchOutput => { output => 'ArrayWithLimits', args => {array => $ary} },
    Composite => { outputs => {Screen => {conf=>{}}, File => {conf=>{path=>$fname}}} },
);

our $scenario = {
    modules => {
        'Log::ger::Output::Composite' => {version=>'0.005'},
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

This document describes version 0.009 of Bencher::Scenario::LogGer::OutputStartup (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-02.

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

L<Log::ger::Output::Array> 0.012

L<Log::ger::Output::ArrayWithLimits> 0.001

L<Log::ger::Output::Callback> 0.001

L<Log::ger::Output::Composite> 0.007

L<Log::ger::Output::DirWriteRotate> 0.002

L<Log::ger::Output::File> 0.002

L<Log::ger::Output::FileWriteRotate> 0.001

L<Log::ger::Output::LogAny> 0.006

L<Log::ger::Output::LogDispatchOutput> 0.001

L<Log::ger::Output::Null> 0.012

L<Log::ger::Output::Screen> 0.005

L<Log::ger::Output::String> 0.012

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline (command)



=item * load-Array (command)

L<Log::ger::Output::Array>



=item * init-with-Array (command)

L<Log::ger::Output::Array>



=item * load-ArrayWithLimits (command)

L<Log::ger::Output::ArrayWithLimits>



=item * init-with-ArrayWithLimits (command)

L<Log::ger::Output::ArrayWithLimits>



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



=item * load-LogDispatchOutput (command)

L<Log::ger::Output::LogDispatchOutput>



=item * init-with-LogDispatchOutput (command)

L<Log::ger::Output::LogDispatchOutput>



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



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogGer::OutputStartup >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+-----------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+-----------+-----------+------------+-----------+---------+
 | init-with-FileWriteRotate   |      20.4 |      49   |        1   | 4.3e-05   |      20 |
 | init-with-LogDispatchOutput |      35   |      29   |        1.7 | 4.6e-05   |      20 |
 | init-with-LogAny            |      53   |      19   |        2.6 |   5e-05   |      21 |
 | init-with-Composite         |      56   |      18   |        2.7 |   0.00011 |      20 |
 | init-with-DirWriteRotate    |      60   |      17   |        2.9 | 7.8e-05   |      21 |
 | init-with-Screen            |      78   |      13   |        3.8 | 5.1e-05   |      20 |
 | init-with-File              |      78   |      13   |        3.8 | 4.3e-05   |      20 |
 | init-with-Null              |      79   |      13   |        3.9 | 5.7e-05   |      21 |
 | init-with-Array             |      79   |      13   |        3.9 | 3.6e-05   |      20 |
 | init-with-String            |      79   |      13   |        3.9 | 4.2e-05   |      20 |
 | init-with-Callback          |      80   |      12   |        3.9 | 4.1e-05   |      20 |
 | init-with-ArrayWithLimits   |      80   |      12   |        3.9 | 3.7e-05   |      20 |
 | load-Screen                 |      90   |      11   |        4.4 | 1.5e-05   |      20 |
 | load-LogDispatchOutput      |      91   |      11   |        4.5 | 2.7e-05   |      20 |
 | load-Composite              |     120   |       8.5 |        5.7 | 2.8e-05   |      20 |
 | load-LogAny                 |     130   |       7.8 |        6.3 | 3.6e-05   |      20 |
 | load-File                   |     130   |       7.8 |        6.3 | 2.2e-05   |      20 |
 | load-FileWriteRotate        |     130   |       7.7 |        6.3 | 1.6e-05   |      20 |
 | load-String                 |     130   |       7.7 |        6.4 | 1.6e-05   |      21 |
 | load-Array                  |     130   |       7.7 |        6.4 | 3.7e-05   |      20 |
 | load-ArrayWithLimits        |     130   |       7.6 |        6.4 | 9.9e-06   |      20 |
 | load-Callback               |     130   |       7.6 |        6.4 | 2.5e-05   |      21 |
 | load-DirWriteRotate         |     130   |       7.5 |        6.5 | 2.3e-05   |      20 |
 | load-Null                   |     190   |       5.4 |        9.1 | 2.1e-05   |      20 |
 | baseline                    |     200   |       5   |        9.7 | 7.4e-06   |      20 |
 +-----------------------------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m LogGer::OutputStartup --module-startup >>):

 #table2#
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Log::ger::Output::Screen            | 864                          | 4.2                | 16             |      11   |                    6   |        1   | 1.7e-05 |      26 |
 | Log::ger::Output::LogDispatchOutput | 856                          | 4.1                | 16             |      11   |                    6   |        1   | 2.3e-05 |      20 |
 | Log::ger::Output::Composite         | 856                          | 4.2                | 16             |       8.6 |                    3.6 |        1.3 | 3.2e-05 |      20 |
 | Log::ger::Output::String            | 864                          | 4.2                | 16             |       7.8 |                    2.8 |        1.4 | 3.1e-05 |      20 |
 | Log::ger::Output::File              | 864                          | 4.1                | 16             |       7.8 |                    2.8 |        1.4 | 3.3e-05 |      20 |
 | Log::ger::Output::Callback          | 860                          | 4.1                | 16             |       7.7 |                    2.7 |        1.4 | 3.2e-05 |      20 |
 | Log::ger::Output::ArrayWithLimits   | 860                          | 4.1                | 16             |       7.7 |                    2.7 |        1.4 | 2.8e-05 |      21 |
 | Log::ger::Output::DirWriteRotate    | 864                          | 4.1                | 16             |       7.7 |                    2.7 |        1.4 | 2.4e-05 |      20 |
 | Log::ger::Output::LogAny            | 1000                         | 4.3                | 16             |       7.7 |                    2.7 |        1.4 | 2.1e-05 |      20 |
 | Log::ger::Output::FileWriteRotate   | 1000                         | 4.3                | 16             |       7.7 |                    2.7 |        1.4 | 2.9e-05 |      20 |
 | Log::ger::Output::Array             | 860                          | 4.1                | 16             |       7.6 |                    2.6 |        1.4 | 2.1e-05 |      20 |
 | Log::ger::Output::Null              | 856                          | 4.1                | 16             |       5.3 |                    0.3 |        2.1 | 6.7e-06 |      20 |
 | perl -e1 (baseline)                 | 844                          | 4.1                | 16             |       5   |                    0   |        2.2 | 6.5e-06 |      20 |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


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
