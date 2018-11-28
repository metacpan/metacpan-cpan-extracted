package Bencher::Scenario::PerinciAccessLite::list;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark list action',
    participants => [
        {
            name => 'request',
            module => 'Perinci::Access::Lite',
            code_template => 'state $pa = Perinci::Access::Lite->new; $pa->request(list => "/Perinci/Examples/Tiny/")',
        },
        {
            name => 'new+request',
            module => 'Perinci::Access::Lite',
            code_template => 'Perinci::Access::Lite->new->request(list => "/Perinci/Examples/Tiny/")',
        },
    ],
};

1;
# ABSTRACT: Benchmark list action

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciAccessLite::list - Benchmark list action

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciAccessLite::list (from Perl distribution Bencher-Scenarios-PerinciAccessLite), released on 2018-11-22.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciAccessLite::list

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciAccessLite::list

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Access::Lite> 0.14

=head1 BENCHMARK PARTICIPANTS

=over

=item * request (perl_code)

Code template:

 state $pa = Perinci::Access::Lite->new; $pa->request(list => "/Perinci/Examples/Tiny/")



=item * new+request (perl_code)

Code template:

 Perinci::Access::Lite->new->request(list => "/Perinci/Examples/Tiny/")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m PerinciAccessLite::list >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | new+request |     70000 |        14 |        1   |   2e-08 |      20 |
 | request     |     77000 |        13 |        1.1 | 2.7e-08 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciAccessLite::list --module-startup >>):

 #table2#
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | participant           | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Access::Lite |        10 |                      5 |          1 | 0.00024 |      20 |
 | perl -e1 (baseline)   |         5 |                      0 |          3 | 0.00012 |      20 |
 +-----------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciAccessLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciAccessLite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciAccessLite>

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
