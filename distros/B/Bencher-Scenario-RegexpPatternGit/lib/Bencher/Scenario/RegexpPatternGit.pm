package Bencher::Scenario::RegexpPatternGit;

our $DATE = '2019-10-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark Regexp::Pattern::Git',
    modules => {
        # minimum versions
        #'Foo' => {version=>'0.31'},
        'Regexp::Pattern' => {},
        'Regexp::Pattern::Git' => {},
    },
    participants => [
        {
            name => 'ref',
            code_template => 'use Regexp::Pattern; state $re = re("Git::ref"); <data> =~ $re',
        },
    ],

    datasets => [
        {args => {data=>'.one'}},
        {args => {data=>'one/two'}},
        {args => {data=>'one/two/three/four/five/six'}},
    ],
};

1;
# ABSTRACT: Benchmark Regexp::Pattern::Git

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpPatternGit - Benchmark Regexp::Pattern::Git

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::RegexpPatternGit (from Perl distribution Bencher-Scenario-RegexpPatternGit), released on 2019-10-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpPatternGit

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Pattern> 0.2.9

L<Regexp::Pattern::Git> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * ref (perl_code)

Code template:

 use Regexp::Pattern; state $re = re("Git::ref"); <data> =~ $re



=back

=head1 BENCHMARK DATASETS

=over

=item * .one

=item * one/two

=item * one/two/three/four/five/six

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m RegexpPatternGit >>):

 #table1#
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | dataset                     | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | one/two/three/four/five/six |    460000 |      2.2  |        1   | 3.3e-09 |      20 |
 | one/two                     |    900000 |      1.1  |        2   | 1.6e-09 |      23 |
 | .one                        |   3600000 |      0.28 |        7.7 | 1.4e-09 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-RegexpPatternGit>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpPatternGit>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-RegexpPatternGit>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
