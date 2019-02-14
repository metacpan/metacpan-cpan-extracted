package Calendar::Dates::CFA;

our $DATE = '2019-02-14'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::FromData';

our @ENTRIES = (
    # dec2018exam
    {date=>'2019-01-23', summary=>'Exam results announcement (Dec 2018, Levels I & II)', tags=>['dec2018exam']},

    # jun2019exam
    {date=>'2018-10-15', summary=>'First deadline to request disability accommodations', tags=>['jun2019exam']},
    {date=>'2018-10-17', summary=>'Early registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-02-13', summary=>'Standard registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-02-18', summary=>'Second deadline to request disability accommodations', tags=>['jun2019exam']},
    {date=>'2019-03-13', summary=>'Final (late) registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-03-18', summary=>'Final deadline to request disability accommodations', tags=>['jun2019exam']},
    # mid-may 2019, admission tickets available
    {date=>'2019-06-11', summary=>'Deadline for submission of test center change requests', tags=>['jun2019exam']},
    {date=>'2019-06-15', summary=>'Exam day: Asia-Pacific (Levels II & III); Americas and EMEA (all levels)', tags=>['jun2019exam']},
    {date=>'2019-06-16', summary=>'Exam day: Asia-Pacific (Level I only)', tags=>['jun2019exam']},
    {date=>'2019-06-16', summary=>'Religious alternate exam date (Americas and EMEA, all levels)', tags=>['jun2019exam']},
    {date=>'2019-06-17', summary=>'Religious alternate exam date (Asia Pacific, all levels)', tags=>['jun2019exam']},
    # TODO: result announcement

    # dec2019exam
    {date=>'2019-01-24', summary=>'Exam registration open', tags=>['dec2019exam']},
    {date=>'2019-03-27', summary=>'Early registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-08-14', summary=>'Standard registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-09-11', summary=>'Final (late) registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-12-07', summary=>'Exam day', tags=>['dec2019exam']},
);

1;
# ABSTRACT: CFA exam calendar

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::CFA - CFA exam calendar

=head1 VERSION

This document describes version 0.003 of Calendar::Dates::CFA (from Perl distribution Calendar-Dates-CFA), released on 2019-02-14.

=head1 SYNOPSIS

=head2 Using from Perl

 use Calendar::Dates::CFA;
 my $min_year = Calendar::Dates::CFA->get_min_year; # => 2018
 my $max_year = Calendar::Dates::CFA->get_max_year; # => 2019
 my $entries  = Calendar::Dates::CFA->get_entries(2019);

C<$entries> result:

 [
   {
     date    => "2019-01-23",
     day     => 23,
     month   => 1,
     summary => "Exam results announcement (Dec 2018, Levels I & II)",
     tags    => ["dec2018exam"],
     year    => 2019,
   },
   {
     date    => "2019-02-13",
     day     => 13,
     month   => 2,
     summary => "Standard registration fee deadline",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-02-18",
     day     => 18,
     month   => 2,
     summary => "Second deadline to request disability accommodations",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-03-13",
     day     => 13,
     month   => 3,
     summary => "Final (late) registration fee deadline",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-03-18",
     day     => 18,
     month   => 3,
     summary => "Final deadline to request disability accommodations",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-11",
     day     => 11,
     month   => 6,
     summary => "Deadline for submission of test center change requests",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-15",
     day     => 15,
     month   => 6,
     summary => "Exam day: Asia-Pacific (Levels II & III); Americas and EMEA (all levels)",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-16",
     day     => 16,
     month   => 6,
     summary => "Exam day: Asia-Pacific (Level I only)",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-16",
     day     => 16,
     month   => 6,
     summary => "Religious alternate exam date (Americas and EMEA, all levels)",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-17",
     day     => 17,
     month   => 6,
     summary => "Religious alternate exam date (Asia Pacific, all levels)",
     tags    => ["jun2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-01-24",
     day     => 24,
     month   => 1,
     summary => "Exam registration open",
     tags    => ["dec2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-03-27",
     day     => 27,
     month   => 3,
     summary => "Early registration fee deadline",
     tags    => ["dec2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-08-14",
     day     => 14,
     month   => 8,
     summary => "Standard registration fee deadline",
     tags    => ["dec2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-09-11",
     day     => 11,
     month   => 9,
     summary => "Final (late) registration fee deadline",
     tags    => ["dec2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-12-07",
     day     => 7,
     month   => 12,
     summary => "Exam day",
     tags    => ["dec2019exam"],
     year    => 2019,
   },
 ]

=head2 Using from CLI (requires L<list-calendar-dates> and L<calx>)

 % list-calendar-dates -l -m CFA
 % calx -c CFA

=head1 DESCRIPTION

This module provides CFA exam calendar using the L<Calendar::Dates> interface.

=head1 DATES STATISTICS

 +---------------+-------+
 | key           | value |
 +---------------+-------+
 | Earliest year | 2018  |
 | Latest year   | 2019  |
 +---------------+-------+

=head1 DATES SAMPLES

Entries for year 2018:

 +------------+-----+-------+-----------------------------------------------------+-------------+------+
 | date       | day | month | summary                                             | tags        | year |
 +------------+-----+-------+-----------------------------------------------------+-------------+------+
 | 2018-10-15 | 15  | 10    | First deadline to request disability accommodations | jun2019exam | 2018 |
 | 2018-10-17 | 17  | 10    | Early registration fee deadline                     | jun2019exam | 2018 |
 +------------+-----+-------+-----------------------------------------------------+-------------+------+

Entries for year 2019:

 +------------+-----+-------+--------------------------------------------------------------------------+-------------+------+
 | date       | day | month | summary                                                                  | tags        | year |
 +------------+-----+-------+--------------------------------------------------------------------------+-------------+------+
 | 2019-01-23 | 23  | 1     | Exam results announcement (Dec 2018, Levels I & II)                      | dec2018exam | 2019 |
 | 2019-02-13 | 13  | 2     | Standard registration fee deadline                                       | jun2019exam | 2019 |
 | 2019-02-18 | 18  | 2     | Second deadline to request disability accommodations                     | jun2019exam | 2019 |
 | 2019-03-13 | 13  | 3     | Final (late) registration fee deadline                                   | jun2019exam | 2019 |
 | 2019-03-18 | 18  | 3     | Final deadline to request disability accommodations                      | jun2019exam | 2019 |
 | 2019-06-11 | 11  | 6     | Deadline for submission of test center change requests                   | jun2019exam | 2019 |
 | 2019-06-15 | 15  | 6     | Exam day: Asia-Pacific (Levels II & III); Americas and EMEA (all levels) | jun2019exam | 2019 |
 | 2019-06-16 | 16  | 6     | Exam day: Asia-Pacific (Level I only)                                    | jun2019exam | 2019 |
 | 2019-06-16 | 16  | 6     | Religious alternate exam date (Americas and EMEA, all levels)            | jun2019exam | 2019 |
 | 2019-06-17 | 17  | 6     | Religious alternate exam date (Asia Pacific, all levels)                 | jun2019exam | 2019 |
 | 2019-01-24 | 24  | 1     | Exam registration open                                                   | dec2019exam | 2019 |
 | 2019-03-27 | 27  | 3     | Early registration fee deadline                                          | dec2019exam | 2019 |
 | 2019-08-14 | 14  | 8     | Standard registration fee deadline                                       | dec2019exam | 2019 |
 | 2019-09-11 | 11  | 9     | Final (late) registration fee deadline                                   | dec2019exam | 2019 |
 | 2019-12-07 | 7   | 12    | Exam day                                                                 | dec2019exam | 2019 |
 +------------+-----+-------+--------------------------------------------------------------------------+-------------+------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-CFA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-CFA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-CFA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.cfainstitute.org/programs/cfa>

L<https://en.wikipedia.org/wiki/Chartered_Financial_Analyst>

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
