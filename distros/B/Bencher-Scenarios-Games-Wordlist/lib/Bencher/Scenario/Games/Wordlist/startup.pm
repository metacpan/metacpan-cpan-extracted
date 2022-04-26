package Bencher::Scenario::Games::Wordlist::startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-20'; # DATE
our $DIST = 'Bencher-Scenarios-Games-Wordlist'; # DIST
our $VERSION = '0.050'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of Games::Word::Wordlist::* modules',
    module_startup => 1,
    participants => [
        {module=>'Games::Word::Wordlist::Enable'},
        {module=>'Games::Word::Wordlist::SGB'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of Games::Word::Wordlist::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Games::Wordlist::startup - Benchmark startup overhead of Games::Word::Wordlist::* modules

=head1 VERSION

This document describes version 0.050 of Bencher::Scenario::Games::Wordlist::startup (from Perl distribution Bencher-Scenarios-Games-Wordlist), released on 2022-03-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Games::Wordlist::startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Games::Word::Wordlist::Enable> 2010090401

L<Games::Word::Wordlist::SGB> 2010091501

=head1 BENCHMARK PARTICIPANTS

=over

=item * Games::Word::Wordlist::Enable (perl_code)

L<Games::Word::Wordlist::Enable>



=item * Games::Word::Wordlist::SGB (perl_code)

L<Games::Word::Wordlist::SGB>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Games::Wordlist::startup >>):

 #table1#
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                   | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Games::Word::Wordlist::SGB    |      30.6 |              24.7 |                 0.00% |               417.01% | 1.5e-05 |      20 |
 | Games::Word::Wordlist::Enable |      30.6 |              24.7 |                 0.06% |               416.70% | 1.6e-05 |      20 |
 | perl -e1 (baseline)           |       5.9 |               0   |               417.01% |                 0.00% | 7.7e-06 |      22 |
 +-------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  GWW:S  GWW:E  perl -e1 (baseline) 
  GWW:S                 32.7/s     --     0%                 -80% 
  GWW:E                 32.7/s     0%     --                 -80% 
  perl -e1 (baseline)  169.5/s   418%   418%                   -- 
 
 Legends:
   GWW:E: mod_overhead_time=24.7 participant=Games::Word::Wordlist::Enable
   GWW:S: mod_overhead_time=24.7 participant=Games::Word::Wordlist::SGB
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Games-Wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Games-Wordlist>.

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

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Games-Wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
