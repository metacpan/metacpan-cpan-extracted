package Bencher::Scenario::DateTimeOfDay::format;

our $DATE = '2019-02-07'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark timeofday formatting",
    participants => [
        {name=>"hms", module=>"Date::TimeOfDay", code_template=>'state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->hms'},
        {name=>"stringify", module=>"Date::TimeOfDay", code_template=>'state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->stringify'},
    ],
};

1;
# ABSTRACT: Benchmark timeofday formatting

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeOfDay::format - Benchmark timeofday formatting

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeOfDay::format (from Perl distribution Bencher-Scenarios-DateTimeOfDay), released on 2019-02-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeOfDay::format

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeOfDay::format

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::TimeOfDay> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * hms (perl_code)

Code template:

 state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->hms



=item * stringify (perl_code)

Code template:

 state $tod = Date::TimeOfDay->from_float(float=>86399); $tod->stringify



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeOfDay::format >>):

 #table1#
 +-------------+-----------+-----------+------------+---------+---------+
 | participant | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------+-----------+-----------+------------+---------+---------+
 | hms         |    520000 |      1.9  |       1    | 3.4e-09 |      20 |
 | stringify   |    551000 |      1.81 |       1.06 | 7.6e-10 |      28 |
 +-------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeOfDay::format --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Date::TimeOfDay     |      11   |                    4.6 |        1   |   5e-05 |      20 |
 | perl -e1 (baseline) |       6.4 |                    0   |        1.6 | 3.2e-05 |      20 |
 +---------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeOfDay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeOfDay>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeOfDay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
