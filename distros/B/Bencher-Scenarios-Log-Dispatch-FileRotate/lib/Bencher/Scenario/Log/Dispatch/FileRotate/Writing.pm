package Bencher::Scenario::Log::Dispatch::FileRotate::Writing;

use strict;
use warnings;

use File::Temp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-Dispatch-FileRotate'; # DIST
our $VERSION = '0.003'; # VERSION

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

Bencher::Scenario::Log::Dispatch::FileRotate::Writing - Benchmark writing using Log::Dispatch::FileRotate

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Log::Dispatch::FileRotate::Writing (from Perl distribution Bencher-Scenarios-Log-Dispatch-FileRotate), released on 2023-10-29.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::Dispatch::FileRotate::Writing

To run module startup overhead benchmark:

 % bencher --module-startup -m Log::Dispatch::FileRotate::Writing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Dispatch::FileRotate> 1.38

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

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::Dispatch::FileRotate::Writing

Result formatted as table:

 #table1#
 +-------------+-----------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | dataset   | ds_tags | p_tags | perl | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ldfr        | 1k x 100b |         |        | perl |      31.8 |      31.5 |                 0.00% |                 0.00% | 5.3e-06 |       6 |
 +-------------+-----------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

      Rate     
    31.8/s  -- 
 
 Legends:
   : dataset=1k x 100b ds_tags= p_tags= participant=ldfr perl=perl

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-Dispatch-FileRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-Dispatch-FileRotate>.

=head1 SEE ALSO

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

This software is copyright (c) 2023, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-Dispatch-FileRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
