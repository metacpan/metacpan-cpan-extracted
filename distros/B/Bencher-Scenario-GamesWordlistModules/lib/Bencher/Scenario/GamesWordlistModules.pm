package Bencher::Scenario::GamesWordlistModules;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of Games::Word::Wordlist::* modules',
    module_startup => 1,
    participants => [
        {module=>'Games::Word::Wordlist::Country'},
        {module=>'Games::Word::Wordlist::CountrySingleWord'},
        {module=>'Games::Word::Wordlist::Enable'},
        {module=>'Games::Word::Wordlist::KBBI'},
        {module=>'Games::Word::Wordlist::SGB'},
        {module=>'Games::Word::Phraselist::Proverb::KBBI'},
        {module=>'Games::Word::Phraselist::Proverb::TWW'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of Games::Word::Wordlist::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::GamesWordlistModules - Benchmark startup overhead of Games::Word::Wordlist::* modules

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::GamesWordlistModules (from Perl distribution Bencher-Scenario-GamesWordlistModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m GamesWordlistModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Games::Word::Wordlist::Country> 0.04

L<Games::Word::Wordlist::CountrySingleWord> 0.04

L<Games::Word::Wordlist::Enable> 2010090401

L<Games::Word::Wordlist::KBBI> 0.03

L<Games::Word::Wordlist::SGB> 2010091501

L<Games::Word::Phraselist::Proverb::KBBI> 0.05

L<Games::Word::Phraselist::Proverb::TWW> 0.03

=head1 BENCHMARK PARTICIPANTS

=over

=item * Games::Word::Wordlist::Country (perl_code)

L<Games::Word::Wordlist::Country>



=item * Games::Word::Wordlist::CountrySingleWord (perl_code)

L<Games::Word::Wordlist::CountrySingleWord>



=item * Games::Word::Wordlist::Enable (perl_code)

L<Games::Word::Wordlist::Enable>



=item * Games::Word::Wordlist::KBBI (perl_code)

L<Games::Word::Wordlist::KBBI>



=item * Games::Word::Wordlist::SGB (perl_code)

L<Games::Word::Wordlist::SGB>



=item * Games::Word::Phraselist::Proverb::KBBI (perl_code)

L<Games::Word::Phraselist::Proverb::KBBI>



=item * Games::Word::Phraselist::Proverb::TWW (perl_code)

L<Games::Word::Phraselist::Proverb::TWW>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m GamesWordlistModules >>):

 #table1#
 +------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                              | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | Games::Word::Phraselist::Proverb::TWW    | 0.82                         | 4.1                | 16             |      31   |                   26.1 |       1    | 3.1e-05 |      20 |
 | Games::Word::Phraselist::Proverb::KBBI   | 4.1                          | 7.7                | 25             |      30   |                   25.1 |       1    | 4.2e-05 |      20 |
 | Games::Word::Wordlist::Country           | 4.1                          | 7.6                | 25             |      30   |                   25.1 |       1    | 3.5e-05 |      20 |
 | Games::Word::Wordlist::KBBI              | 4.01                         | 7.52               | 25.2           |      30.3 |                   25.4 |       1.01 |   3e-05 |      20 |
 | Games::Word::Wordlist::CountrySingleWord | 4                            | 7.5                | 25             |      30   |                   25.1 |       1    | 4.4e-05 |      20 |
 | Games::Word::Wordlist::SGB               | 4.1                          | 7.6                | 25             |      30   |                   25.1 |       1    | 8.7e-05 |      21 |
 | Games::Word::Wordlist::Enable            | 4.1                          | 7.58               | 25.4           |      29.4 |                   24.5 |       1.04 | 1.7e-05 |      20 |
 | perl -e1 (baseline)                      | 4.1                          | 7.6                | 25             |       4.9 |                    0   |       6.2  | 7.6e-06 |      20 |
 +------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-GamesWordlistModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-GamesWordlistModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-GamesWordlistModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::WordListModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
