package Bencher::Scenario::Example::StringConcat;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark concatenation of string',
    description => <<'_',

The benchmark code starts with an empty string then appends one character at a
time for N times:

    $str = '';
    $str .= 'x';

_
    participants => [
        {name=>'concat_str', code_template=>'my $str = ""; for (1..<size>) { $str .= "x" } $str'},
    ],
    datasets => [
        {args => {'size@' => [10, 1000, 5000, 10_000, 50_000, 100_000, 500_000, 1000_000, 5000_000]}},
    ],
};

1;
# ABSTRACT: Benchmark concatenation of string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::StringConcat - Benchmark concatenation of string

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Example::StringConcat (from Perl distribution Bencher-Scenarios-Examples), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Example::StringConcat

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

The benchmark code starts with an empty string then appends one character at a
time for N times:

 $str = '';
 $str .= 'x';


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * concat_str (perl_code)

Code template:

 my $str = ""; for (1..<size>) { $str .= "x" } $str



=back

=head1 BENCHMARK DATASETS

=over

=item * [10,1000,5000,10000,50000,100000,500000,1000000,5000000]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Example::StringConcat >>):

 #table1#
 +----------+-----------+-----------+------------+-----------+---------+
 | arg_size | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------+-----------+-----------+------------+-----------+---------+
 | 5000000  |       3.7 | 270       |          1 |   0.00056 |      20 |
 | 1000000  |      18   |  55       |          5 | 6.7e-05   |      20 |
 | 500000   |      37   |  27       |         10 |   0.00011 |      20 |
 | 100000   |     180   |   5.5     |         50 |   2e-05   |      20 |
 | 50000    |     400   |   3       |        100 | 4.3e-05   |      20 |
 | 10000    |    2000   |   0.501   |        546 | 4.3e-07   |      20 |
 | 5000     |    3590   |   0.279   |        982 | 2.1e-07   |      20 |
 | 1000     |   22000   |   0.045   |       6100 | 1.1e-07   |      26 |
 | 10       | 1600000   |   0.00064 |     430000 | 8.4e-10   |      20 |
 +----------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::Example::StringConcat2>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
