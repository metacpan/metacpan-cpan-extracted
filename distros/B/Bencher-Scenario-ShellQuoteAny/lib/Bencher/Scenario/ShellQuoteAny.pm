package Bencher::Scenario::ShellQuoteAny;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark cross-platform shell quoting',
    participants => [
        {
            fcall_template=>'ShellQuote::Any::shell_quote(<cmd>)',
        },
        {
            fcall_template=>'PERLANCAR::ShellQuote::Any::shell_quote(@{<cmd>})',
        },
        {
            fcall_template=>'ShellQuote::Any::Tiny::shell_quote(<cmd>)',
        },
    ],
    datasets => [
        {name=>'empty0', args=>{cmd=>[]}},
        {name=>'empty1', args=>{cmd=>['']}},
        {name=>'cmd1', args=>{cmd=>['foo bar']}},
        {name=>'cmd5', args=>{cmd=>['foo', 'bar', 'baz', 'qux', 'quux']}},
    ],
};

1;
# ABSTRACT: Benchmark cross-platform shell quoting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ShellQuoteAny - Benchmark cross-platform shell quoting

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::ShellQuoteAny (from Perl distribution Bencher-Scenario-ShellQuoteAny), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ShellQuoteAny

To run module startup overhead benchmark:

 % bencher --module-startup -m ShellQuoteAny

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<ShellQuote::Any> 0.03

L<PERLANCAR::ShellQuote::Any> 0.002

L<ShellQuote::Any::Tiny> 0.004

=head1 BENCHMARK PARTICIPANTS

=over

=item * ShellQuote::Any::shell_quote (perl_code)

Function call template:

 ShellQuote::Any::shell_quote(<cmd>)



=item * PERLANCAR::ShellQuote::Any::shell_quote (perl_code)

Function call template:

 PERLANCAR::ShellQuote::Any::shell_quote(@{<cmd>})



=item * ShellQuote::Any::Tiny::shell_quote (perl_code)

Function call template:

 ShellQuote::Any::Tiny::shell_quote(<cmd>)



=back

=head1 BENCHMARK DATASETS

=over

=item * empty0

=item * empty1

=item * cmd1

=item * cmd5

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ShellQuoteAny >>):

 #table1#
 {dataset=>"cmd1"}
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    400000 |       2.5 |        1   | 3.3e-09 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    420000 |       2.4 |        1   | 3.3e-09 |      20 |
 | ShellQuote::Any::Tiny::shell_quote      |   1200000 |       0.8 |        3.1 | 1.6e-09 |      21 |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+

 #table2#
 {dataset=>"cmd5"}
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    233199 |   4.28818 |       1    |   0     |      22 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    244000 |   4.1     |       1.05 | 1.7e-09 |      20 |
 | ShellQuote::Any::Tiny::shell_quote      |    990000 |   1       |       4.2  | 1.6e-09 |      21 |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+

 #table3#
 {dataset=>"empty0"}
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                             | rate (/s) | time (ns) | vs_slowest |  errors | samples |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    987900 |      1012 |        1   | 1.2e-11 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |   1000000 |      1000 |        1   | 1.6e-09 |      21 |
 | ShellQuote::Any::Tiny::shell_quote      |   1400000 |       700 |        1.4 | 8.3e-10 |      20 |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+

 #table4#
 {dataset=>"empty1"}
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | participant                             | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+
 | ShellQuote::Any::shell_quote            |    602000 |      1.66 |        1   | 8.4e-10 |      20 |
 | PERLANCAR::ShellQuote::Any::shell_quote |    680000 |      1.5  |        1.1 | 1.7e-09 |      20 |
 | ShellQuote::Any::Tiny::shell_quote      |   1200000 |      0.82 |        2   | 7.1e-09 |      20 |
 +-----------------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ShellQuoteAny --module-startup >>):

 #table5#
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | ShellQuote::Any            | 852                          | 4.1                | 16             |       7.4 |                    2.7 |        1   |   4e-05 |      20 |
 | ShellQuote::Any::Tiny      | 840                          | 4.1                | 16             |       6.3 |                    1.6 |        1.2 |   4e-05 |      20 |
 | PERLANCAR::ShellQuote::Any | 976                          | 4.4                | 16             |       5.2 |                    0.5 |        1.4 | 2.4e-05 |      20 |
 | perl -e1 (baseline)        | 884                          | 4.2                | 16             |       4.7 |                    0   |        1.6 | 1.9e-05 |      20 |
 +----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ShellQuoteAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ShellQuoteAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ShellQuoteAny>

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
