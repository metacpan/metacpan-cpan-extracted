package Bencher::Scenario::LogDispatchFileRotate::Writing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use File::Temp;

our $scenario = {
    summary => 'Benchmark writing using Log::Dispatch::FileRotate',
    precision => 6,
    participants => [
        {
            name => 'ldfr',
            module => 'Log::Dispatch::FileRotate',
            function => 'log',
            code_template => <<'_',
state $tempdir = File::Temp::tempdir(CLEANUP => 0);
warn "tempdir=$tempdir";
state $file = Log::Dispatch::FileRotate->new(name => 'file1', min_level => 'info', filename => "$tempdir/file1", mode => 'append', size => 10*1024*1024, max => 6);
$file->log(level => 'info', message => <str>) for 1..1000;
_
        },
    ],
    datasets => [
        {name => "1k x 100b", args => {str => ("a" x 99) . "\n"}},
    ],
};

1;
# ABSTRACT: Benchmark writing using Log::Dispatch::FileRotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogDispatchFileRotate::Writing - Benchmark writing using Log::Dispatch::FileRotate

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::LogDispatchFileRotate::Writing (from Perl distribution Bencher-Scenarios-LogDispatchFileRotate), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogDispatchFileRotate::Writing

To run module startup overhead benchmark:

 % bencher --module-startup -m LogDispatchFileRotate::Writing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Dispatch::FileRotate> 1.19

=head1 BENCHMARK PARTICIPANTS

=over

=item * ldfr (perl_code)

Code template:

 state $tempdir = File::Temp::tempdir(CLEANUP => 0);
 warn "tempdir=$tempdir";
 state $file = Log::Dispatch::FileRotate->new(name => 'file1', min_level => 'info', filename => "$tempdir/file1", mode => 'append', size => 10*1024*1024, max => 6);
 $file->log(level => 'info', message => <str>) for 1..1000;




=back

=head1 BENCHMARK DATASETS

=over

=item * 1k x 100b

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogDispatchFileRotate::Writing >>):

 #table1#
 +-------------+-----------+------+-----------+-----------+------------+---------+---------+
 | participant | dataset   | perl | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-------------+-----------+------+-----------+-----------+------------+---------+---------+
 | ldfr        | 1k x 100b | perl |        29 |        35 |          1 | 5.8e-05 |       6 |
 +-------------+-----------+------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogDispatchFileRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogDispatchFileRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogDispatchFileRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
