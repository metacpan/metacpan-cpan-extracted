package Bencher::Scenario::PERLANCAR::CommonModulesStartup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of commonly used modules',
    module_startup => 1,
    participants => [
        {module=>'strict'},
        {module=>'warnings'},
        {modules=>['strict', 'warnings']},
        {module=>'utf8'},
        {module=>'Role::Tiny'},
        {module=>'Role::Tiny::With'},
        {modules=>['Role::Tiny', 'Role::Tiny::With']},
        {module=>'List::Util'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of commonly used modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::PERLANCAR::CommonModulesStartup - Benchmark startup overhead of commonly used modules

=head1 VERSION

This document describes version 0.06 of Bencher::Scenario::PERLANCAR::CommonModulesStartup (from Perl distribution Bencher-Scenarios-PERLANCAR), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m PERLANCAR::CommonModulesStartup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<strict> 1.11

L<warnings> 1.36

L<utf8> 1.19

L<Role::Tiny> 2.000003

L<Role::Tiny::With> 2.000003

L<List::Util> 1.45

=head1 BENCHMARK PARTICIPANTS

=over

=item * strict (perl_code)

L<strict>



=item * warnings (perl_code)

L<warnings>



=item * strict+warnings (perl_code)

L<strict+warnings>



=item * utf8 (perl_code)

L<utf8>



=item * Role::Tiny (perl_code)

L<Role::Tiny>



=item * Role::Tiny::With (perl_code)

L<Role::Tiny::With>



=item * Role::Tiny+Role::Tiny::With (perl_code)

L<Role::Tiny+Role::Tiny::With>



=item * List::Util (perl_code)

L<List::Util>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m PERLANCAR::CommonModulesStartup >>):

 #table1#
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Role::Tiny+Role::Tiny::With | 1                            | 4.4                | 18             |     13    |      4.8               |       1    |   6e-05 |      20 |
 | Role::Tiny::With            | 1.3                          | 4.6                | 16             |     13    |      4.8               |       1    | 5.5e-05 |      20 |
 | Role::Tiny                  | 1.3                          | 4.7                | 16             |     13    |      4.8               |       1.1  | 6.5e-05 |      21 |
 | List::Util                  | 0.83                         | 4.1                | 16             |     12    |      3.8               |       1.1  | 5.6e-05 |      20 |
 | strict+warnings             | 0.82                         | 4                  | 16             |     10    |      1.8               |       1.3  | 1.9e-05 |      20 |
 | warnings                    | 0.83                         | 4                  | 16             |     10    |      1.8               |       1.3  | 5.2e-05 |      20 |
 | strict                      | 0.83                         | 4.1                | 16             |      8.7  |      0.5               |       1.5  | 2.1e-05 |      20 |
 | utf8                        | 1.17                         | 4.46               | 16.3           |      8.42 |      0.220000000000001 |       1.59 | 6.7e-06 |      20 |
 | perl -e1 (baseline)         | 0.83                         | 4.1                | 16             |      8.2  |      0                 |       1.6  | 2.1e-05 |      20 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PERLANCAR>

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
