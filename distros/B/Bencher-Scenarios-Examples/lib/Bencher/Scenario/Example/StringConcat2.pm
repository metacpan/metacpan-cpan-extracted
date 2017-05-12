package Bencher::Scenario::Example::StringConcat2;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark concatenation of string',
    description => <<'_',

The benchmark code starts with an empty string then appends one character at a
time for N times, forming a new string each time:

    $str = '';
    $str = 'x' . $str;

_
    precision => 2,
    participants => [
        {name=>'concat_str', code_template=>'my $str = ""; for (1..<size>) { $str = "x" . $str } $str'},
    ],
    datasets => [
        {args => {'size@' => [10, 1000, 5000, 10_000, 50_000, 100_000, 200_000, 500_000]}},
    ],
};

1;
# ABSTRACT: Benchmark concatenation of string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::StringConcat2 - Benchmark concatenation of string

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Example::StringConcat2 (from Perl distribution Bencher-Scenarios-Examples), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Example::StringConcat2

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

The benchmark code starts with an empty string then appends one character at a
time for N times, forming a new string each time:

 $str = '';
 $str = 'x' . $str;


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * concat_str (perl_code)

Code template:

 my $str = ""; for (1..<size>) { $str = "x" . $str } $str



=back

=head1 BENCHMARK DATASETS

=over

=item * [10,1000,5000,10000,50000,100000,200000,500000]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m Example::StringConcat2 >>):

 #table1#
 +----------+----------------+---------------+---------------+----------+---------+
 | arg_size | rate (/s)      |         time  | vs_slowest    |  errors  | samples |
 +----------+----------------+---------------+---------------+----------+---------+
 | 500000   |      0.06      | 20            |       1       |   0.29   |       3 |
 | 200000   |      0.455628  |  2.19477      |       7.58639 |   0      |       2 |
 | 100000   |      1.9       |  0.52         |      32       |   0.0011 |       3 |
 | 50000    |      7.5570713 |  0.1323264    |     125.82842 | 3.3e-10  |       2 |
 | 10000    |    185.83818   |  0.0053810256 |    3094.2841  | 3.7e-11  |       2 |
 | 5000     |    462.122     |  0.00216393   |    7694.53    |   6e-10  |       2 |
 | 1000     |   3600         |  0.00027      |   61000       | 2.2e-06  |       3 |
 | 10       | 395800         |  0.000002526  | 6591000       | 1.1e-10  |       2 |
 +----------+----------------+---------------+---------------+----------+---------+


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

L<Bencher::Scenario::Example::StringConcat>

L<http://accidentallyquadratic.tumblr.com/post/142387131042/nodejs-left-pad>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
