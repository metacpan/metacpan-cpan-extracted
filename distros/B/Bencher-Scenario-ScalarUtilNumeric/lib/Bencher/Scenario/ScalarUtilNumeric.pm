package Bencher::Scenario::ScalarUtilNumeric;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP',
    participants => [
        map {
            my $which = $_;
            my $mod = $which eq 'pp' ?
                "Scalar::Util::Numeric::PP" : "Scalar::Util::Numeric";
            (
                {
                    module => $mod,
                    name => "isint-int-$which",
                    fcall_template => "$mod\::isint(1)",
                    tags => [$which, "func:isint"],
                },
                {
                    module => $mod,
                    name => "isint-str-$which",
                    fcall_template => "$mod\::isint('a')",
                    tags => [$which, "func:isint"],
                },
                {
                    module => $mod,
                    name => "isint-float-$which",
                    fcall_template => "$mod\::isint(1.23)",
                    tags => [$which, "func:isint"],
                },

                {
                    module => $mod,
                    name => "isfloat-int-$which",
                    fcall_template => "$mod\::isfloat(1)",
                    tags => [$which, "func:isfloat"],
                },
                {
                    module => $mod,
                    name => "isfloat-str-$which",
                    fcall_template => "$mod\::isfloat('a')",
                    tags => [$which, "func:isfloat"],
                },
                {
                    module => $mod,
                    name => "isfloat-float-$which",
                    fcall_template => "$mod\::isfloat(1.23)",
                    tags => [$which, "func:isfloat"],
                },

                {
                    module => $mod,
                    name => "isnum-int-$which",
                    fcall_template => "$mod\::isnum(1)",
                    tags => [$which, "func:isnum"],
                },
                {
                    module => $mod,
                    name => "isnum-str-$which",
                    fcall_template => "$mod\::isnum('a')",
                    tags => [$which, "func:isnum"],
                },
                {
                    module => $mod,
                    name => "isnum-float-$which",
                    fcall_template => "$mod\::isnum(1.23)",
                    tags => [$which, "func:isnum"],
                },
            );
        } ("pp", "xs"),
    ],
};

1;
# ABSTRACT: Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ScalarUtilNumeric - Benchmark Scalar::Util::Numeric vs Scalar::Util::Numeric::PP

=head1 VERSION

This document describes version 0.02 of Bencher::Scenario::ScalarUtilNumeric (from Perl distribution Bencher-Scenario-ScalarUtilNumeric), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ScalarUtilNumeric

To run module startup overhead benchmark:

 % bencher --module-startup -m ScalarUtilNumeric

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Scalar::Util::Numeric::PP> 0.04

L<Scalar::Util::Numeric> 0.40

=head1 BENCHMARK PARTICIPANTS

=over

=item * isint-int-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint(1)



=item * isint-str-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint('a')



=item * isint-float-pp (perl_code) [pp, func:isint]

Function call template:

 Scalar::Util::Numeric::PP::isint(1.23)



=item * isfloat-int-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat(1)



=item * isfloat-str-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat('a')



=item * isfloat-float-pp (perl_code) [pp, func:isfloat]

Function call template:

 Scalar::Util::Numeric::PP::isfloat(1.23)



=item * isnum-int-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum(1)



=item * isnum-str-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum('a')



=item * isnum-float-pp (perl_code) [pp, func:isnum]

Function call template:

 Scalar::Util::Numeric::PP::isnum(1.23)



=item * isint-int-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint(1)



=item * isint-str-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint('a')



=item * isint-float-xs (perl_code) [xs, func:isint]

Function call template:

 Scalar::Util::Numeric::isint(1.23)



=item * isfloat-int-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat(1)



=item * isfloat-str-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat('a')



=item * isfloat-float-xs (perl_code) [xs, func:isfloat]

Function call template:

 Scalar::Util::Numeric::isfloat(1.23)



=item * isnum-int-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum(1)



=item * isnum-str-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum('a')



=item * isnum-float-xs (perl_code) [xs, func:isnum]

Function call template:

 Scalar::Util::Numeric::isnum(1.23)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m ScalarUtilNumeric >>):

 #table1#
 +------------------+-----------+-----------+------------+---------+---------+
 | participant      | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +------------------+-----------+-----------+------------+---------+---------+
 | isnum-float-pp   |    455464 |   2.19556 |      1     |   0     |      24 |
 | isnum-str-pp     |    580500 |   1.723   |      1.275 | 1.5e-10 |      30 |
 | isfloat-int-pp   |    850000 |   1.2     |      1.9   | 1.7e-09 |      20 |
 | isfloat-float-pp |    930000 |   1.1     |      2     | 1.7e-09 |      20 |
 | isfloat-str-pp   |   1030000 |   0.968   |      2.27  | 7.4e-10 |      22 |
 | isint-float-pp   |   1220000 |   0.818   |      2.68  | 5.2e-10 |      20 |
 | isnum-int-pp     |   1500000 |   0.668   |      3.28  |   2e-10 |      21 |
 | isint-int-pp     |   1900000 |   0.52    |      4.2   | 8.3e-10 |      20 |
 | isfloat-float-xs |   2600000 |   0.385   |      5.71  | 1.8e-10 |      28 |
 | isnum-float-xs   |   2610000 |   0.383   |      5.73  | 2.5e-10 |      20 |
 | isint-str-pp     |   2740000 |   0.365   |      6.02  | 2.1e-10 |      20 |
 | isint-float-xs   |   2800000 |   0.36    |      6.1   | 2.1e-09 |      20 |
 | isint-int-xs     |   9000000 |   0.1     |     20     | 6.1e-09 |      20 |
 | isint-str-xs     |  15000000 |   0.066   |     33     |   4e-10 |      20 |
 | isfloat-int-xs   |  15800000 |   0.0631  |     34.8   | 4.6e-11 |      20 |
 | isfloat-str-xs   |  15900000 |   0.0628  |     34.9   | 4.6e-11 |      20 |
 | isnum-int-xs     |  15900000 |   0.0627  |     35     | 4.6e-11 |      20 |
 | isnum-str-xs     |  16000000 |   0.0625  |     35.1   | 4.7e-11 |      21 |
 +------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m ScalarUtilNumeric --module-startup >>):

 #table2#
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant               | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Scalar::Util::Numeric     | 964                          | 4.3                | 16             |      12   |                    6.3 |        1   | 7.3e-05 |      20 |
 | Scalar::Util::Numeric::PP | 964                          | 4.4                | 16             |       9.1 |                    3.4 |        1.3 | 3.9e-05 |      20 |
 | perl -e1 (baseline)       | 964                          | 4.4                | 16             |       5.7 |                    0   |        2   | 1.9e-05 |      20 |
 +---------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-ScalarUtilNumeric>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-ScalarUtilNumeric>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-ScalarUtilNumeric>

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
