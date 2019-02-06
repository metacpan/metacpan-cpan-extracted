package Bencher::Scenario::DateTimeOfDay::create;

our $DATE = '2019-02-07'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $scenario = {
    summary => "Benchmark timeofday creation",
    participants => [
        {fcall_template=>'Date::TimeOfDay->new(hour=>23, minute=>59, second=>59)'},
        {fcall_template=>'Date::TimeOfDay->from_hms(hms=>"23:59:59")'},
        {fcall_template=>'Date::TimeOfDay->from_float(float=>86399)'},
    ],
};

1;
# ABSTRACT: Benchmark timeofday creation

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeOfDay::create - Benchmark timeofday creation

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeOfDay::create (from Perl distribution Bencher-Scenarios-DateTimeOfDay), released on 2019-02-07.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeOfDay::create

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeOfDay::create

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::TimeOfDay> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * Date::TimeOfDay::new (perl_code)

Function call template:

 Date::TimeOfDay->new(hour=>23, minute=>59, second=>59)



=item * Date::TimeOfDay::from_hms (perl_code)

Function call template:

 Date::TimeOfDay->from_hms(hms=>"23:59:59")



=item * Date::TimeOfDay::from_float (perl_code)

Function call template:

 Date::TimeOfDay->from_float(float=>86399)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeOfDay::create >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Date::TimeOfDay::from_hms   |    177000 |    5.64   |      1     | 1.7e-09 |      20 |
 | Date::TimeOfDay::new        |    421000 |    2.37   |      2.38  |   9e-10 |      20 |
 | Date::TimeOfDay::from_float |   1175000 |    0.8513 |      6.625 | 3.5e-11 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeOfDay::create --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+------------------------+------------+---------+---------+
 | Date::TimeOfDay     |      10   |                    3.5 |        1   | 5.6e-05 |      20 |
 | perl -e1 (baseline) |       6.5 |                    0   |        1.6 | 3.7e-05 |      20 |
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
