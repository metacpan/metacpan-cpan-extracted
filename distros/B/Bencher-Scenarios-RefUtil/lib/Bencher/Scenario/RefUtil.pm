package Bencher::Scenario::RefUtil;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Ref::Util',
    precision => 0.001,
    participants => [
        {
            name=>'is_arrayref',
            module => 'Ref::Util',
            code_template => 'no warnings "void"; state $ref = []; Ref::Util::is_arrayref($ref) for 1..1000',
        },
        {
            name=>'is_plain_arrayref',
            module => 'Ref::Util',
            code_template => 'no warnings "void"; state $ref = []; Ref::Util::is_plain_arrayref($ref) for 1..1000',
        },
        {
            name=>'ref(ARRAY)',
            code_template => 'no warnings "void"; state $ref = []; ref($ref) eq "ARRAY" for 1..1000',
        },
        {
            name=>'reftype(ARRAY)',
            module => 'Scalar::Util',
            code_template => 'no warnings "void"; state $ref = []; Scalar::Util::reftype($ref) eq "ARRAY" for 1..1000',
        },
    ],
};

1;
# ABSTRACT: Benchmark Ref::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RefUtil - Benchmark Ref::Util

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::RefUtil (from Perl distribution Bencher-Scenarios-RefUtil), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RefUtil

To run module startup overhead benchmark:

 % bencher --module-startup -m RefUtil

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Ref::Util> 0.101

L<Scalar::Util> 1.45

=head1 BENCHMARK PARTICIPANTS

=over

=item * is_arrayref (perl_code)

Code template:

 no warnings "void"; state $ref = []; Ref::Util::is_arrayref($ref) for 1..1000



=item * is_plain_arrayref (perl_code)

Code template:

 no warnings "void"; state $ref = []; Ref::Util::is_plain_arrayref($ref) for 1..1000



=item * ref(ARRAY) (perl_code)

Code template:

 no warnings "void"; state $ref = []; ref($ref) eq "ARRAY" for 1..1000



=item * reftype(ARRAY) (perl_code)

Code template:

 no warnings "void"; state $ref = []; Scalar::Util::reftype($ref) eq "ARRAY" for 1..1000



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RefUtil >>):

 #table1#
 +-------------------+-----------+-----------+------------+---------+---------+
 | participant       | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-------------------+-----------+-----------+------------+---------+---------+
 | reftype(ARRAY)    |   11900   |   83.8    |    1       | 2.7e-08 |      20 |
 | is_plain_arrayref |   20542.3 |   48.6801 |    1.72185 |   0     |      22 |
 | ref(ARRAY)        |   21000   |   47.5    |    1.76    | 1.3e-08 |      20 |
 | is_arrayref       |   21195.9 |   47.1789 |    1.77664 | 2.7e-11 |      20 |
 +-------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m RefUtil --module-startup >>):

 #table2#
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant         | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Scalar::Util        | 844                          | 4.17               | 16             |      9.14 |                   4.14 |       1    | 8.8e-06 |    1016 |
 | Ref::Util           | 1016                         | 4.36               | 18.1           |      8.7  |                   3.7  |       1.05 | 8.5e-06 |     836 |
 | perl -e1 (baseline) | 1016                         | 4.37               | 18.1           |      5    |                   0    |       1.83 | 4.8e-06 |     290 |
 +---------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

I'm not seeing significant performance difference between C<ref() eq "ARRAY">
and C<is_arrayref()> on my perls. Am I doing something wrong?

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RefUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RefUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RefUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
