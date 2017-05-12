package Bencher::Scenario::HumanDateParsingModules::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.006'; # VERSION

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

This document describes version 0.006 of Bencher::Scenario::HumanDateParsingModules::Startup (from Perl distribution Bencher-Scenarios-HumanDateParsingModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HumanDateParsingModules::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::Alami::EN> 0.13

L<DateTime::Format::Alami::ID> 0.13

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

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m HumanDateParsingModules::Startup >>):

 #table1#
 {dataset=>undef}
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::Flexible  | 16                           | 20                 | 56             |     100   |                   94.4 |        1   |   0.00015 |      20 |
 | DateTime::Format::Natural   | 11                           | 15                 | 44             |      92   |                   86.4 |        1.1 |   0.0001  |      21 |
 | DateTime                    | 0.82                         | 4.1                | 16             |      61   |                   55.4 |        1.7 | 6.8e-05   |      20 |
 | DateTime::Format::Alami::ID | 16                           | 20                 | 56             |      22   |                   16.4 |        4.7 | 3.5e-05   |      20 |
 | DateTime::Format::Alami::EN | 2.8                          | 6.4                | 20             |      22   |                   16.4 |        4.8 | 6.2e-05   |      20 |
 | perl -e1 (baseline)         | 2.7                          | 6.2                | 20             |       5.6 |                    0   |       19   | 2.2e-05   |      20 |
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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
