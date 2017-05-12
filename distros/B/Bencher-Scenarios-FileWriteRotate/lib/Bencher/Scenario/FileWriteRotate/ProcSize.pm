package Bencher::Scenario::FileWriteRotate::ProcSize;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use File::Temp;

our $scenario = {
    participants => [
        {
            module => 'File::Write::Rotate',
            code_template => '1',
        },
        {
            module => 'Log::Dispatch::FileRotate',
            code_template => '1',
        },
    ],
    with_process_size => 1,
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::FileWriteRotate::ProcSize

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::FileWriteRotate::ProcSize (from Perl distribution Bencher-Scenarios-FileWriteRotate), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m FileWriteRotate::ProcSize

To run module startup overhead benchmark:

 % bencher --module-startup -m FileWriteRotate::ProcSize

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<File::Write::Rotate> 0.31

L<Log::Dispatch::FileRotate> 1.19

=head1 BENCHMARK PARTICIPANTS

=over

=item * File::Write::Rotate (perl_code)

Code template:

 1



=item * Log::Dispatch::FileRotate (perl_code)

Code template:

 1



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m FileWriteRotate::ProcSize >>):

 #table1#
 +---------------------------+------------------------------+--------------------+----------------+-----------+-----------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+-----------+------------+---------+---------+
 | Log::Dispatch::FileRotate | 13                           | 17                 | 47             | 110000000 |       9.5 |          1 | 2.5e-11 |      27 |
 | File::Write::Rotate       | 5                            | 8                  | 40             | 200000000 |       6   |          1 | 8.8e-11 |      38 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-FileWriteRotate>

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
