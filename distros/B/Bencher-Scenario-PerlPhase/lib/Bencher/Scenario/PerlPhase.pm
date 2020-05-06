package Bencher::Scenario::PerlPhase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-05'; # DATE
our $DIST = 'Bencher-Scenario-PerlPhase'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Perl::Phase',
    participants => [
        {
            name => 'GLOBAL_PHASE-compile_time',
            code_template => '${^GLOBAL_PHASE} eq "START" ? 1:0',
        },
        # XXX: INIT
        {
            name => 'GLOBAL_PHASE-run_time',
            code_template => '${^GLOBAL_PHASE} eq "RUN" ? 1:0',
        },
        {
            name => 'Perl::Phase::is_compile_time',
            code_template => 'use Perl::Phase; Perl::Phase::is_compile_time() ? 1:0',
        },
        {
            name => 'Perl::Phase::is_run_time',
            code_template => 'use Perl::Phase; Perl::Phase::is_run_time() ? 1:0',
        },
    ],
};

1;
# ABSTRACT: Benchmark Perl::Phase

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerlPhase - Benchmark Perl::Phase

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerlPhase (from Perl distribution Bencher-Scenario-PerlPhase), released on 2020-02-05.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerlPhase

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * GLOBAL_PHASE-compile_time (perl_code)

Code template:

 ${^GLOBAL_PHASE} eq "START" ? 1:0



=item * GLOBAL_PHASE-run_time (perl_code)

Code template:

 ${^GLOBAL_PHASE} eq "RUN" ? 1:0



=item * Perl::Phase::is_compile_time (perl_code)

Code template:

 use Perl::Phase; Perl::Phase::is_compile_time() ? 1:0



=item * Perl::Phase::is_run_time (perl_code)

Code template:

 use Perl::Phase; Perl::Phase::is_run_time() ? 1:0



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m PerlPhase >>):

 #table1#
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                  | rate (/s) | time (ns) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | Perl::Phase::is_compile_time |   4090000 |     245   |                 0.00% |               172.03% | 1.1e-10 |      20 |
 | Perl::Phase::is_run_time     |   4600000 |     220   |                11.62% |               143.71% | 3.1e-10 |      20 |
 | GLOBAL_PHASE-run_time        |  10500000 |      94.9 |               157.68% |                 5.57% | 5.5e-11 |      21 |
 | GLOBAL_PHASE-compile_time    |  11000000 |      90   |               172.03% |                 0.00% | 2.1e-10 |      20 |
 +------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


=begin html

<img src="https://st.aticpan.org/source/PERLANCAR/Bencher-Scenario-PerlPhase-0.001/share/images/bencher-result-1.png" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

L<Perl::Phase> claims to be much faster than checking C<${^GLOBAL_PHASE}>,
because it's a numeric vs string comparison. This benchmark doesn't seem to show
that. And in 99.9% of the case, the speed won't matter. Conclusion: just use the
variable perl has provided, unless you're on perl < 5.14.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-PerlPhase>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-PerlPhase>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-PerlPhase>

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
