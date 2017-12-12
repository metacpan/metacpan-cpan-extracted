package Bencher::Scenario::MathBigFloat::Multiply;

our $DATE = '2017-12-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark multiplying 2 32 times (2^32)',
    participants => [
        {
            module => 'Math::BigFloat',
            code_template => 'my $n = Math::BigFloat->new("1"); my $m = Math::BigFloat->new("2"); for (1..32) { $n->bmul($m) } $n->bstr',
        },
        {
            name => 'native',
            code_template => 'my $n = 1; for (1..32) { $n *= 2 } $n',
        },
    ],
};

1;
# ABSTRACT: Benchmark multiplying 2 32 times (2^32)

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::MathBigFloat::Multiply - Benchmark multiplying 2 32 times (2^32)

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::MathBigFloat::Multiply (from Perl distribution Bencher-Scenarios-MathBigFloat), released on 2017-12-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m MathBigFloat::Multiply

To run module startup overhead benchmark:

 % bencher --module-startup -m MathBigFloat::Multiply

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Math::BigFloat> 1.999808

=head1 BENCHMARK PARTICIPANTS

=over

=item * Math::BigFloat (perl_code)

Code template:

 my $n = Math::BigFloat->new("1"); my $m = Math::BigFloat->new("2"); for (1..32) { $n->bmul($m) } $n->bstr



=item * native (perl_code)

Code template:

 my $n = 1; for (1..32) { $n *= 2 } $n



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m MathBigFloat::Multiply >>):

 #table1#
 +----------------+-----------+-----------+------------+---------+---------+
 | participant    | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------+-----------+-----------+------------+---------+---------+
 | Math::BigFloat |      1700 |     600   |          1 | 2.5e-06 |      20 |
 | native         |    430000 |       2.4 |        260 | 3.3e-09 |      20 |
 +----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m MathBigFloat::Multiply --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Math::BigFloat      | 0.83                         | 4.2                | 16             |      75   |                   66.3 |        1   |   0.00046 |      20 |
 | perl -e1 (baseline) | 6.3                          | 10                 | 22             |       8.7 |                    0   |        8.6 | 6.1e-05   |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-MathBigFloat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-MathBigFloat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-MathBigFloat>

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
