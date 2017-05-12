package Bencher::Scenario::PERLANCAR::state;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark overhead of state (vs my) variables in a tight subroutine',
    description => <<'_',

Each variable declaration is not free.

_
    participants => [
        {
            name=>'baseline_0',
            code_template=>' ',
            #include_by_default => 0,
        },
        {
            name=>'1_state',
            code_template=>'state $s1 = 1',
        },
        {
            name=>'2_state',
            code_template=>'state $s1 = 1; state $s2 = 1',
        },
        {
            name=>'5_state',
            code_template=>'state $s1 = 1; state $s2 = 1; state $s3 = 1; state $s4 = 1; state $s5 = 1; ',
        },
        {
            name=>'10_state',
            code_template=>'state $s1=1; state $s2=1; state $s3=1; state $s4=1; state $s5=1; state $s6=1; state $s7=1; state $s8=1; state $s9=1; state $s10=1; ',
        },

        {
            name=>'5_state_do',
            code_template=>'state $s1 = do{1}; state $s2 = do{1}; state $s3 = do{1}; state $s4 = do{1}; state $s5 = do{1}; ',
            include_by_default => 0,
            summary => "The use of do{} doesn't affect the timing because they are evaluated once",
        },

        {
            name=>'1_my',
            code_template=>'my $s1 = 1',
        },
        {
            name=>'2_my',
            code_template=>'my $s1 = 1; my $s2 = 1',
        },
        {
            name=>'5_my',
            code_template=>'my $s1 = 1; my $s2 = 1; my $s3 = 1; my $s4 = 1; my $s5 = 1; ',
        },
        {
            name=>'10_my',
            code_template=>'my $s1=1; my $s2=1; my $s3=1; my $s4=1; my $s5=1; my $s6=1; my $s7=1; my $s8=1; my $s9=1; my $s10=1; ',
        },
    ],
};

1;
# ABSTRACT: Benchmark overhead of state (vs my) variables in a tight subroutine

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::state - Benchmark overhead of state (vs my) variables in a tight subroutine

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::state (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::state

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each variable declaration is not free.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * baseline_0 (perl_code)

Code template:

  



=item * 1_state (perl_code)

Code template:

 state $s1 = 1



=item * 2_state (perl_code)

Code template:

 state $s1 = 1; state $s2 = 1



=item * 5_state (perl_code)

Code template:

 state $s1 = 1; state $s2 = 1; state $s3 = 1; state $s4 = 1; state $s5 = 1; 



=item * 10_state (perl_code)

Code template:

 state $s1=1; state $s2=1; state $s3=1; state $s4=1; state $s5=1; state $s6=1; state $s7=1; state $s8=1; state $s9=1; state $s10=1; 



=item * 5_state_do (perl_code) (not included by default)

Code template:

 my $s1 = 1



=item * 1_my (perl_code)

Code template:

 my $s1 = 1; my $s2 = 1



=item * 2_my (perl_code)

Code template:

 my $s1 = 1; my $s2 = 1; my $s3 = 1; my $s4 = 1; my $s5 = 1; 



=item * 5_my (perl_code)

Code template:

 my $s1=1; my $s2=1; my $s3=1; my $s4=1; my $s5=1; my $s6=1; my $s7=1; my $s8=1; my $s9=1; my $s10=1; 



=item * 10_my (perl_code)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::state >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | 10_my       |   3400000 |     290   |       1    | 4.2e-10 |      20 |
 | 10_state    |   6900000 |     150   |       2    | 3.7e-10 |      25 |
 | 5_my        |   7100000 |     141   |       2.08 |   1e-10 |      20 |
 | 5_state     |  11700000 |      85.7 |       3.42 | 5.2e-11 |      20 |
 | 2_my        |  16000000 |      61   |       4.8  | 2.4e-10 |      27 |
 | 1_my        |  36500000 |      27.4 |      10.7  | 2.6e-11 |      20 |
 | 2_state     |  47000000 |      21   |      14    | 5.3e-11 |      20 |
 | 1_state     | 100000000 |      10   |      30    | 2.4e-10 |      28 |
 | baseline_0  | 600000000 |       2   |     200    | 2.1e-10 |      20 |
 +-------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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
