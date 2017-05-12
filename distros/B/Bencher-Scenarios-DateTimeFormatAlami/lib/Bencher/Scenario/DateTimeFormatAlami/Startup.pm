package Bencher::Scenario::DateTimeFormatAlami::Startup;

our $DATE = '2016-06-30'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of DateTime::Format::Alami against some other modules',
    module_startup => 1,
    participants => [
        {module=>'DateTime::Format::Alami::EN'},
        {module=>'DateTime::Format::Alami::ID'},
        {module=>'DateTime::Format::Flexible'},
        {module=>'DateTime::Format::Natural'},
        {module=>'DateTime'},
    ],
};

1;
# ABSTRACT: Benchmark startup of DateTime::Format::Alami against some other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTimeFormatAlami::Startup - Benchmark startup of DateTime::Format::Alami against some other modules

=head1 VERSION

This document describes version 0.004 of Bencher::Scenario::DateTimeFormatAlami::Startup (from Perl distribution Bencher-Scenarios-DateTimeFormatAlami), released on 2016-06-30.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatAlami::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Alami::EN> 0.13

L<DateTime::Format::Alami::ID> 0.13

L<DateTime::Format::Flexible> 0.26

L<DateTime::Format::Natural> 1.03

L<DateTime> 1.27

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime::Format::Alami::EN (perl_code)

L<DateTime::Format::Alami::EN>



=item * DateTime::Format::Alami::ID (perl_code)

L<DateTime::Format::Alami::ID>



=item * DateTime::Format::Flexible (perl_code)

L<DateTime::Format::Flexible>



=item * DateTime::Format::Natural (perl_code)

L<DateTime::Format::Natural>



=item * DateTime (perl_code)

L<DateTime>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.22.1 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m DateTimeFormatAlami::Startup >>):

 #table1#
 {dataset=>undef}
 +-----------------------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::Flexible  |       100 |                     95 |        1   |   0.0031  |      20 |
 | DateTime::Format::Natural   |        83 |                     78 |        1.6 |   0.00034 |      20 |
 | DateTime                    |        60 |                     55 |        2.2 |   0.00042 |      20 |
 | DateTime::Format::Alami::ID |        24 |                     19 |        5.4 |   0.00016 |      20 |
 | DateTime::Format::Alami::EN |        23 |                     18 |        5.6 | 7.8e-05   |      20 |
 | perl -e1 (baseline)         |         5 |                      0 |       30   | 5.1e-05   |      20 |
 +-----------------------------+-----------+------------------------+------------+-----------+---------+

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatAlami>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatAlami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatAlami>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
