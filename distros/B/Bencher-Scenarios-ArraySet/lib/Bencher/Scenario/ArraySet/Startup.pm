package Bencher::Scenario::ArraySet::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup of Array::Set',
    module_startup => 1,
    modules => {
    },
    participants => [
        {module=>'Array::Set'},
        {module=>'Set::Object'},
        {module=>'Set::Scalar'},
    ],
};

1;
# ABSTRACT: Benchmark startup of Array::Set

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArraySet::Startup - Benchmark startup of Array::Set

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::ArraySet::Startup (from Perl distribution Bencher-Scenarios-ArraySet), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArraySet::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Array::Set> 0.05

L<Set::Object> 1.35

L<Set::Scalar> 1.29

=head1 BENCHMARK PARTICIPANTS

=over

=item * Array::Set (perl_code)

L<Array::Set>



=item * Set::Object (perl_code)

L<Set::Object>



=item * Set::Scalar (perl_code)

L<Set::Scalar>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with C<< bencher -m ArraySet::Startup --include-path archive/Array-Set-0.02/lib --include-path archive/Array-Set-0.05/lib --multimodver Array::Set >>:

 #table1#
 {dataset=>undef}
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+---------+---------+
 | proc_private_dirty_size | proc_rss_size | proc_size | participant         | modver | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+---------+---------+
 | 1.9                     | 5.2           | 19        | Set::Object         |        |      14   |                   12   |        1   | 1.5e-05 |      20 |
 | 0.83                    | 4.1           | 16        | Set::Scalar         |        |      13   |                   11   |        1.1 | 4.1e-05 |      21 |
 | 2.2                     | 5.7           | 19        | Array::Set          | 0.02   |      10   |                    8   |        1.4 | 3.3e-05 |      20 |
 | 2.2                     | 5.5           | 19        | Array::Set          | 0.05   |       5.4 |                    3.4 |        2.5 | 1.7e-05 |      20 |
 | 1.1                     | 4.3           | 16        | perl -e1 (baseline) |        |       2   |                    0   |        6.9 | 1.3e-05 |      20 |
 +-------------------------+---------------+-----------+---------------------+--------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArraySet>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArraySet>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArraySet>

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
