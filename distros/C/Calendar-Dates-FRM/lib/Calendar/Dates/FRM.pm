package Calendar::Dates::FRM;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple';
with 'Calendar::DatesRoles::DataUser::CalendarVar';

sub filter_entry {
    my ($self, $entry, $params) = @_;

    if (defined(my $mon = $params->{exam_month})) {
        $mon eq 'may' || $mon eq 'nov' or die "Invalid exam_month, please specify either may/nov";
        return 0 unless grep { /\A$mon/ } @{ $entry->{tags} // [] };
    }
    # exam_level has no effect currently, each exam date is relevant to both
    # levels/parts.
    1;
}

1;
# ABSTRACT: FRM exam calendar

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::FRM - FRM exam calendar

=head1 VERSION

This document describes version 0.007 of Calendar::Dates::FRM (from Perl distribution Calendar-Dates-FRM), released on 2019-06-20.

=head1 SYNOPSIS

=head2 Using from Perl

 use Calendar::Dates::FRM;
 my $min_year = Calendar::Dates::FRM->get_min_year; # => 2018
 my $max_year = Calendar::Dates::FRM->get_max_year; # => 2020
 my $entries  = Calendar::Dates::FRM->get_entries(2019);

C<$entries> result:

 [
   {
     date    => "2019-01-03",
     day     => 3,
     month   => 1,
     summary => "Exam results sent via email",
     tags    => ["nov2018exam"],
     year    => 2019,
   },
   {
     date    => "2019-01-31",
     day     => 31,
     month   => 1,
     summary => "Early registration closed",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-02-01",
     day     => 1,
     month   => 2,
     summary => "Standard registration opened",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-02-28",
     day     => 28,
     month   => 2,
     summary => "Standard registration closed",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-03-01",
     day     => 1,
     month   => 3,
     summary => "Late registration opened",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-04-15",
     day     => 15,
     month   => 4,
     summary => "Late registration closed",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-04-15",
     day     => 15,
     month   => 4,
     summary => "Defer deadline",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-05-01",
     day     => 1,
     month   => 5,
     summary => "Admission tickets released",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-05-18",
     day     => 18,
     month   => 5,
     summary => "Exam day",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-06-28",
     day     => 28,
     month   => 6,
     summary => "Exam results sent via email",
     tags    => ["may2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-05-01",
     day     => 1,
     month   => 5,
     summary => "Early registration opened",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-07-31",
     day     => 31,
     month   => 7,
     summary => "Early registration closed",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-08-01",
     day     => 1,
     month   => 8,
     summary => "Standard registration opened",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-08-31",
     day     => 31,
     month   => 8,
     summary => "Standard registration closed",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-09-01",
     day     => 1,
     month   => 9,
     summary => "Late registration opened",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-10-15",
     day     => 15,
     month   => 10,
     summary => "Late registration closed",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-10-15",
     day     => 15,
     month   => 10,
     summary => "Defer deadline",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-11-01",
     day     => 1,
     month   => 11,
     summary => "Admission tickets released",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
   {
     date    => "2019-11-16",
     day     => 16,
     month   => 11,
     summary => "Exam day",
     tags    => ["nov2019exam"],
     year    => 2019,
   },
 ]

=head2 Using from CLI (requires L<list-calendar-dates> and L<calx>)

 % list-calendar-dates -l -m FRM
 % calx -c FRM

=head1 DESCRIPTION

This module provides FRM exam calendar using the L<Calendar::Dates> interface.

=head1 DATES STATISTICS

 +---------------+-------+
 | key           | value |
 +---------------+-------+
 | Earliest year | 2018  |
 | Latest year   | 2020  |
 +---------------+-------+

=head1 DATES SAMPLES

Entries for year 2018:

 +------------+-----+-------+---------------------------+-------------+------+
 | date       | day | month | summary                   | tags        | year |
 +------------+-----+-------+---------------------------+-------------+------+
 | 2018-12-01 | 1   | 12    | Early registration opened | may2019exam | 2018 |
 +------------+-----+-------+---------------------------+-------------+------+

Entries for year 2019:

 +------------+-----+-------+------------------------------+-------------+------+
 | date       | day | month | summary                      | tags        | year |
 +------------+-----+-------+------------------------------+-------------+------+
 | 2019-01-03 | 3   | 1     | Exam results sent via email  | nov2018exam | 2019 |
 | 2019-01-31 | 31  | 1     | Early registration closed    | may2019exam | 2019 |
 | 2019-02-01 | 1   | 2     | Standard registration opened | may2019exam | 2019 |
 | 2019-02-28 | 28  | 2     | Standard registration closed | may2019exam | 2019 |
 | 2019-03-01 | 1   | 3     | Late registration opened     | may2019exam | 2019 |
 | 2019-04-15 | 15  | 4     | Late registration closed     | may2019exam | 2019 |
 | 2019-04-15 | 15  | 4     | Defer deadline               | may2019exam | 2019 |
 | 2019-05-01 | 1   | 5     | Admission tickets released   | may2019exam | 2019 |
 | 2019-05-18 | 18  | 5     | Exam day                     | may2019exam | 2019 |
 | 2019-06-28 | 28  | 6     | Exam results sent via email  | may2019exam | 2019 |
 | 2019-05-01 | 1   | 5     | Early registration opened    | nov2019exam | 2019 |
 | 2019-07-31 | 31  | 7     | Early registration closed    | nov2019exam | 2019 |
 | 2019-08-01 | 1   | 8     | Standard registration opened | nov2019exam | 2019 |
 | 2019-08-31 | 31  | 8     | Standard registration closed | nov2019exam | 2019 |
 | 2019-09-01 | 1   | 9     | Late registration opened     | nov2019exam | 2019 |
 | 2019-10-15 | 15  | 10    | Late registration closed     | nov2019exam | 2019 |
 | 2019-10-15 | 15  | 10    | Defer deadline               | nov2019exam | 2019 |
 | 2019-11-01 | 1   | 11    | Admission tickets released   | nov2019exam | 2019 |
 | 2019-11-16 | 16  | 11    | Exam day                     | nov2019exam | 2019 |
 +------------+-----+-------+------------------------------+-------------+------+

Entries for year 2020:

 +------------+-----+-------+-----------------------------+-------------+------+
 | date       | day | month | summary                     | tags        | year |
 +------------+-----+-------+-----------------------------+-------------+------+
 | 2020-01-02 | 2   | 1     | Exam results sent via email | nov2019exam | 2020 |
 +------------+-----+-------+-----------------------------+-------------+------+

=for Pod::Coverage ^(filter_entry)$

=head1 PARAMETERS

=head2 exam_month

Can be used to select dates related to a certain exam month only. Value is
either C<may> or C<nov>. Example:

 $entries = Calendar::Dates::FRM->get_entries({exam_month=>'nov'}, 2019);

=head2 exam_level

Can be used to select dates related to a certain exam level (part) only. Value
is either 1, 2.

 $entries = Calendar::Dates::FRM->get_entries({exam_level=>2}, 2019);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-FRM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-FRM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-FRM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.garp.org/#!/frm/program-exams>

L<https://en.wikipedia.org/wiki/Financial_risk_management>

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
# nov2018exam
2019-01-03;Exam results sent via email;nov2018exam

# may2019exam
2018-12-01;Early registration opened;may2019exam
2019-01-31;Early registration closed;may2019exam
2019-02-01;Standard registration opened;may2019exam
2019-02-28;Standard registration closed;may2019exam
2019-03-01;Late registration opened;may2019exam
2019-04-15;Late registration closed;may2019exam
2019-04-15;Defer deadline;may2019exam
2019-05-01;Admission tickets released;may2019exam
2019-05-18;Exam day;may2019exam
2019-06-28;Exam results sent via email;may2019exam

# nov2019exam
2019-05-01;Early registration opened;nov2019exam
2019-07-31;Early registration closed;nov2019exam
2019-08-01;Standard registration opened;nov2019exam
2019-08-31;Standard registration closed;nov2019exam
2019-09-01;Late registration opened;nov2019exam
2019-10-15;Late registration closed;nov2019exam
2019-10-15;Defer deadline;nov2019exam
2019-11-01;Admission tickets released;nov2019exam
2019-11-16;Exam day;nov2019exam
2020-01-02;Exam results sent via email;nov2019exam
