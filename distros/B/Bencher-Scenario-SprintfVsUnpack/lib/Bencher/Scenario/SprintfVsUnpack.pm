package Bencher::Scenario::SprintfVsUnpack;

our $DATE = '2017-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark sprintf() vs unpack()',
    participants => [
        {
            name => 'sprintf',
            code_template => 'state $data = <sprintf_data>; my $res; for (1..1000) { $res = sprintf(<sprintf_fmt>, $data) } $res',
        },
        {
            name => 'unpack',
            code_template => 'state $data = chr(<unpack_data>); my $res; for (1..1000) { $res = unpack(<unpack_fmt>, $data) } $res',
        },
    ],
    datasets => [
        {
            name => 'binary-byte',
            args => {
                sprintf_fmt  => '%08b',
                sprintf_data => 15,
                unpack_fmt   => 'B8',
                unpack_data  => 15,
            },
            result => '00001111',
        },
    ],
};

1;
# ABSTRACT: Benchmark sprintf() vs unpack()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::SprintfVsUnpack - Benchmark sprintf() vs unpack()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::SprintfVsUnpack (from Perl distribution Bencher-Scenario-SprintfVsUnpack), released on 2017-04-16.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m SprintfVsUnpack

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * sprintf (perl_code)

Code template:

 state $data = <sprintf_data>; my $res; for (1..1000) { $res = sprintf(<sprintf_fmt>, $data) } $res



=item * unpack (perl_code)

Code template:

 state $data = chr(<unpack_data>); my $res; for (1..1000) { $res = unpack(<unpack_fmt>, $data) } $res



=back

=head1 BENCHMARK DATASETS

=over

=item * binary-byte

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.5 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m SprintfVsUnpack >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | unpack      |      6770 |       148 |       1    | 4.7e-08 |      26 |
 | sprintf     |      9070 |       110 |       1.34 | 5.3e-08 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-SprintfVsUnpack>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-SprintfVsUnpack>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-SprintfVsUnpack>

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
