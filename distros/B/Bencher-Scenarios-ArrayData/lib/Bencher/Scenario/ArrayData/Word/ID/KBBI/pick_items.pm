package Bencher::Scenario::ArrayData::Word::ID::KBBI::pick_items;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'Bencher-Scenarios-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark picking words',
    participants => [
        {name=>'ArrayData::Word::ID::KBBI-pick_items-1' , module=>'ArrayData::Word::ID::KBBI', code_template=>'my $ary = ArrayData::Word::ID::KBBI->new;                                                                         $ary->pick_items(n=>1)  for 1..20; my ($w) = $ary->pick_items(n=>1); $w'},
        {name=>'WordList::ID::KBBI-pick-1'              , module=>'WordList::ID::KBBI'       , code_template=>'my $wl  = WordList::ID::KBBI->new;        Role::Tiny->apply_roles_to_object($wl, "WordListRole::RandomSeekPick"); $wl ->pick              for 1..20; my ($w) = $wl->pick; $w'},
        {name=>'ArrayData::Word::ID::KBBI-pick_items-10', module=>'ArrayData::Word::ID::KBBI', code_template=>'my $ary = ArrayData::Word::ID::KBBI->new;                                                                         $ary->pick_items(n=>10) for 1..20; my @w = $ary->pick_items(n=>10); \@w'},
        {name=>'WordList::ID::KBBI-pick-10'             , module=>'WordList::ID::KBBI'       , code_template=>'my $wl  = WordList::ID::KBBI->new;        Role::Tiny->apply_roles_to_object($wl, "WordListRole::RandomSeekPick"); $wl ->pick      (10)    for 1..20; my @w = $wl->pick(10); \@w'},
    ],
};

1;
# ABSTRACT: Benchmark picking words

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::ArrayData::Word::ID::KBBI::pick_items - Benchmark picking words

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::ArrayData::Word::ID::KBBI::pick_items (from Perl distribution Bencher-Scenarios-ArrayData), released on 2022-02-05.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m ArrayData::Word::ID::KBBI::pick_items

To run module startup overhead benchmark:

 % bencher --module-startup -m ArrayData::Word::ID::KBBI::pick_items

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<ArrayData::Word::ID::KBBI> 0.004

L<WordList::ID::KBBI> 0.050

=head1 BENCHMARK PARTICIPANTS

=over

=item * ArrayData::Word::ID::KBBI-pick_items-1 (perl_code)

Code template:

 my $ary = ArrayData::Word::ID::KBBI->new;                                                                         $ary->pick_items(n=>1)  for 1..20; my ($w) = $ary->pick_items(n=>1); $w



=item * WordList::ID::KBBI-pick-1 (perl_code)

Code template:

 my $wl  = WordList::ID::KBBI->new;        Role::Tiny->apply_roles_to_object($wl, "WordListRole::RandomSeekPick"); $wl ->pick              for 1..20; my ($w) = $wl->pick; $w



=item * ArrayData::Word::ID::KBBI-pick_items-10 (perl_code)

Code template:

 my $ary = ArrayData::Word::ID::KBBI->new;                                                                         $ary->pick_items(n=>10) for 1..20; my @w = $ary->pick_items(n=>10); \@w



=item * WordList::ID::KBBI-pick-10 (perl_code)

Code template:

 my $wl  = WordList::ID::KBBI->new;        Role::Tiny->apply_roles_to_object($wl, "WordListRole::RandomSeekPick"); $wl ->pick      (10)    for 1..20; my @w = $wl->pick(10); \@w



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with C<< bencher -m ArrayData::Word::ID::KBBI::pick_items --multimodver Array::Set >>:

 #table1#
 {dataset=>undef}
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                             | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | WordList::ID::KBBI-pick-10              |        30 |   30      |                 0.00% |             54560.69% |   0.00051 |      20 |
 | WordList::ID::KBBI-pick-1               |       700 |    2      |              2081.05% |              2406.16% | 7.5e-05   |      69 |
 | ArrayData::Word::ID::KBBI-pick_items-10 |     16600 |    0.0601 |             54523.94% |                 0.07% | 2.5e-08   |      23 |
 | ArrayData::Word::ID::KBBI-pick_items-1  |     17000 |    0.06   |             54560.69% |                 0.00% | 1.1e-07   |      20 |
 +-----------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

                                              Rate  WordList::ID::KBBI-pick-10  WordList::ID::KBBI-pick-1  ArrayData::Word::ID::KBBI-pick_items-10  ArrayData::Word::ID::KBBI-pick_items-1 
  WordList::ID::KBBI-pick-10                  30/s                          --                       -93%                                     -99%                                    -99% 
  WordList::ID::KBBI-pick-1                  700/s                       1400%                         --                                     -96%                                    -97% 
  ArrayData::Word::ID::KBBI-pick_items-10  16600/s                      49816%                      3227%                                       --                                      0% 
  ArrayData::Word::ID::KBBI-pick_items-1   17000/s                      49900%                      3233%                                       0%                                      -- 
 
 Legends:
   ArrayData::Word::ID::KBBI-pick_items-1: participant=ArrayData::Word::ID::KBBI-pick_items-1
   ArrayData::Word::ID::KBBI-pick_items-10: participant=ArrayData::Word::ID::KBBI-pick_items-10
   WordList::ID::KBBI-pick-1: participant=WordList::ID::KBBI-pick-1
   WordList::ID::KBBI-pick-10: participant=WordList::ID::KBBI-pick-10


Benchmark module startup overhead (C<< bencher -m ArrayData::Word::ID::KBBI::pick_items --module-startup >>):

 #table2#
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant               | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | ArrayData::Word::ID::KBBI |     14.3  |              8.37 |                 0.00% |               140.77% | 9.6e-06 |      20 |
 | WordList::ID::KBBI        |     12.2  |              6.27 |                16.67% |               106.38% | 4.2e-06 |      21 |
 | perl -e1 (baseline)       |      5.93 |              0    |               140.77% |                 0.00% | 2.7e-06 |      20 |
 +---------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  AWI:K  WI:K  perl -e1 (baseline) 
  AWI:K                 69.9/s     --  -14%                 -58% 
  WI:K                  82.0/s    17%    --                 -51% 
  perl -e1 (baseline)  168.6/s   141%  105%                   -- 
 
 Legends:
   AWI:K: mod_overhead_time=8.37 participant=ArrayData::Word::ID::KBBI
   WI:K: mod_overhead_time=6.27 participant=WordList::ID::KBBI
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
