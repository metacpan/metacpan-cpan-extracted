package Bencher::Scenario::DateTime::Format::Duration::ISO8601::Formatting;

use 5.010001;
use strict;
use warnings;

use DateTime::Duration;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-DateTime-Format-Duration-ISO8601'; # DIST
our $VERSION = '0.002'; # VERSION

my $dur1 = DateTime::Duration->new(years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6, nanoseconds => 700_000_000);

our $scenario = {
    summary => 'Benchmark formatting with DateTime::Format::Duration::ISO8601',
    participants => [
        {
            name => 'format_duration',
            fcall_template => 'DateTime::Format::Duration::ISO8601->new->format_duration(<dur>)',
        },
    ],
    datasets => [
        {args => {'dur@' => [$dur1]}},
    ],
};

1;
# ABSTRACT: Benchmark formatting with DateTime::Format::Duration::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTime::Format::Duration::ISO8601::Formatting - Benchmark formatting with DateTime::Format::Duration::ISO8601

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DateTime::Format::Duration::ISO8601::Formatting (from Perl distribution Bencher-Scenarios-DateTime-Format-Duration-ISO8601), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTime::Format::Duration::ISO8601::Formatting

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTime::Format::Duration::ISO8601::Formatting

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Duration::ISO8601> 0.008

=head1 BENCHMARK PARTICIPANTS

=over

=item * format_duration (perl_code)

Function call template:

 DateTime::Format::Duration::ISO8601->new->format_duration(<dur>)



=back

=head1 BENCHMARK DATASETS

=over

=item * [bless({days=>3,end_of_month=>"wrap",minutes=>245,months=>14,nanoseconds=>700000000,seconds=>6},"DateTime::Duration")]

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m DateTime::Format::Duration::ISO8601::Formatting >>):

 #table1#
 +-----------------+------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | participant     | dataset                                                                                                                | arg_dur                                 | ds_tags | p_tags | perl | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest | errors | samples |
 +-----------------+------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+
 | format_duration | [bless({days=>3,end_of_month=>"wrap",minutes=>245,months=>14,nanoseconds=>700000000,seconds=>6},"DateTime::Duration")] | DateTime::Duration=HASH(0x558b4ff169c8) |         |        | perl |     53000 |      18.9 |                 0.00% |                 0.00% |  6e-09 |      25 |
 +-----------------+------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+---------+--------+------+-----------+-----------+-----------------------+-----------------------+--------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

       Rate     
    53000/s  -- 
 
 Legends:
   : arg_dur=DateTime::Duration=HASH(0x558b4ff169c8) dataset=[bless({days=>3,end_of_month=>"wrap",minutes=>245,months=>14,nanoseconds=>700000000,seconds=>6},"DateTime::Duration")] ds_tags= p_tags= participant=format_duration perl=perl

Benchmark module startup overhead (C<< bencher -m DateTime::Format::Duration::ISO8601::Formatting --module-startup >>):

 #table2#
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | DateTime::Format::Duration::ISO8601 |       8.9 |               2.6 |                 0.00% |                41.39% |   3e-05 |      20 |
 | perl -e1 (baseline)                 |       6.3 |               0   |                41.39% |                 0.00% | 2.3e-05 |      20 |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DFD:I  perl -e1 (baseline) 
  DFD:I                112.4/s     --                 -29% 
  perl -e1 (baseline)  158.7/s    41%                   -- 
 
 Legends:
   DFD:I: mod_overhead_time=2.6 participant=DateTime::Format::Duration::ISO8601
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTime-Format-Duration-ISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTime-Format-Duration-ISO8601>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTime-Format-Duration-ISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
