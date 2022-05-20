package Bencher::Scenario::Crypt::Diceware::Wordlist::startup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-19'; # DATE
our $DIST = 'Bencher-Scenarios-Crypt-Diceware-Wordlist'; # DIST
our $VERSION = '0.002'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of Crypt::Diceware::Wordlist::* modules',
    module_startup => 1,
    participants => [
        {module=>'Crypt::Diceware::Wordlist::Beale'},
        {module=>'Crypt::Diceware::Wordlist::Common'},
        {module=>'Crypt::Diceware::Wordlist::Original'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of Crypt::Diceware::Wordlist::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Crypt::Diceware::Wordlist::startup - Benchmark startup overhead of Crypt::Diceware::Wordlist::* modules

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::Crypt::Diceware::Wordlist::startup (from Perl distribution Bencher-Scenarios-Crypt-Diceware-Wordlist), released on 2022-03-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Crypt::Diceware::Wordlist::startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Crypt::Diceware::Wordlist::Beale> 0.005

L<Crypt::Diceware::Wordlist::Common> 0.005

L<Crypt::Diceware::Wordlist::Original> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * Crypt::Diceware::Wordlist::Beale (perl_code)

L<Crypt::Diceware::Wordlist::Beale>



=item * Crypt::Diceware::Wordlist::Common (perl_code)

L<Crypt::Diceware::Wordlist::Common>



=item * Crypt::Diceware::Wordlist::Original (perl_code)

L<Crypt::Diceware::Wordlist::Original>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Crypt::Diceware::Wordlist::startup >>):

 #table1#
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | Crypt::Diceware::Wordlist::Common   |      11   |               5   |                 0.00% |                83.35% | 7.4e-06 |      20 |
 | Crypt::Diceware::Wordlist::Beale    |      11   |               5   |                 0.96% |                81.61% | 1.3e-05 |      20 |
 | Crypt::Diceware::Wordlist::Original |      10.8 |               4.8 |                 1.15% |                81.27% | 7.9e-06 |      20 |
 | perl -e1 (baseline)                 |       6   |               0   |                83.35% |                 0.00% | 7.8e-06 |      20 |
 +-------------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  CDW:C  CDW:B  CDW:O  perl -e1 (baseline) 
  CDW:C                 90.9/s     --     0%    -1%                 -45% 
  CDW:B                 90.9/s     0%     --    -1%                 -45% 
  CDW:O                 92.6/s     1%     1%     --                 -44% 
  perl -e1 (baseline)  166.7/s    83%    83%    80%                   -- 
 
 Legends:
   CDW:B: mod_overhead_time=5 participant=Crypt::Diceware::Wordlist::Beale
   CDW:C: mod_overhead_time=5 participant=Crypt::Diceware::Wordlist::Common
   CDW:O: mod_overhead_time=4.8 participant=Crypt::Diceware::Wordlist::Original
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Crypt-Diceware-Wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CryptDicewareWordlistModules>.

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

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Crypt-Diceware-Wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
