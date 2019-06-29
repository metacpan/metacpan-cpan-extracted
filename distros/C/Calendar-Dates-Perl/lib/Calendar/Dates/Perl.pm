package Calendar::Dates::Perl;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple';
with 'Calendar::DatesRoles::DataUser::CalendarVar';

1;
# ABSTRACT: Dates/anniversaries related to Perl

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::Perl - Dates/anniversaries related to Perl

=head1 VERSION

This document describes version 0.001 of Calendar::Dates::Perl (from Perl distribution Calendar-Dates-Perl), released on 2019-06-19.

=head1 SYNOPSIS

=head2 Using from Perl

 use Calendar::Dates::Perl;
 my $min_year = Calendar::Dates::Perl->get_min_year; # => 1954
 my $max_year = Calendar::Dates::Perl->get_max_year; # => 9999
 my $entries  = Calendar::Dates::Perl->get_entries(2019);

C<$entries> result:

 [
   {
     date      => "2019-09-27",
     day       => 27,
     month     => 9,
     orig_year => 1954,
     summary   => "Larry Wall's birthday (65th anniversary)",
     tags      => ["anniversary"],
     year      => 2019,
   },
   {
     date      => "2019-12-18",
     day       => 18,
     month     => 12,
     orig_year => 1987,
     summary   => "Perl 1.0 released (32nd anniversary)",
     tags      => ["anniversary"],
     year      => 2019,
   },
   {
     date      => "2019-10-17",
     day       => 17,
     month     => 10,
     orig_year => 1994,
     summary   => "Perl 5.0 released (25th anniversary)",
     tags      => ["anniversary"],
     year      => 2019,
   },
 ]

=head2 Using from CLI (requires L<list-calendar-dates> and L<calx>)

 % list-calendar-dates -l -m Perl
 % calx -c Perl

=head1 DESCRIPTION

=head1 DATES STATISTICS

 +---------------+-------+
 | key           | value |
 +---------------+-------+
 | Earliest year | 1954  |
 | Latest year   | 9999  |
 +---------------+-------+

=head1 DATES SAMPLES

Entries for year 2018:

 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | date       | day | month | orig_year | summary                                  | tags        | year |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | 2018-09-27 | 27  | 9     | 1954      | Larry Wall's birthday (64th anniversary) | anniversary | 2018 |
 | 2018-12-18 | 18  | 12    | 1987      | Perl 1.0 released (31st anniversary)     | anniversary | 2018 |
 | 2018-10-17 | 17  | 10    | 1994      | Perl 5.0 released (24th anniversary)     | anniversary | 2018 |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+

Entries for year 2019:

 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | date       | day | month | orig_year | summary                                  | tags        | year |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | 2019-09-27 | 27  | 9     | 1954      | Larry Wall's birthday (65th anniversary) | anniversary | 2019 |
 | 2019-12-18 | 18  | 12    | 1987      | Perl 1.0 released (32nd anniversary)     | anniversary | 2019 |
 | 2019-10-17 | 17  | 10    | 1994      | Perl 5.0 released (25th anniversary)     | anniversary | 2019 |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+

Entries for year 2020:

 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | date       | day | month | orig_year | summary                                  | tags        | year |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+
 | 2020-09-27 | 27  | 9     | 1954      | Larry Wall's birthday (66th anniversary) | anniversary | 2020 |
 | 2020-12-18 | 18  | 12    | 1987      | Perl 1.0 released (33rd anniversary)     | anniversary | 2020 |
 | 2020-10-17 | 17  | 10    | 1994      | Perl 5.0 released (26th anniversary)     | anniversary | 2020 |
 +------------+-----+-------+-----------+------------------------------------------+-------------+------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlhist>

L<Calendar::Dates>

L<App::CalendarDatesUtils> contains CLIs to list dates from this module, etc.

L<calx> from L<App::calx> can display calendar and highlight dates from Calendar::Dates::* modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

# people
1954-09-27;Larry Wall's birthday;anniversary

# releases
1987-12-18;Perl 1.0 released;anniversary
1991-03-21;Perl 4.0 released;anniversary,low-priority
1994-10-17;Perl 5.0 released;anniversary

# 2019
