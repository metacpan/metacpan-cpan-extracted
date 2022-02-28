package Bencher::Scenario::ArrayData::Word::ID::KBBI::startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'Bencher-Scenarios-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark startup of ArrayData::Word::ID::KBBI vs WordList::ID::KBBI',
    module_startup => 1,
    modules => {
    },
    participants => [
        {module=>'ArrayData::Word::ID::KBBI'},
        {module=>'WordList::ID::KBBI'},
    ],
};

1;
# ABSTRACT: Benchmark startup of ArrayData::Word::ID::KBBI vs WordList::ID::KBBI

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArrayData::Word::ID::KBBI::startup - Benchmark startup of ArrayData::Word::ID::KBBI vs WordList::ID::KBBI

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ArrayData::Word::ID::KBBI::startup (from Perl distribution Bencher-Scenarios-ArrayData), released on 2022-02-05.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArrayData::Word::ID::KBBI::startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<ArrayData::Word::ID::KBBI> 0.004

L<WordList::ID::KBBI> 0.050

=head1 BENCHMARK PARTICIPANTS

=over

=item * ArrayData::Word::ID::KBBI (perl_code)

L<ArrayData::Word::ID::KBBI>



=item * WordList::ID::KBBI (perl_code)

L<WordList::ID::KBBI>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m ArrayData::Word::ID::KBBI::startup --multimodver Array::Set >>:

 #table1#
 {dataset=>undef}
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | ArrayData::Word::ID::KBBI |     10.3  |              8.5  |                 0.00% |               469.86% | 8.3e-06 |      20 |
 | WordList::ID::KBBI        |      8.25 |              6.45 |                24.40% |               358.07% |   6e-06 |      21 |
 | perl -e1 (baseline)       |      1.8  |              0    |               469.86% |                 0.00% | 4.1e-06 |      23 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  AWI:K  WI:K  perl -e1 (baseline) 
  AWI:K                 97.1/s     --  -19%                 -82% 
  WI:K                 121.2/s    24%    --                 -78% 
  perl -e1 (baseline)  555.6/s   472%  358%                   -- 
 
 Legends:
   AWI:K: mod_overhead_time=8.5 participant=ArrayData::Word::ID::KBBI
   WI:K: mod_overhead_time=6.45 participant=WordList::ID::KBBI
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

The startup overhead is fairly close. L<WordList> modules used to have
significantly smaller overhead before the use of roles. But L<Role::Tiny>'s
overhead is still tiny (~2-3ms on my laptop) so startup overhead should not be
an issue in most cases.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-ArrayData>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
