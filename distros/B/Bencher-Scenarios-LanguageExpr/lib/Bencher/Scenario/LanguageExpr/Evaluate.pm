package Bencher::Scenario::LanguageExpr::Evaluate;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

# put shared datasets here
#use Bencher::ScenarioUtil::LanguageExpr;

our $scenario = {
    summary => 'Benchmark evaluation',
    modules => {
        'Language::Expr' => 0.24,
    },
    participants => [
        {
            module => 'Language::Expr::Compiler::perl',
            code_template => 'state $plc = Language::Expr::Compiler::perl->new; $plc->eval(<expr>)',
        },
    ],
    datasets => [
        {
            args => {expr => '1'},
        },
        {
            args => {expr => '1' . ('*1' x (  2-1)) },
        },
        {
            args => {expr => '1' . ('*1' x (  5-1)) },
        },
        {
            name => '1*1*...*1 (10x)',
            args => {expr => '1' . ('*1' x ( 10-1)) } },
        {
            name => '1*1*...*1 (20x)',
            args => {expr => '1' . ('*1' x ( 20-1)) },
        },
        {
            name => '1*1*...*1 (100x)',
            args => {expr => '1' . ('*1' x (100-1)) },
        },
    ],
};

1;
# ABSTRACT: Benchmark evaluation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LanguageExpr::Evaluate - Benchmark evaluation

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::LanguageExpr::Evaluate (from Perl distribution Bencher-Scenarios-LanguageExpr), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LanguageExpr::Evaluate

To run module startup overhead benchmark:

 % bencher --module-startup -m LanguageExpr::Evaluate

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Language::Expr> 0.29

L<Language::Expr::Compiler::perl> 0.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * Language::Expr::Compiler::perl (perl_code)

Code template:

 state $plc = Language::Expr::Compiler::perl->new; $plc->eval(<expr>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 1*1

=item * 1*1*1*1*1

=item * 1*1*...*1 (10x)

=item * 1*1*...*1 (20x)

=item * 1*1*...*1 (100x)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LanguageExpr::Evaluate >>):

 #table1#
 +------------------+-----------+-----------+------------+---------+---------+
 | dataset          | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +------------------+-----------+-----------+------------+---------+---------+
 | 1*1*...*1 (100x) |        35 |     29    |        1   | 4.9e-05 |      21 |
 | 1*1*...*1 (20x)  |       170 |      5.9  |        4.9 | 3.3e-05 |      20 |
 | 1*1*...*1 (10x)  |       330 |      3    |        9.5 | 1.4e-05 |      22 |
 | 1*1*1*1*1        |       630 |      1.6  |       18   | 2.5e-06 |      20 |
 | 1*1              |      1200 |      0.82 |       35   | 1.1e-06 |      20 |
 | 1                |      1800 |      0.54 |       53   | 1.2e-06 |      20 |
 +------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LanguageExpr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LanguageExpr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LanguageExpr>

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
