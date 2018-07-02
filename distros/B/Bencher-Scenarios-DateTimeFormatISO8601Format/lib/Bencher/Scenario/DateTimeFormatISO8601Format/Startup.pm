package Bencher::Scenario::DateTimeFormatISO8601Format::Startup;

our $DATE = '2018-07-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of DateTime::Format::ISO8601::Format',
    participants => [
        {
            name => 'load',
            code_template => 'use DateTime::Format::ISO8601::Format',
        },
        {
            name => 'load+instantiate',
            code_template => 'use DateTime::Format::ISO8601::Format; my $f = DateTime::Format::ISO8601::Format->new',
        },
    ],
    code_startup => 1,
};

1;
# ABSTRACT: Benchmark startup of DateTime::Format::ISO8601::Format

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatISO8601Format::Startup - Benchmark startup of DateTime::Format::ISO8601::Format

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatISO8601Format::Startup (from Perl distribution Bencher-Scenarios-DateTimeFormatISO8601Format), released on 2018-07-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatISO8601Format::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * load (perl_code)

Code template:

 use DateTime::Format::ISO8601::Format



=item * load+instantiate (perl_code)

Code template:

 use DateTime::Format::ISO8601::Format; my $f = DateTime::Format::ISO8601::Format->new



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatISO8601Format::Startup >>):

 #table1#
 +---------------------+-----------+-------------------------+------------+---------+---------+
 | participant         | time (ms) | code_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+-----------+-------------------------+------------+---------+---------+
 | load+instantiate    |       7.7 |                     2.3 |        1   | 2.6e-05 |      20 |
 | load                |       7.6 |                     2.2 |        1   | 1.2e-05 |      20 |
 | perl -e1 (baseline) |       5.4 |                     0   |        1.4 | 2.2e-05 |      20 |
 +---------------------+-----------+-------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatISO8601Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatISO8601Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatISO8601Format>

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
