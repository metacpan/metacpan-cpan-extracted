package Bencher::Scenario::PERLANCAR::pass_list_vs_array;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark passing list vs array reference',
    description => <<'_',


_
    participants => [
        {
            name=>'pass_list',
            code_template=>'my $sub = sub {}; my @list = 1..<size>;  for (1..<reuse>) { $sub->(@list) }',
        },
        {
            name=>'pass_arrayref',
            code_template=>'my $sub = sub {}; my @list = 1..<size>;  for (1..<reuse>) { $sub->(\@list) }',
        },
    ],

    datasets => [
        {name => 'data', args => {'size@'=>[100, 1000, 10000], 'reuse@'=>[1, 10, 100, 1000]}},
    ],
};

1;
# ABSTRACT: Benchmark passing list vs array reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::pass_list_vs_array - Benchmark passing list vs array reference

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::pass_list_vs_array (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::pass_list_vs_array

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Passing a large array by reference will generate a large saving only if we reuse
the list (pass it multiple times).

=head1 BENCHMARK PARTICIPANTS

=over

=item * pass_list (perl_code)

Code template:

 my $sub = sub {}; my @list = 1..<size>;  for (1..<reuse>) { $sub->(@list) }



=item * pass_arrayref (perl_code)

Code template:

 my $sub = sub {}; my @list = 1..<size>;  for (1..<reuse>) { $sub->(\@list) }



=back

=head1 BENCHMARK DATASETS

=over

=item * data

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::pass_list_vs_array >>):

 #table1#
 +---------------+-----------+----------+-----------+-------------+------------+-----------+---------+
 | participant   | arg_reuse | arg_size | rate (/s) |  time (ms)  | vs_slowest |  errors   | samples |
 +---------------+-----------+----------+-----------+-------------+------------+-----------+---------+
 | pass_list     | 1000      | 10000    |     32    | 31          |      1     |   0.00012 |      21 |
 | pass_list     | 100       | 10000    |    310    |  3.2        |      9.8   | 1.9e-05   |      20 |
 | pass_list     | 1000      | 1000     |    420    |  2.4        |     13     | 5.4e-06   |      22 |
 | pass_list     | 10        | 10000    |   1800    |  0.56       |     56     | 1.6e-06   |      20 |
 | pass_arrayref | 1000      | 10000    |   2710    |  0.369      |     84.7   | 2.1e-07   |      21 |
 | pass_list     | 1         | 10000    |   3300    |  0.3        |    100     | 4.3e-07   |      20 |
 | pass_list     | 1000      | 100      |   3330    |  0.301      |    104     | 2.1e-07   |      20 |
 | pass_arrayref | 10        | 10000    |   3750    |  0.267      |    117     | 2.1e-07   |      20 |
 | pass_list     | 100       | 1000     |   3900    |  0.26       |    120     | 1.1e-06   |      21 |
 | pass_arrayref | 1         | 10000    |   3953.09 |  0.252967   |    123.509 |   0       |      20 |
 | pass_arrayref | 100       | 10000    |   4010    |  0.249      |    125     | 2.1e-07   |      20 |
 | pass_arrayref | 1000      | 1000     |   7771.31 |  0.128678   |    242.805 | 4.6e-11   |      20 |
 | pass_arrayref | 1000      | 100      |   9970    |  0.1        |    311     | 2.5e-08   |      23 |
 | pass_list     | 10        | 1000     |  20000    |  0.05       |    600     | 9.2e-07   |      23 |
 | pass_arrayref | 100       | 1000     |  27000    |  0.037      |    840     |   5e-08   |      23 |
 | pass_list     | 100       | 100      |  32028.1  |  0.0312226  |   1000.68  | 1.2e-11   |      20 |
 | pass_list     | 1         | 1000     |  36000    |  0.027      |   1100     | 6.7e-08   |      20 |
 | pass_arrayref | 10        | 1000     |  37000    |  0.027      |   1200     | 5.3e-08   |      20 |
 | pass_arrayref | 1         | 1000     |  40000    |  0.025      |   1300     |   5e-08   |      23 |
 | pass_arrayref | 100       | 100      |  77724.5  |  0.012866   |   2428.41  | 1.1e-11   |      30 |
 | pass_list     | 10        | 100      | 167000    |  0.00599    |   5220     | 1.7e-09   |      20 |
 | pass_arrayref | 10        | 100      | 250000    |  0.0039     |   7900     | 6.7e-09   |      20 |
 | pass_list     | 1         | 100      | 333991    |  0.00299409 |  10435.1   |   0       |      22 |
 | pass_arrayref | 1         | 100      | 361000    |  0.00277    |  11300     | 8.3e-10   |      20 |
 +---------------+-----------+----------+-----------+-------------+------------+-----------+---------+


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
