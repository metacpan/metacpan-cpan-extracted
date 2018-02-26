package Bencher::Scenario::CryptDicewareWordlistModules;

our $DATE = '2018-02-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

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

Bencher::Scenario::CryptDicewareWordlistModules - Benchmark startup overhead of Crypt::Diceware::Wordlist::* modules

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::CryptDicewareWordlistModules (from Perl distribution Bencher-Scenario-CryptDicewareWordlistModules), released on 2018-02-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m CryptDicewareWordlistModules

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

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m CryptDicewareWordlistModules >>):

 #table1#
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                         | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | Crypt::Diceware::Wordlist::Common   | 2                            | 6                  | 20             |        10 |                      4 |        1   |   0.00017 |      20 |
 | Crypt::Diceware::Wordlist::Original | 0.82                         | 4                  | 16             |        12 |                      6 |        1   | 7.8e-05   |      20 |
 | Crypt::Diceware::Wordlist::Beale    | 2.3                          | 5.7                | 18             |        11 |                      5 |        1.1 | 5.1e-05   |      20 |
 | perl -e1 (baseline)                 | 2.3                          | 5.7                | 18             |         6 |                      0 |        2.1 | 2.3e-05   |      20 |
 +-------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-CryptDicewareWordlistModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-CryptDicewareWordlistModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-CryptDicewareWordlistModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::WordListModules>

L<Bencher::Scenario::GamesWordlistModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
