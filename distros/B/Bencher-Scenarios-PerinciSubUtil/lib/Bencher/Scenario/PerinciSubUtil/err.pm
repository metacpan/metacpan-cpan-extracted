package Bencher::Scenario::PerinciSubUtil::err;

our $DATE = '2017-01-31'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark err()',
    participants => [
        {
            name => 'err',
            module => 'Perinci::Sub::Util',
            fcall_template => 'Perinci::Sub::Util::err(@{<args>})',
        },
    ],
    datasets => [
        {name=>'err()', args => {args=>[]}},
        {name=>'err(404)', args => {args=>[404]}},
        {name=>'err(404,"message")', args => {args=>[404, "message"]}},
        {name=>'err(404,"message",[500,"prev"])', args => {args=>[404, "message", [500,"prev"]]}},
    ],
};

1;
# ABSTRACT: Benchmark err()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PerinciSubUtil::err - Benchmark err()

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::PerinciSubUtil::err (from Perl distribution Bencher-Scenarios-PerinciSubUtil), released on 2017-01-31.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PerinciSubUtil::err

To run module startup overhead benchmark:

 % bencher --module-startup -m PerinciSubUtil::err

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Perinci::Sub::Util> 0.46

=head1 BENCHMARK PARTICIPANTS

=over

=item * err (perl_code)

Function call template:

 Perinci::Sub::Util::err(@{<args>})



=back

=head1 BENCHMARK DATASETS

=over

=item * err()

=item * err(404)

=item * err(404,"message")

=item * err(404,"message",[500,"prev"])

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PerinciSubUtil::err >>):

 #table1#
 +---------------------------------+-----------+-----------+------------+---------+---------+
 | dataset                         | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+-----------+-----------+------------+---------+---------+
 | err(404,"message",[500,"prev"]) |    250000 |   4.1     |    1       | 6.4e-09 |      22 |
 | err(404,"message")              |    280000 |   3.6     |    1.1     | 6.7e-09 |      20 |
 | err(404)                        |    299082 |   3.34357 |    1.21895 |   0     |      22 |
 | err()                           |    333800 |   2.995   |    1.361   | 3.4e-11 |      21 |
 +---------------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m PerinciSubUtil::err --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Perinci::Sub::Util  | 844                          | 4.1                | 16             |       7.7 |                    3.8 |          1 | 4.2e-05 |      20 |
 | perl -e1 (baseline) | 1124                         | 4.4                | 16             |       3.9 |                    0   |          2 | 7.5e-06 |      20 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubUtil>

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
