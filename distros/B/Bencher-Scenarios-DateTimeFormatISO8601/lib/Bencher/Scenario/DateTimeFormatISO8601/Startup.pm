package Bencher::Scenario::DateTimeFormatISO8601::Startup;

our $DATE = '2018-07-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of DateTime::Format::ISO8601',
    participants => [
        {
            name => 'load',
            code_template => 'use DateTime::Format::ISO8601',
        },
        {
            name => 'load+instantiate',
            code_template => 'use DateTime::Format::ISO8601; my $f = DateTime::Format::ISO8601->new',
        },
    ],
    code_startup => 1,
};

1;
# ABSTRACT: Benchmark startup of DateTime::Format::ISO8601

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatISO8601::Startup - Benchmark startup of DateTime::Format::ISO8601

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatISO8601::Startup (from Perl distribution Bencher-Scenarios-DateTimeFormatISO8601), released on 2018-07-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatISO8601::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * load (perl_code)

Code template:

 use DateTime::Format::ISO8601



=item * load+instantiate (perl_code)

Code template:

 use DateTime::Format::ISO8601; my $f = DateTime::Format::ISO8601->new



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatISO8601::Startup >>):

 #table1#
 +---------------------+-----------+-------------------------+------------+-----------+---------+
 | participant         | time (ms) | code_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------+-------------------------+------------+-----------+---------+
 | load                |     180   |                   173.7 |          1 |   0.00057 |      20 |
 | load+instantiate    |     180   |                   173.7 |          1 |   0.00059 |      20 |
 | perl -e1 (baseline) |       6.3 |                     0   |         28 | 3.4e-05   |      20 |
 +---------------------+-----------+-------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatISO8601>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatISO8601>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatISO8601>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
