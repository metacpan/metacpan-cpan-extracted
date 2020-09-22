package Bencher::Scenario::Z::Overhead;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-21'; # DATE
our $DIST = 'Bencher-Scenarios-Z'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Measure startup overhead of Z',
    code_startup => 1,
    participants => [
        {code_template=>'use Z;'},
        {code_template=>'use Z -modern;'},
        {code_template=>'use Z -compat;'},
        {code_template=>'use Z -detect;'},
    ],
};

1;
# ABSTRACT: Measure startup overhead of Z

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Z::Overhead - Measure startup overhead of Z

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Z::Overhead (from Perl distribution Bencher-Scenarios-Z), released on 2020-09-21.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Z::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * use Z; (perl_code)

Code template:

 use Z;



=item * use Z -modern; (perl_code)

Code template:

 use Z -modern;



=item * use Z -compat; (perl_code)

Code template:

 use Z -compat;



=item * use Z -detect; (perl_code)

Code template:

 use Z -detect;



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 4.15.0-91-generic >>.

Benchmark with C<< bencher -m Z::Overhead --include-path archive/Z-0.001/lib --include-path archive/Z-0.005/lib --multimodver Z >>:

 #table1#
 +---------------------+--------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | participant         | modver | time (ms) | code_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------+--------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+
 | use Z;              | 0.005  |        84 |                 82 |                 0.00% |              4420.17% |   0.00026 |      20 |
 | use Z -modern;      | 0.005  |        84 |                 82 |                 0.41% |              4401.81% |   0.0001  |      20 |
 | use Z -detect;      | 0.005  |        84 |                 82 |                 0.43% |              4401.03% |   0.00014 |      20 |
 | use Z;              | 0.001  |        84 |                 82 |                 0.71% |              4388.14% |   0.00016 |      20 |
 | use Z -compat;      | 0.005  |        84 |                 82 |                 0.75% |              4386.44% |   0.00012 |      21 |
 | use Z -modern;      | 0.001  |        84 |                 82 |                 0.94% |              4378.28% |   0.00017 |      20 |
 | use Z -detect;      | 0.001  |        84 |                 82 |                 1.05% |              4373.31% |   0.0001  |      20 |
 | use Z -compat;      | 0.001  |        83 |                 81 |                 1.37% |              4359.20% |   0.00012 |      21 |
 | perl -e1 (baseline) | 0.001  |         2 |                  0 |              4277.17% |                 3.27% | 8.4e-05   |      21 |
 | perl -e1 (baseline) | 0.005  |         2 |                  0 |              4420.17% |                 0.00% | 5.8e-05   |      20 |
 +---------------------+--------+-----------+--------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Z>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Z>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Z>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
