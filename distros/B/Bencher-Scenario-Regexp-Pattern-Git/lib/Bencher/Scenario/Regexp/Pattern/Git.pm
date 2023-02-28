package Bencher::Scenario::Regexp::Pattern::Git;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-17'; # DATE
our $DIST = 'Bencher-Scenario-Regexp-Pattern-Git'; # DIST
our $VERSION = '0.003'; # VERSION

our $scenario = {
    summary => 'Benchmark patterns in Regexp::Pattern::Git',
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
# ABSTRACT: Benchmark patterns in Regexp::Pattern::Git

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Regexp::Pattern::Git - Benchmark patterns in Regexp::Pattern::Git

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::Regexp::Pattern::Git (from Perl distribution Bencher-Scenario-Regexp-Pattern-Git), released on 2023-01-17.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Regexp::Pattern::Git

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Pattern> 0.2.14

L<Regexp::Pattern::Git> 0.002

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

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Regexp::Pattern::Git >>):

 #table1#
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | dataset                     | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | one/two/three/four/five/six |    536000 |    1.87   |                 0.00% |               593.02% | 7.3e-10 |      26 |
 | one/two                     |    859380 |    1.1636 |                60.40% |               332.05% | 5.8e-12 |      20 |
 | .one                        |   3713000 |    0.2693 |               593.02% |                 0.00% | 5.8e-12 |      20 |
 +-----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                                    Rate  one/two/three/four/five/six  one/two  .one 
  one/two/three/four/five/six   536000/s                           --     -37%  -85% 
  one/two                       859380/s                          60%       --  -76% 
  .one                         3713000/s                         594%     332%    -- 
 
 Legends:
   .one: dataset=.one
   one/two: dataset=one/two
   one/two/three/four/five/six: dataset=one/two/three/four/five/six

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Regexp-Pattern-Git>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-RegexpPatternGit>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Regexp-Pattern-Git>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
