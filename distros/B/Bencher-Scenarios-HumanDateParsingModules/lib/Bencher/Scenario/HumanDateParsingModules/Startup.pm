package Bencher::Scenario::HumanDateParsingModules::Startup;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of some human date parsing modules',
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
# ABSTRACT: Benchmark startup overhead of some human date parsing modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HumanDateParsingModules::Startup - Benchmark startup overhead of some human date parsing modules

=head1 VERSION

This document describes version 0.007 of Bencher::Scenario::HumanDateParsingModules::Startup (from Perl distribution Bencher-Scenarios-HumanDateParsingModules), released on 2017-06-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HumanDateParsingModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Alami::EN> 0.14

L<DateTime::Format::Alami::ID> 0.14

L<DateTime::Format::Flexible> 0.26

L<DateTime::Format::Natural> 1.04

L<DateTime> 1.36

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux Debian version 8.0 >>, OS kernel: I<< Linux version 3.16.0-4-amd64 >>.

Benchmark with default options (C<< bencher -m HumanDateParsingModules::Startup >>):

 #table1#
 {dataset=>undef}
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::Flexible  | 16                           | 20                 | 60             |       120 |                    114 |        1   |   0.00021 |      20 |
 | DateTime::Format::Natural   | 11                           | 15                 | 48             |       110 |                    104 |        1.1 |   0.00022 |      20 |
 | DateTime                    | 0.82                         | 4.1                | 20             |        72 |                     66 |        1.7 |   0.00018 |      20 |
 | DateTime::Format::Alami::ID | 16                           | 20                 | 60             |        25 |                     19 |        4.8 | 6.2e-05   |      20 |
 | DateTime::Format::Alami::EN | 2.8                          | 6.4                | 24             |        25 |                     19 |        4.8 | 5.7e-05   |      20 |
 | perl -e1 (baseline)         | 2.8                          | 6.4                | 24             |         6 |                      0 |       20   | 2.1e-05   |      20 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+

=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HumanDateParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatAlami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HumanDateParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
