package Acme::CPANModules::CalculatingDayOfWeek;

our $DATE = '2019-11-20'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our $LIST = {
    summary => 'Modules to calculate day of week',
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
# ABSTRACT: Modules to calculate day of week

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CalculatingDayOfWeek - Modules to calculate day of week

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CalculatingDayOfWeek (from Perl distribution Acme-CPANModules-CalculatingDayOfWeek), released on 2019-11-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module CalculatingDayOfWeek

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module CalculatingDayOfWeek

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Modules to calculate day of week.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::DayOfWeek> 1.22

L<Time::DayOfWeek> 1.8

L<DateTime> 1.39

L<Date::Calc> 6.4

L<Time::Moment> 0.38

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

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module CalculatingDayOfWeek >>):

 #table1#
 {dataset=>"date1"}
 +----------------------------+-----------+-----------+------------+---------+---------+
 | participant                | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime                   |     44000 | 23        |     1      | 5.3e-08 |      20 |
 | Date::DayOfWeek::dayofweek |    630000 |  1.59     |    14.2    | 7.9e-10 |      22 |
 | Date::Calc::Day_of_Week    |    753000 |  1.33     |    17      | 3.2e-10 |      35 |
 | Time::DayOfWeek::DoW       |   1100000 |  0.89     |    25      | 1.2e-09 |      21 |
 | Time::Moment               |   2974870 |  0.336149 |    67.0065 |   0     |      20 |
 +----------------------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module CalculatingDayOfWeek --module-startup >>):

 #table2#
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | participant         | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +---------------------+-----------+------------------------+------------+-----------+---------+
 | DateTime            |      98   |                   95.3 |        1   |   0.00021 |      21 |
 | Date::Calc          |      17   |                   14.3 |        5.7 | 2.5e-05   |      20 |
 | Time::Moment        |       7   |                    4.3 |       14   | 1.3e-05   |      20 |
 | Time::DayOfWeek     |       5.9 |                    3.2 |       17   | 2.3e-05   |      20 |
 | Date::DayOfWeek     |       5.2 |                    2.5 |       19   | 8.3e-06   |      21 |
 | perl -e1 (baseline) |       2.7 |                    0   |       36   |   7e-06   |      20 |
 +---------------------+-----------+------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 INCLUDED MODULES

=over

=item * L<Date::DayOfWeek>

Both L<Date::DayOfWeek> and L<Time::DayOfWeek> are lightweight modules.


=item * L<Time::DayOfWeek>

Both L<Date::DayOfWeek> and L<Time::DayOfWeek> are lightweight modules.

This module offers cryptic and confusing function names: C<DoW> returns 0-6,
C<Dow> returns 3-letter abbrev.


=item * L<DateTime>

Compared to L<Date::DayOfWeek> and L<Time::DayOfWeek>, L<DateTime> is a
behemoth. But it provides a bunch of other functionalities as well.


=item * L<Date::Calc>

L<Date::Calc> is a nice compromise when you want something that is more
lightweight and does not need to be as accurate as L<DateTime>.


=item * L<Time::Moment>

L<Time::Moment> is also a nice alternative to L<DateTime>. Although it's not
as featureful as DateTime, it is significantly more lightweight. Compared to
L<Date::Calc>, Time::Moment's API is closer to DateTime's. Being an XS module,
it's also faster.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CalculatingDayOfWeek>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CalculatingDayOfWeek>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CalculatingDayOfWeek>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
