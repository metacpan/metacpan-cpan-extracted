package Bencher::Scenario::ArrayData::Word::ID::KBBI::has_item;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'Bencher-Scenarios-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark checking if word exists',
    participants => [
        {name=>'ArrayData::Word::ID::KBBI-has_item'  , module=>'ArrayData::Word::ID::KBBI', code_template=>'my $ary = ArrayData::Word::ID::KBBI->new; for(1..3) { $ary->has_item   ("zebra"); $ary->has_item   ("nama"); $ary->has_item   ("foo") }'},
        {name=>'WordList::ID::KBBI-word_exists'      , module=>'WordList::ID::KBBI'       , code_template=>'my $wl  = WordList::ID::KBBI->new;        for(1..3) { $wl ->word_exists("zebra"); $wl ->word_exists("nama"); $wl ->word_exists("foo") }'},
    ],
};

1;
# ABSTRACT: Benchmark checking if word exists

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArrayData::Word::ID::KBBI::has_item - Benchmark checking if word exists

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ArrayData::Word::ID::KBBI::has_item (from Perl distribution Bencher-Scenarios-ArrayData), released on 2022-02-05.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArrayData::Word::ID::KBBI::has_item

To run module startup overhead benchmark:

 % bencher --module-startup -m ArrayData::Word::ID::KBBI::has_item

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<ArrayData::Word::ID::KBBI> 0.004

L<WordList::ID::KBBI> 0.050

=head1 BENCHMARK PARTICIPANTS

=over

=item * ArrayData::Word::ID::KBBI-has_item (perl_code)

Code template:

 my $ary = ArrayData::Word::ID::KBBI->new; for(1..3) { $ary->has_item   ("zebra"); $ary->has_item   ("nama"); $ary->has_item   ("foo") }



=item * WordList::ID::KBBI-word_exists (perl_code)

Code template:

 my $wl  = WordList::ID::KBBI->new;        for(1..3) { $wl ->word_exists("zebra"); $wl ->word_exists("nama"); $wl ->word_exists("foo") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m ArrayData::Word::ID::KBBI::has_item --multimodver Array::Set >>:

 #table1#
 {dataset=>undef}
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                        | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | ArrayData::Word::ID::KBBI-has_item |       620 |       1.6 |                 0.00% |                14.52% | 2.3e-06 |      27 |
 | WordList::ID::KBBI-word_exists     |       700 |       1   |                14.52% |                 0.00% | 7.1e-05 |     142 |
 +------------------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

        Rate  A_i   W_e 
  A_i  620/s   --  -37% 
  W_e  700/s  60%    -- 
 
 Legends:
   A_i: participant=ArrayData::Word::ID::KBBI-has_item
   W_e: participant=WordList::ID::KBBI-word_exists


Benchmark module startup overhead (C<< bencher -m ArrayData::Word::ID::KBBI::has_item --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | ArrayData::Word::ID::KBBI |     14.2  |              8.31 |                 0.00% |               141.67% | 7.4e-06 |      21 |
 | WordList::ID::KBBI        |     12.2  |              6.31 |                16.71% |               107.07% | 7.1e-06 |      20 |
 | perl -e1 (baseline)       |      5.89 |              0    |               141.67% |                 0.00% | 4.3e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  AWI:K  WI:K  perl -e1 (baseline) 
  AWI:K                 70.4/s     --  -14%                 -58% 
  WI:K                  82.0/s    16%    --                 -51% 
  perl -e1 (baseline)  169.8/s   141%  107%                   -- 
 
 Legends:
   AWI:K: mod_overhead_time=8.31 participant=ArrayData::Word::ID::KBBI
   WI:K: mod_overhead_time=6.31 participant=WordList::ID::KBBI
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 BENCHMARK NOTES

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
