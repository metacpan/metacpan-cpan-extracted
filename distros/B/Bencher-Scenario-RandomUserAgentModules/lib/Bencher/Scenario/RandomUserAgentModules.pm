package Bencher::Scenario::RandomUserAgentModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark modules that produce random HTTP user agent string',
    participants => [
        {
            fcall_template=>'WWW::UserAgent::Random::rand_ua("browsers")',
        },
    ],
};

1;
# ABSTRACT: Benchmark modules that produce random HTTP user agent string

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RandomUserAgentModules - Benchmark modules that produce random HTTP user agent string

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::RandomUserAgentModules (from Perl distribution Bencher-Scenario-RandomUserAgentModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RandomUserAgentModules

To run module startup overhead benchmark:

 % bencher --module-startup -m RandomUserAgentModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<WWW::UserAgent::Random> 0.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * WWW::UserAgent::Random::rand_ua (perl_code)

Function call template:

 WWW::UserAgent::Random::rand_ua("browsers")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RandomUserAgentModules >>):

 #table1#
 +---------------------------------+------+-----------+-----------+------------+---------+---------+
 | participant                     | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +---------------------------------+------+-----------+-----------+------------+---------+---------+
 | WWW::UserAgent::Random::rand_ua | perl |     69000 |        14 |          1 | 4.7e-08 |      26 |
 +---------------------------------+------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m RandomUserAgentModules --module-startup >>):

 #table2#
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant            | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | WWW::UserAgent::Random | 840                          | 4.1                | 16             |       9.9 |                      4 |        1   | 3.6e-05 |      21 |
 | perl -e1 (baseline)    | 1044                         | 4.3                | 16             |       5.9 |                      0 |        1.7 | 3.7e-05 |      20 |
 +------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RandomUserAgentModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RandomUserAgentModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RandomUserAgentModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Modules that are not yet included in this benchmark:
L<Faker::Provider::UserAgent> (dependency cannot be installed and has
compile-time errors).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
