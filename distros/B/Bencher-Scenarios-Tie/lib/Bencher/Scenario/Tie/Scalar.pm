package Bencher::Scenario::Tie::Scalar;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-27'; # DATE
our $DIST = 'Bencher-Scenarios-Tie'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark the overhead of tied scalar',
    modules => {
        'Tie::Scalar::NoOp' => {},
    },
    participants => [
        {name => 'read-tied-100k'  , code_template => 'tie my $var, "Tie::Scalar::NoOp"; my $var2; for (1..100_000) { $var2 = $var }'},
        {name => 'read-notie-100k' , code_template => 'my $var; my $var2; for (1..100_000) { $var2 = $var }'},
        {name => 'write-tied-100k' , code_template => 'tie my $var, "Tie::Scalar::NoOp"; for (1..100_000) { $var = 42 }'},
        {name => 'write-notie-100k', code_template => 'my $var; for (1..100_000) { $var = 42 }'},
    ],
};

1;
# ABSTRACT: Benchmark the overhead of tied scalar

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Tie::Scalar - Benchmark the overhead of tied scalar

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Tie::Scalar (from Perl distribution Bencher-Scenarios-Tie), released on 2023-12-27.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Tie::Scalar

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Tie::Scalar::NoOp> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * read-tied-100k (perl_code)

Code template:

 tie my $var, "Tie::Scalar::NoOp"; my $var2; for (1..100_000) { $var2 = $var }



=item * read-notie-100k (perl_code)

Code template:

 my $var; my $var2; for (1..100_000) { $var2 = $var }



=item * write-tied-100k (perl_code)

Code template:

 tie my $var, "Tie::Scalar::NoOp"; for (1..100_000) { $var = 42 }



=item * write-notie-100k (perl_code)

Code template:

 my $var; for (1..100_000) { $var = 42 }



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Tie::Scalar

Result formatted as table:

 #table1#
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant      | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | read-tied-100k   |        40 |        30 |                 0.00% |               787.74% |   0.00035 |      20 |
 | write-tied-100k  |        45 |        22 |                21.47% |               630.86% |   0.00015 |      20 |
 | read-notie-100k  |       300 |         3 |               730.21% |                 6.93% | 6.6e-05   |      20 |
 | write-notie-100k |       330 |         3 |               787.74% |                 0.00% | 2.8e-05   |      20 |
 +------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                     Rate  read-tied-100k  write-tied-100k  read-notie-100k  write-notie-100k 
  read-tied-100k     40/s              --             -26%             -90%              -90% 
  write-tied-100k    45/s             36%               --             -86%              -86% 
  read-notie-100k   300/s            900%             633%               --                0% 
  write-notie-100k  330/s            900%             633%               0%                -- 
 
 Legends:
   read-notie-100k: participant=read-notie-100k
   read-tied-100k: participant=read-tied-100k
   write-notie-100k: participant=write-notie-100k
   write-tied-100k: participant=write-tied-100k

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Tie>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Tie>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Tie>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
