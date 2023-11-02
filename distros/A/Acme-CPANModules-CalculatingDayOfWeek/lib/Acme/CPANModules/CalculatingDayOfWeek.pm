package Acme::CPANModules::CalculatingDayOfWeek;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-CalculatingDayOfWeek'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to calculate day of week',
    entries => [
        {
            module => 'Date::DayOfWeek',
            bench_fcall_template => 'Date::DayOfWeek::dayofweek(<day>, <month>, <year>)',
            description => <<'_',

Both <pm:Date::DayOfWeek> and <pm:Time::DayOfWeek> are lightweight modules.

_
        },
        {
            module => 'Time::DayOfWeek',
            bench_fcall_template => 'Time::DayOfWeek::DoW(<year>, <month>, <day>)',
            description => <<'_',

Both <pm:Date::DayOfWeek> and <pm:Time::DayOfWeek> are lightweight modules.

This module offers cryptic and confusing function names: `DoW` returns 0-6,
`Dow` returns 3-letter abbrev.

_
        },
        {
            module => 'DateTime',
            bench_code_template => 'DateTime->new(year=><year>, month=><month>, day=><day>)->day_of_week',
            description => <<'_',

Compared to <pm:Date::DayOfWeek> and <pm:Time::DayOfWeek>, <pm:DateTime> is a
behemoth. But it provides a bunch of other functionalities as well.

_
        },
        {
            module => 'Date::Calc',
            bench_fcall_template => 'Date::Calc::Day_of_Week(<year>, <month>, <day>)',
            description => <<'_',

<pm:Date::Calc> is a nice compromise when you want something that is more
lightweight and does not need to be as accurate as <pm:DateTime>.

_
        },
        {
            module => 'Time::Moment',
            bench_code_template => 'Time::Moment->new(year => <year>, month => <month>, day => <day>)->day_of_week',
            description => <<'_',

<pm:Time::Moment> is also a nice alternative to <pm:DateTime>. Although it's not
as featureful as DateTime, it is significantly more lightweight. Compared to
<pm:Date::Calc>, Time::Moment's API is closer to DateTime's. Being an XS module,
it's also faster.

_
        },
    ],

    bench_datasets => [
        {name=>'date1', args => {day=>20, month=>11, year=>2019}},
    ],

};

1;
# ABSTRACT: List of modules to calculate day of week

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CalculatingDayOfWeek - List of modules to calculate day of week

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CalculatingDayOfWeek (from Perl distribution Acme-CPANModules-CalculatingDayOfWeek), released on 2023-08-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module CalculatingDayOfWeek

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module CalculatingDayOfWeek

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Date::DayOfWeek>

Author: L<RBOW|https://metacpan.org/author/RBOW>

Both L<Date::DayOfWeek> and L<Time::DayOfWeek> are lightweight modules.


=item L<Time::DayOfWeek>

Author: L<PIP|https://metacpan.org/author/PIP>

Both L<Date::DayOfWeek> and L<Time::DayOfWeek> are lightweight modules.

This module offers cryptic and confusing function names: C<DoW> returns 0-6,
C<Dow> returns 3-letter abbrev.


=item L<DateTime>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

Compared to L<Date::DayOfWeek> and L<Time::DayOfWeek>, L<DateTime> is a
behemoth. But it provides a bunch of other functionalities as well.


=item L<Date::Calc>

Author: L<STBEY|https://metacpan.org/author/STBEY>

L<Date::Calc> is a nice compromise when you want something that is more
lightweight and does not need to be as accurate as L<DateTime>.


=item L<Time::Moment>

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

L<Time::Moment> is also a nice alternative to L<DateTime>. Although it's not
as featureful as DateTime, it is significantly more lightweight. Compared to
L<Date::Calc>, Time::Moment's API is closer to DateTime's. Being an XS module,
it's also faster.


=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::DayOfWeek> 1.22

L<Time::DayOfWeek> 1.8

L<DateTime> 1.59

L<Date::Calc> 6.4

L<Time::Moment> 0.44

=head1 BENCHMARK PARTICIPANTS

=over

=item * Date::DayOfWeek::dayofweek (perl_code)

Function call template:

 Date::DayOfWeek::dayofweek(<day>, <month>, <year>)



=item * Time::DayOfWeek::DoW (perl_code)

Function call template:

 Time::DayOfWeek::DoW(<year>, <month>, <day>)



=item * DateTime (perl_code)

Code template:

 DateTime->new(year=><year>, month=><month>, day=><day>)->day_of_week



=item * Date::Calc::Day_of_Week (perl_code)

Function call template:

 Date::Calc::Day_of_Week(<year>, <month>, <day>)



=item * Time::Moment (perl_code)

Code template:

 Time::Moment->new(year => <year>, month => <month>, day => <day>)->day_of_week



=back

=head1 BENCHMARK DATASETS

=over

=item * date1

=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark command (default options):

 % bencher --cpanmodules-module CalculatingDayOfWeek

Result formatted as table:

 #table1#
 {dataset=>"date1"}
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant                | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | DateTime                   |     37000 |    27     |                 0.00% |              8030.29% | 3.8e-08 |      24 |
 | Date::DayOfWeek::dayofweek |    562000 |     1.78  |              1415.39% |               436.51% | 3.8e-10 |      20 |
 | Date::Calc::Day_of_Week    |    650000 |     1.54  |              1650.85% |               364.36% | 9.3e-10 |      20 |
 | Time::DayOfWeek::DoW       |   1030000 |     0.97  |              2677.36% |               192.73% | 6.3e-10 |      20 |
 | Time::Moment               |   3020000 |     0.331 |              8030.29% |                 0.00% | 1.7e-10 |      20 |
 +----------------------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

The above result formatted in L<Benchmark.pm|Benchmark> style:

                 Rate      D  DD:d  DC:D_o_W  TD:D   T:M 
  D           37000/s     --  -93%      -94%  -96%  -98% 
  DD:d       562000/s  1416%    --      -13%  -45%  -81% 
  DC:D_o_W   650000/s  1653%   15%        --  -37%  -78% 
  TD:D      1030000/s  2683%   83%       58%    --  -65% 
  T:M       3020000/s  8057%  437%      365%  193%    -- 
 
 Legends:
   D: participant=DateTime
   DC:D_o_W: participant=Date::Calc::Day_of_Week
   DD:d: participant=Date::DayOfWeek::dayofweek
   T:M: participant=Time::Moment
   TD:D: participant=Time::DayOfWeek::DoW


=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher --cpanmodules-module CalculatingDayOfWeek --module-startup

Result formatted as table:

 #table2#
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant         | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | DateTime            |    145    |            139.2  |                 0.00% |              2398.83% | 3.7e-05 |      20 |
 | Date::Calc          |     24.9  |             19.1  |               483.22% |               328.45% | 1.2e-05 |      21 |
 | Time::Moment        |     12.2  |              6.4  |              1086.86% |               110.54% | 8.3e-06 |      20 |
 | Time::DayOfWeek     |      9.8  |              4    |              1380.99% |                68.73% | 5.7e-06 |      20 |
 | Date::DayOfWeek     |      9.34 |              3.54 |              1453.50% |                60.85% |   5e-06 |      20 |
 | perl -e1 (baseline) |      5.8  |              0    |              2398.83% |                 0.00% | 6.4e-06 |      20 |
 +---------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate      D   D:C   T:M   T:D   D:D  perl -e1 (baseline) 
  D                      6.9/s     --  -82%  -91%  -93%  -93%                 -96% 
  D:C                   40.2/s   482%    --  -51%  -60%  -62%                 -76% 
  T:M                   82.0/s  1088%  104%    --  -19%  -23%                 -52% 
  T:D                  102.0/s  1379%  154%   24%    --   -4%                 -40% 
  D:D                  107.1/s  1452%  166%   30%    4%    --                 -37% 
  perl -e1 (baseline)  172.4/s  2400%  329%  110%   68%   61%                   -- 
 
 Legends:
   D: mod_overhead_time=139.2 participant=DateTime
   D:C: mod_overhead_time=19.1 participant=Date::Calc
   D:D: mod_overhead_time=3.54 participant=Date::DayOfWeek
   T:D: mod_overhead_time=4 participant=Time::DayOfWeek
   T:M: mod_overhead_time=6.4 participant=Time::Moment
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n CalculatingDayOfWeek

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CalculatingDayOfWeek | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CalculatingDayOfWeek -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CalculatingDayOfWeek -E'say $_->{module} for @{ $Acme::CPANModules::CalculatingDayOfWeek::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module CalculatingDayOfWeek

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CalculatingDayOfWeek>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CalculatingDayOfWeek>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CalculatingDayOfWeek>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
