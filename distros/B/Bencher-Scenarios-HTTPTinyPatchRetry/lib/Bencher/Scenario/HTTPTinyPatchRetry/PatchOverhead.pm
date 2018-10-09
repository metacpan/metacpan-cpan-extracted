package Bencher::Scenario::HTTPTinyPatchRetry::PatchOverhead;

our $DATE = '2018-10-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark patching overhead',
    participants => [
        {
            name => 'import+unimport',
            module => 'HTTP::Tiny::Patch::Retry',
            code_template => 'HTTP::Tiny::Patch::Retry->import; HTTP::Tiny::Patch::Retry->unimport',
        },
    ],
};

1;
# ABSTRACT: Benchmark patching overhead

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HTTPTinyPatchRetry::PatchOverhead - Benchmark patching overhead

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::HTTPTinyPatchRetry::PatchOverhead (from Perl distribution Bencher-Scenarios-HTTPTinyPatchRetry), released on 2018-10-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HTTPTinyPatchRetry::PatchOverhead

To run module startup overhead benchmark:

 % bencher --module-startup -m HTTPTinyPatchRetry::PatchOverhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<HTTP::Tiny::Patch::Retry> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * import+unimport (perl_code)

Code template:

 HTTP::Tiny::Patch::Retry->import; HTTP::Tiny::Patch::Retry->unimport



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m HTTPTinyPatchRetry::PatchOverhead >>):

 #table1#
 +-----------------+---------+--------+------+-----------+-----------+------------+---------+---------+
 | participant     | ds_tags | p_tags | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------+---------+--------+------+-----------+-----------+------------+---------+---------+
 | import+unimport |         |        | perl |      4500 |       220 |          1 | 4.2e-07 |      21 |
 +-----------------+---------+--------+------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m HTTPTinyPatchRetry::PatchOverhead --module-startup >>):

 #table2#
 +--------------------------+-----------+------------------------+------------+---------+---------+
 | participant              | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------+-----------+------------------------+------------+---------+---------+
 | HTTP::Tiny::Patch::Retry |      38   |                   33.3 |        1   | 7.8e-05 |      20 |
 | perl -e1 (baseline)      |       4.7 |                    0   |        8.2 |   1e-05 |      20 |
 +--------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HTTPTinyPatchRetry>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-HTTPTinyPatchRetry>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HTTPTinyPatchRetry>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
