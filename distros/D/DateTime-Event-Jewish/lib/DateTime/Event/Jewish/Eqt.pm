package DateTime::Event::Jewish::Eqt;
use strict;
use warnings;
use DateTime;
use DateTime::Duration;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
our $VERSION = '0.01';
@EXPORT_OK = qw(eqt %eqt);

=head1 NAME

Eqt - Equation of time

=head1 Synopsis

Returns the Equation of Time (the variation of solar time from
clock time) for a given day in the year.

-ve times are sundial slow of clock.


=cut

our %eqt=(
"Jan"=>[
"-3:12",
"-3:40",
"-4:08",
"-4:36",
"-5:03",

"-5:30",
"-5:57",
"-6:23",
"-6:49",
"-7:14",

"-7:38",
"-8:02",
"-8:25",
"-8:48",
"-9:10",

"-9:32",
"-9:52",
"-10:12",
"-12:32",
"-10:50",

"-11:08",
"-11:25",
"-11:41",
"-11:57",
"-12:12",

"-12:26",
"-12:39",
"-12:51",
"-13:03",
"-13:14",
"-13:24",
],
"Feb"=>[
"-13:33",
"-13:41",
"-13:48",
"-13:55",
"-14:01",

"-14:06",
"-14:10",
"-14:14",
"-14:16",
"-14:18",

"-14:19",
"-14:20",
"-14:19",
"-14:18",
"-14:16",

"-14:13",
"-14:10",
"-14:06",
"-14:01",
"-13:55",

"-13:49",
"-13:42",
"-13:35",
"-13:27",
"-13:18",

"-13:09",
"-12:59",
"-12:48",
"-12:42",
],
"Mar"=>[
"-12:34",
"-12:23",
"-12:11",
"-11:58",
"-11:45",

"-11:31",
"-11:17",
"-11:03",
"-10:48",
"-10:33",

"-10:18",
"-10:02",
"-9:46",
"-9:30",
"-9:13",

"-8:56",
"-8:39",
"-8:22",
"-8:04",
"-7:46",

"-7:28",
"-7:10",
"-6:52",
"-6:34",
"-6:16",

"-5:58",
"-5:40",
"-5:21",
"-5:02",
"-4:44",
"-4:26",
],
"Apr"=>[
"-4:08",
"-3:50",
"-3:32",
"-3:14",
"-2:57",

"-2:40",
"-2:23",
"-2:06",
"-1:49",
"-1:32",

"-1:16",
"-1:00",
"-0:44",
"-0:29",
"-0:14",

"0:01",
"0:15",
"0:29",
"0:43",
"0:56",

"1:00",
"1:21",
"1:33",
"1:45",
"1:56",

"2:06",
"2:16",
"2:26",
"2:35",
"2:43",
],
"May"=>[
"2:51",
"2:59",
"3:06",
"3:12",
"3:18",

"3:23",
"3:27",
"3:31",
"3:35",
"3:38",

"3:40",
"3:42",
"3:44",
"3:44",
"3:44",

"3:44",
"3:43",
"3:41",
"3:39",
"3:37",

"3:34",
"3:30",
"3:24",
"3:21",
"3:16",

"3:10",
"3:03",
"2:56",
"2:49",
"2:41",
"2:33",
],
"Jun"=>[
"2:25",
"2:16",
"2:06",
"1:56",
"1:46",

"1:36",
"1:25",
"1:14",
"1:03",
"0:51",

"0:39",
"0:27",
"0:15",
"0:03",
"-0:10",

"-0:23",
"-0:36",
"-0:49",
"-1:02",
"-1:15",

"-1:28",
"-1:41",
"-1:54",
"-2:07",
"-2:20",

"-2:33",
"-2:45",
"-2:57",
"-3:09",
"-3:21",
],
"Jul"=>[
"-3:33",
"-3:45",
"-3:57",
"-4:08",
"-4:19",

"-4:29",
"-4:39",
"-4:49",
"-4:58",
"-5:07",

"-5:16",
"-5:24",
"-5:32",
"-5:39",
"-5:46",

"-5:52",
"-5:58",
"-6:03",
"-6:08",
"-6:12",

"-6:15",
"-6:18",
"-6:20",
"-6:22",
"-6:24",

"-6:25",
"-6:25",
"-6:24",
"-6:23",
"-6:21",
"-6:19",
],
"Aug"=>[
"-6:16",
"-6:13",
"-6:09",
"-6:04",
"-5:59",

"-5:53",
"-5:46",
"-5:39",
"-5:31",
"-5:23",

"-5:14",
"-5:05",
"-4:55",
"-4:44",
"-4:33",

"-4:21",
"-4:09",
"-3:57",
"-3:44",
"-3:30",

"-3:16",
"-3:01",
"-2:46",
"-2:30",
"-2:14",

"-1:58",
"-1:41",
"-1:24",
"-1:07",
"-0:49",
"-0:31",
],
"Sep"=>[
"-0:12",
"0:07",
"0:26",
"0:45",
"1:05",

"1:25",
"1:45",
"2:05",
"2:26",
"2:47",

"3:08",
"3:29",
"3:50",
"4:11",
"4:32",

"4:53",
"5:14",
"5:35",
"5:56",
"6:18",

"6:40",
"7:01",
"7:22",
"7:43",
"8:04",

"8:25",
"8:46",
"9:06",
"9:26",
"9:46",
],
"Oct"=>[
"10:05",
"10:24",
"10:43",
"11:02",
"11:20",

"11:38",
"11:56",
"12:13",
"12:30",
"12:46",

"13:02",
"13:18",
"13:33",
"13:47",
"14:01",

"14:14",
"14:27",
"14:39",
"14:51",
"15:01",

"15:12",
"15:22",
"15:31",
"15:40",
"15:47",

"15:54",
"16:01",
"16:06",
"16:11",
"16:15",
"16:18",
],
"Nov"=>[
"16:20",
"16:22",
"16:23",
"16:23",
"16:22",

"16:20",
"16:18",
"16:15",
"16:11",
"16:06",

"16:00",
"15:53",
"15:46",
"15:37",
"15:28",

"15:18",
"15:07",
"14:56",
"14:43",
"14:30",

"14:16",
"14:01",
"13:45",
"13:28",
"13:11",

"12:53",
"12:34",
"12:14",
"11:54",
"11:33",
],
"Dec"=>[
"11:11",
"10:49",
"10:26",
"10:02",
"9:38",

"9:13",
"8:48",
"8:22",
"7:56",
"7:29",

"7:02",
"6:34",
"6:06",
"5:38",
"5:09",

"4:40",
"4:11",
"3:42",
"3:13",
"2:43",

"2:13",
"1:43",
"1:13",
"0:43",
"0:13",

"-0:17",
"-0:47",
"-1:16",
"-1:45",
"-2:14",
"-2:43",
],
);
our @months=("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");


=head3 eqt($date)

Returns the deviation of solar time from clock time in minutes.

Add to clock time to get sundial time;
subtract from sundial time to get clock time.

=over

=item $date

A DateTime object. Only the day and month are relevant.

=back

=cut

sub eqt {
    my $date= shift;
    # Do some basic validation
    my ($day, $month)	= ($date->day, $date->month);
    if ($month !~ /^\w+$/) {
        print "Bad month: not alphanumeric $month\n";
	return undef;
    }
    if ($day !~ /^[0-9]+$/) {
        print "(eqt) Bad day: not numeric $day\n";
	return undef;
    }
    if ($month =~ /^[0-9]+$/) { $month	= $months[$month-1];}
    $month	= ucfirst($month);		# Get the case right

    # Get the offset for this date.
    my $decl	= $eqt{$month}[$day-1];
    my ($min, $sec)	= ($decl =~ /([^:]+):([^:]+)/);
    $min	= int($min);
    $sec	= int($sec);
    if ($min < 0){ $sec	= -$sec;}
    $min	+= $sec/60.0;
    return $min;
}


1;

=head1 AUTHOR

Raphael Mankin, C<< <rapmankin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-jewish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Jewish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Jewish


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Jewish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Jewish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Jewish>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Jewish/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Raphael Mankin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DateTime::Event::Eqt
