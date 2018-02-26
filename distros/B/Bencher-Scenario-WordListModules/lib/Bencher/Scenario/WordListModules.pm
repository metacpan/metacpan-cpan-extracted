package Bencher::Scenario::WordListModules;

our $DATE = '2018-02-20'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark startup overhead of WordList::* modules',
    module_startup => 1,
    default_precision => 0.005,
    participants => [
        {module=>'WordList::EN::CountryNames'},
        {module=>'WordList::EN::CountryNames::SingleWord'},
        {module=>'WordList::EN::Enable'},
        {module=>'WordList::EN::SGB'},
        {module=>'WordList::ID::KBBI'},
        {module=>'WordList::Phrase::EN::Proverb::TWW'},
        {module=>'WordList::Phrase::ID::Proverb::KBBI'},

        {module=>'WordListC::Password::10Million::Top100000'},
        {module=>'WordListC::Password::10Million::Top1000000'},
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of WordList::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::WordListModules - Benchmark startup overhead of WordList::* modules

=head1 VERSION

This document describes version 0.051 of Bencher::Scenario::WordListModules (from Perl distribution Bencher-Scenario-WordListModules), released on 2018-02-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m WordListModules

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<WordList::EN::CountryNames> 0.04

L<WordList::EN::CountryNames::SingleWord> 0.04

L<WordList::EN::Enable> 0.03

L<WordList::EN::SGB> 0.03

L<WordList::ID::KBBI> 0.04

L<WordList::Phrase::EN::Proverb::TWW> 0.03

L<WordList::Phrase::ID::Proverb::KBBI> 0.03

L<WordListC::Password::10Million::Top100000> 0.001

L<WordListC::Password::10Million::Top1000000> 0.001

=head1 BENCHMARK PARTICIPANTS

=over

=item * WordList::EN::CountryNames (perl_code)

L<WordList::EN::CountryNames>



=item * WordList::EN::CountryNames::SingleWord (perl_code)

L<WordList::EN::CountryNames::SingleWord>



=item * WordList::EN::Enable (perl_code)

L<WordList::EN::Enable>



=item * WordList::EN::SGB (perl_code)

L<WordList::EN::SGB>



=item * WordList::ID::KBBI (perl_code)

L<WordList::ID::KBBI>



=item * WordList::Phrase::EN::Proverb::TWW (perl_code)

L<WordList::Phrase::EN::Proverb::TWW>



=item * WordList::Phrase::ID::Proverb::KBBI (perl_code)

L<WordList::Phrase::ID::Proverb::KBBI>



=item * WordListC::Password::10Million::Top100000 (perl_code)

L<WordListC::Password::10Million::Top100000>



=item * WordListC::Password::10Million::Top1000000 (perl_code)

L<WordListC::Password::10Million::Top1000000>



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m WordListModules >>):

 #table1#
 +--------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | participant                                | proc_private_dirty_size (kB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +--------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+
 | WordList::EN::Enable                       | 944                          | 4.3                | 16             |       7.1 |      1                 |        1   | 2.8e-05 |      20 |
 | WordList::Phrase::ID::Proverb::KBBI        | 920                          | 4.3                | 16             |       7.1 |      1                 |        1   | 3.4e-05 |      25 |
 | WordList::EN::SGB                          | 948                          | 4.4                | 16             |       7.1 |      1                 |        1   | 3.3e-05 |      24 |
 | WordList::EN::CountryNames::SingleWord     | 952                          | 4.3                | 16             |       7   |      0.9               |        1   | 1.3e-05 |      20 |
 | WordList::ID::KBBI                         | 948                          | 4.2                | 16             |       7   |      0.9               |        1   | 2.4e-05 |      20 |
 | WordList::Phrase::EN::Proverb::TWW         | 948                          | 4.3                | 16             |       7   |      0.9               |        1   |   3e-05 |      20 |
 | WordList::EN::CountryNames                 | 948                          | 4.3                | 16             |       6.9 |      0.800000000000001 |        1   | 1.8e-05 |      20 |
 | WordListC::Password::10Million::Top100000  | 920                          | 4.2                | 16             |       6.9 |      0.800000000000001 |        1   | 2.8e-05 |      21 |
 | WordListC::Password::10Million::Top1000000 | 844                          | 4.2                | 16             |       6.9 |      0.800000000000001 |        1   | 3.4e-05 |      27 |
 | perl -e1 (baseline)                        | 948                          | 4.3                | 16             |       6.1 |      0                 |        1.2 | 2.8e-05 |      20 |
 +--------------------------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-WordListModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-WordListModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-WordListModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Bencher::Scenario::GamesWordlistModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
