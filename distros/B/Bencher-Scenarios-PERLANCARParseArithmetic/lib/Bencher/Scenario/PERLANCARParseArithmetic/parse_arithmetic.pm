package Bencher::Scenario::PERLANCARParseArithmetic::parse_arithmetic;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.006'; # VERSION

our $scenario = {
    summary => 'Benchmark parse_arithmetic()',
    modules => {
    },
    participants => [
        {
            fcall_template => 'PERLANCAR::Parse::Arithmetic::parse_arithmetic(<expr>)',
        },
        {
            fcall_template => 'PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic(<expr>)',
        },
        {
            fcall_template => 'PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic(<expr>)',
        },
        {
            fcall_template => 'PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic(<expr>)',
        },
    ],
    datasets => [
        {
            args => {expr => '1'},
        },
        {
            args => {expr => '1' . ('+1' x (  2-1)) },
        },
        {
            args => {expr => '1' . ('+1' x (  5-1)) },
        },
        {
            name => '1+1+..+1 (10x)',
            args => {expr => '1' . ('+1' x ( 10-1)) } },
        {
            name => '1+1+..+1 (20x)',
            args => {expr => '1' . ('+1' x ( 20-1)) },
        },
        {
            name => '1+1+..+1 (100x)',
            args => {expr => '1' . ('+1' x (100-1)) },
        },
        {
            name => '1+1+..+1 (200x)',
            args => {expr => '1' . ('+1' x (200-1)) },
        },
        {
            name => '1+1+..+1 (500x)',
            args => {expr => '1' . ('+1' x (500-1)) },
        },
        {
            name => '1+1+..+1 (1000x)',
            args => {expr => '1' . ('+1' x (1000-1)) },
        },
    ],
};

1;
# ABSTRACT: Benchmark parse_arithmetic()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCARParseArithmetic::parse_arithmetic - Benchmark parse_arithmetic()

=head1 VERSION

This document describes version 0.006 of Bencher::Scenario::PERLANCARParseArithmetic::parse_arithmetic (from Perl distribution Bencher-Scenarios-PERLANCARParseArithmetic), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCARParseArithmetic::parse_arithmetic

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCARParseArithmetic::parse_arithmetic

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Parse::Arithmetic> 0.004

L<PERLANCAR::Parse::Arithmetic::Marpa> 0.004

L<PERLANCAR::Parse::Arithmetic::NoHash> 0.004

L<PERLANCAR::Parse::Arithmetic::Pegex> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Parse::Arithmetic::parse_arithmetic (perl_code)

Function call template:

 PERLANCAR::Parse::Arithmetic::parse_arithmetic(<expr>)



=item * PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic (perl_code)

Function call template:

 PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic(<expr>)



=item * PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic (perl_code)

Function call template:

 PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic(<expr>)



=item * PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic (perl_code)

Function call template:

 PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic(<expr>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 1

=item * 1+1

=item * 1+1+1+1+1

=item * 1+1+..+1 (10x)

=item * 1+1+..+1 (20x)

=item * 1+1+..+1 (100x)

=item * 1+1+..+1 (200x)

=item * 1+1+..+1 (500x)

=item * 1+1+..+1 (1000x)

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCARParseArithmetic::parse_arithmetic >>):

 #table1#
 +--------------------------------------------------------+------------------+-----------+------------+------------+-----------+---------+
 | participant                                            | dataset          | rate (/s) | time (ms)  | vs_slowest |  errors   | samples |
 +--------------------------------------------------------+------------------+-----------+------------+------------+-----------+---------+
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (1000x) |        17 | 58         |        1   |   0.00024 |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (500x)  |        33 | 30         |        1.9 |   0.00016 |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (200x)  |        70 | 14         |        4.1 |   0.00011 |      21 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (1000x) |        80 | 10         |        4   |   0.00014 |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (100x)  |       100 | 10         |        6   |   0.00013 |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (500x)  |       200 |  6         |        9   |   0.0001  |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (20x)   |       190 |  5.1       |       11   | 4.6e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+..+1 (10x)   |       200 |  5         |       10   | 4.9e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1+1+1+1        |       200 |  4         |       10   | 5.7e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1+1              |       240 |  4.2       |       14   |   5e-06   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (1000x) |       200 |  4         |       10   | 7.8e-05   |      23 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (1000x) |       244 |  4.1       |       14.2 | 3.8e-06   |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex::parse_arithmetic  | 1                |       240 |  4.1       |       14   |   2e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (200x)  |       370 |  2.7       |       22   | 6.9e-06   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (500x)  |       510 |  2         |       30   | 1.6e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (500x)  |       550 |  1.8       |       32   | 1.1e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (100x)  |       620 |  1.6       |       36   | 1.1e-05   |      21 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (200x)  |      1380 |  0.723     |       80.4 | 6.9e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (200x)  |      1490 |  0.672     |       86.6 | 2.7e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (20x)   |      1600 |  0.626     |       93   | 4.3e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+..+1 (10x)   |      1700 |  0.58      |      100   | 1.2e-06   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1+1+1+1        |      1960 |  0.51      |      114   | 2.6e-07   |      21 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1+1              |      2200 |  0.46      |      130   | 4.8e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::Marpa::parse_arithmetic  | 1                |      2300 |  0.43      |      130   | 4.8e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (100x)  |      2460 |  0.406     |      143   | 2.4e-07   |      25 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (100x)  |      2700 |  0.37      |      160   | 8.5e-07   |      23 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (20x)   |     12000 |  0.084     |      690   | 1.2e-07   |      26 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (20x)   |     13000 |  0.079     |      740   |   8e-08   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+..+1 (10x)   |     20000 |  0.04      |     1000   | 8.4e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+..+1 (10x)   |     25000 |  0.04      |     1400   | 1.1e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1+1+1+1        |     45500 |  0.022     |     2650   |   2e-08   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1+1+1+1        |     49400 |  0.0202    |     2870   | 6.7e-09   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1+1              |    100000 |  0.009     |     6000   | 1.4e-07   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1+1              |    114260 |  0.0087517 |     6648.7 | 1.2e-11   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash::parse_arithmetic | 1                |    210000 |  0.0048    |    12000   | 8.3e-09   |      20 |
 | PERLANCAR::Parse::Arithmetic::parse_arithmetic         | 1                |    220000 |  0.0045    |    13000   | 6.7e-09   |      20 |
 +--------------------------------------------------------+------------------+-----------+------------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m PERLANCARParseArithmetic::parse_arithmetic --module-startup >>):

 #table2#
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                          | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | PERLANCAR::Parse::Arithmetic::Marpa  | 0.95                         | 4.3                | 16             |      79   |                   72.8 |        1   |   0.00017 |      20 |
 | PERLANCAR::Parse::Arithmetic::Pegex  | 0.83                         | 4.2                | 16             |      19   |                   12.8 |        4.3 |   4e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic         | 12                           | 16                 | 38             |       9.6 |                    3.4 |        8.3 | 2.5e-05   |      20 |
 | PERLANCAR::Parse::Arithmetic::NoHash | 2                            | 5.4                | 19             |       9.5 |                    3.3 |        8.3 | 7.5e-05   |      20 |
 | perl -e1 (baseline)                  | 0.95                         | 4.4                | 16             |       6.2 |                    0   |       13   |   2e-05   |      20 |
 +--------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCARParseArithmetic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCARParseArithmetic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCARParseArithmetic>

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
