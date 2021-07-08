package Bencher::Scenario::Perl::Swap;

our $DATE = '2021-07-03'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark swapping two variables',
    participants => [
        {code_template => 'my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a = $b; $b = $tmp } [$a, $b]'},
        {code_template => 'my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) } [$a, $b]'},
    ],
    datasets => [
        {name=>'undef', args=>{a=>undef, b=>undef}},
        {name=>'empty-string', args=>{a=>'', b=>''}},
        {name=>'short-string', args=>{a=>'12345', b=>'54321'}},
        {name=>'long-string', args=>{a=>'1' x 100, b=>'2' x 100}},
        {name=>'number', args=>{a=>1, b=>2}},
    ],
};

1;
# ABSTRACT: Benchmark swapping two variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::Swap - Benchmark swapping two variables

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::Perl::Swap (from Perl distribution Bencher-Scenarios-Perl), released on 2021-07-03.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::Swap

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

=head1 BENCHMARK PARTICIPANTS

=over

=item * my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a (perl_code)

Code template:

 my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a = $b; $b = $tmp } [$a, $b]



=item * my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  (perl_code)

Code template:

 my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) } [$a, $b]



=back

=head1 BENCHMARK DATASETS

=over

=item * undef

=item * empty-string

=item * short-string

=item * long-string

=item * number

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.2 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark with default options (C<< bencher -m Perl::Swap >>):

 #table1#
 +------------------------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                                                      | dataset      | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  | empty-string |   8267.46 | 120.956   |                 0.00% |                80.43% |   0     |      20 |
 | my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  | long-string  |   8272.35 | 120.885   |                 0.06% |                80.33% |   0     |      20 |
 | my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a | empty-string |  10300    |  96.7     |                25.10% |                44.23% |   8e-08 |      20 |
 | my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a | long-string  |  10529.8  |  94.9685  |                27.36% |                41.67% |   0     |      20 |
 | my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  | number       |  14000    |  72       |                68.60% |                 7.02% | 1.1e-07 |      20 |
 | my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a | short-string |  14100    |  70.9     |                70.57% |                 5.78% | 2.7e-08 |      20 |
 | my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a | number       |  14197.45 |  70.43516 |                71.73% |                 5.07% | 4.8e-12 |      20 |
 | my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  | short-string |  14300    |  70.1     |                72.49% |                 4.60% | 2.1e-08 |      31 |
 | my $a = <a>; my $b = <b>; my $tmp; for (1..1001) { $tmp = $a; $a | undef        |  14299.1  |  69.93446 |                72.96% |                 4.32% | 5.7e-12 |      20 |
 | my $a = <a>; my $b = <b>; for (1..1001) { ($a, $b) = ($b, $a) }  | undef        |  14917.19 |  67.03677 |                80.43% |                 0.00% | 4.6e-12 |      26 |
 +------------------------------------------------------------------+--------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
