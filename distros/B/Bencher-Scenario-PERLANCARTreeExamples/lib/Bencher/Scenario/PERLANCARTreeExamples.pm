package Bencher::Scenario::PERLANCARTreeExamples;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark PERLANCAR::Tree::Examples',
    modules => {
        'PERLANCAR::Tree::Examples' => {version=>1.0.4},
    },
    description => <<'_',

Created just for testing, while adding feature in `Bencher` to return result
size.

_
    participants => [
        {
            fcall_template => 'PERLANCAR::Tree::Examples::gen_sample_data(size => <size>, backend => <backend>)',
        },
    ],
    datasets => [
        {name => 'dataset', args=>{'size@'=>['tiny1', 'medium1'], 'backend@'=>['hash', 'array']}},
    ],
    include_result_size => 1,
};

1;
# ABSTRACT: Benchmark PERLANCAR::Tree::Examples

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCARTreeExamples - Benchmark PERLANCAR::Tree::Examples

=head1 VERSION

This document describes version 0.03 of Bencher::Scenario::PERLANCARTreeExamples (from Perl distribution Bencher-Scenario-PERLANCARTreeExamples), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCARTreeExamples

To run module startup overhead benchmark:

 % bencher --module-startup -m PERLANCARTreeExamples

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Created just for testing, while adding feature in C<Bencher> to return result
size.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<PERLANCAR::Tree::Examples> 1.0.6

=head1 BENCHMARK PARTICIPANTS

=over

=item * PERLANCAR::Tree::Examples::gen_sample_data (perl_code)

Function call template:

 PERLANCAR::Tree::Examples::gen_sample_data(size => <size>, backend => <backend>)



=back

=head1 BENCHMARK DATASETS

=over

=item * dataset

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCARTreeExamples >>):

 #table1#
 +-------------+----------+-----------+-----------+------------+-----------+---------+
 | arg_backend | arg_size | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +-------------+----------+-----------+-----------+------------+-----------+---------+
 | hash        | medium1  |        11 |    93     |        1   |   0.00042 |      20 |
 | array       | medium1  |        12 |    86     |        1.1 |   0.00029 |      21 |
 | hash        | tiny1    |     47000 |     0.021 |     4300   | 5.9e-08   |      21 |
 | array       | tiny1    |     54000 |     0.018 |     5000   | 5.1e-08   |      22 |
 +-------------+----------+-----------+-----------+------------+-----------+---------+


Benchmark module startup overhead (C<< bencher -m PERLANCARTreeExamples --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | PERLANCAR::Tree::Examples | 0.82                         | 4                  | 16             |        36 |                     21 |        1   |   8e-05 |      20 |
 | perl -e1 (baseline)       | 2.9                          | 6.2                | 20             |        15 |                      0 |        2.4 | 2.8e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-PERLANCARTreeExamples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-PERLANCARTreeExamples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-PERLANCARTreeExamples>

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
