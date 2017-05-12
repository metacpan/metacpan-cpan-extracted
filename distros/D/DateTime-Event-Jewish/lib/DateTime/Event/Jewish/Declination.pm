package DateTime::Event::Jewish::Declination;
use strict;
use warnings;
use DateTime;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
our $VERSION = '0.01';
@EXPORT_OK = qw(declination %Declination);

=head1 NAME

Declination - Declination of the sun for each day of the year

=head1 SYNOPSIS

  use Declination qw(declination);
  
  my $date = DateTime->new(day=>21, month=>3, year=>2010);
  my $declination	= declination($date, 'deg');

=cut

#    When using this table beware that day-of-month runs from 1,
#    but subscripts into the arrays below run from 0


use Math::Trig;
use DateTime;
our %Declination=(
"Jan"=>[
    "-23:04",
    "-22:59",
    "-22:54",
    "-22:48",
    "-22:42",

    "-22:36",
    "-22:28",
    "-22:21",
    "-22:13",
    "-22:05",

    "-21:56",
    "-21:47",
    "-21:37",
    "-21:27",
    "-21:16",

    "-21:06",
    "-20:54",
    "-20:42",
    "-20:30",
    "-20:18",

    "-20:05",
    "-19:52",
    "-19:38",
    "-19:24",
    "-19:10",
    "-18:55",
    "-18:40",
    "-18:25",
    "-18:09",
    "-17:53",

    "-17:37",
    ],

    "Feb"=>[
	"-17:20",
	"-17:03",
	"-16:46",
	"-16:28",
    "-16:10",

    "-15:52",
    "-15:34",
    "-15:15",
    "-14:56",
    "-14:37",

    "-14:18",
    "-13:58",
    "-13:38",
    "-13:18",
    "-12:59",

    "-12:37",
    "-12:16",
    "-11:55",
    "-11:34",
    "-11:13",

    "-10:52",
    "-10:30",
    "-10:08",
    "-9:46",
    "-9:24",

    "-9:02",
    "-8:39",
    "-8:17",
    "-8:03",
    ],

"Mar"=>[
    "-7:49",
    "-7:26",
    "-7:03",
    "-6:40",
    "-6:17",

    "-5:54",
    "-5:30",
    "-5:07",
    "-4:44",
    "-4:20",

    "-3:57",
    "-3:33",
    "-3:10",
    "-2:46",
    "-2:22",

    "-1:59",
    "-1:35",
    "-1:11",
    "-0:48",
    "-0:24",

    "0:00",
    "0:24",
    "0:47",
    "1:11",
    "1:35",

    "1:58",
    "2:22",
    "2:45",
    "3:09",
    "3:32",

    "3:55",
    ],

"Apr"=>[
    "4:18",
    "4:42",
    "5:05",
    "5:28",
    "5:51",

    "6:13",
    "6:36",
    "6:59",
    "7:21",
    "7:43",

    "8:07",
    "8:28",
    "8:50",
    "9:11",
    "9:33",

    "9:54",
    "10:16",
    "10:37",
    "10:58",
    "11:19",

    "11:39",
    "12:00",
    "12:20",
    "12:40",
    "13:00",

    "13:19",
    "13:38",
    "13:58",
    "14:16",
    "14:35",
    ],

"May"=>[
    "14:54",
    "15:12",
    "15:30",
    "15:47",
    "16:05",

    "16:22",
    "16:39",
    "16:55",
    "17:12",
    "17:27",

    "17:43",
    "17:59",
    "18:14",
    "18:29",
    "18:43",

    "18:58",
    "19:11",
    "19:25",
    "19:38",
    "19:51",

    "20:04",
    "20:16",
    "20:28",
    "20:39",
    "20:50",

    "21:01",
    "21:12",
    "21:22",
    "21:31",
    "21:41",

    "21:50",
    ],

"Jun"=>[
    "21:58",
    "22:06",
    "22:14",
    "22:22",
    "22:29",

    "22:35",
    "22:42",
    "22:47",
    "22:53",
    "22:58",

    "23:02",
    "23:07",
    "23:11",
    "23:14",
    "23:17",

    "23:20",
    "23:22",
    "23:24",
    "23:25",
    "23:26",

    "23:26",
    "23:26",
    "23:26",
    "23:25",
    "23:24",

    "23:23",
    "23:21",
    "23:19",
    "23:16",
    "23:13",
    ],

"Jul"=>[
    "23:09",
    "23:05",
    "23:01",
    "22:56",
    "22:51",

    "22:45",
    "22:39",
    "22:33",
    "22:26",
    "22:19",

    "22:11",
    "22:04",
    "21:55",
    "21:46",
    "21:37",

    "21:28",
    "21:18",
    "21:08",
    "20:58",
    "20:47",

    "20:36",
    "20:24",
    "20:12",
    "20:00",
    "19:47",

    "19:34",
    "19:21",
    "19:08",
    "18:54",
    "18:40",

    "18:25",
    ],

"Aug"=>[
    "18:10",
    "17:55",
    "17:40",
    "17:24",
    "17:08",

    "16:52",
    "16:36",
    "16:19",
    "16:02",
    "15:45",

    "15:27",
    "15:10",
    "14:52",
    "14:33",
    "14:15",

    "13:56",
    "13:37",
    "13:18",
    "12:59",
    "12:39",

    "12:19",
    "11:59",
    "11:39",
    "11:19",
    "10:58",

    "10:38",
    "10:17",
    "9:56",
    "9:35",
    "9:13",

    "8:52",
    ],

"Sep"=>[
    "8:30",
    "8:09",
    "7:47",
    "7:25",
    "7:03",

    "6:40",
    "6:18",
    "5:56",
    "5:33",
    "5:10",

    "4:48",
    "4:25",
    "4:02",
    "3:39",
    "3:16",

    "2:53",
    "2:30",
    "2:06",
    "1:43",
    "1:20",

    "0:57",
    "0:33",
    "0:10",
    "-0:14",
    "-0:37",

    "-1:00",
    "-1:24",
    "-1:47",
    "-2:10",
    "-2:34",
    ],

"Oct"=>[
    "-2:57",
    "-3:20",
    "-3:44",
    "-4:07",
    "-4:30",

    "-4:53",
    "-5:16",
    "-5:39",
    "-6:02",
    "-6:25",

    "-6:48",
    "-7:10",
    "-7:32",
    "-7:35",
    "-8:18",

    "-8:40",
    "-9:02",
    "-9:24",
    "-9:45",
    "-10:07",

    "-10:29",
    "-10:50",
    "-11:12",
    "-11:33",
    "-11:54",

    "-12:14",
    "-12:35",
    "-12:55",
    "-13:15",
    "-13:35",

    "-13:55",
    ],

"Nov"=>[
    "-14:14",
    "-14:34",
    "-14:53",
    "-15:11",
    "-15:30",

    "-15:48",
    "-16:06",
    "-16:24",
    "-16:41",
    "-16:58",

    "-17:15",
    "-17:32",
    "-17:48",
    "-18:04",
    "-18:20",

    "-18:35",
    "-18:50",
    "-19:05",
    "-19:19",
    "-19:33",

    "-19:47",
    "-20:00",
    "-20:13",
    "-20:26",
    "-20:38",

    "-20:50",
    "-21:01",
    "-21:12",
    "-21:23",
    "-21:33",
    ],

"Dec"=>[
    "-21:43",
    "-21:52",
    "-22:01",
    "-22:10",
    "-22:18",

    "-22:25",
    "-22:32",
    "-22:39",
    "-22:46",
    "-22:52",

    "-22:57",
    "-23:02",
    "-23:07",
    "-23:11",
    "-23:14",

    "-23:17",
    "-23:20",
    "-23:22",
    "-23:24",
    "-23:25",

    "-23:26",
    "-23:26",
    "-23:26",
    "-23:26",
    "-23:25",

    "-23:23",
    "-23:21",
    "-23:19",
    "-23:16",
    "-23:12",

    "-23:08",
    ],
);
our @months=("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");


=head3 declination($date, [ $units])

Returns the declination of the sun on the given day of the year.

=over

=item $date

A DateTime object. Only the day and month are relevant.


=item $units

The units to return, either 'rad' or 'deg'.
This determines whether the result is returned as radians or
degrees. If you are going to pass the result to trigonometric
functions then radians are better. Default 'rad'.

=back

=cut

sub declination {
    my $date	= shift;
    my $day	= $date->day;
    my $month	= $date->month;
    my $as = scalar @_ ? shift : "rad";
    # Do some basic validation
    if ($month !~ /^[a-z0-9]+$/i) {
        print "Bad month: not alphanumeric: $month\n";
	return undef;
    }
    if ($day !~ /^[0-9]+$/) {
        print " (declination) Bad day: not numeric: $day\n";
	return undef;
    }
    if ($month =~ /^[0-9]+$/){
    	$month	= $months[$month-1];
    }
    $month	= ucfirst(lc($month));		# Get the case right

    # Get the declination of the sun for this date.
    my $decl	= $Declination{$month}->[$day-1];
    my ($deg, $min)	= ($decl =~ /(-?[0-9]+):([0-9]+)/);
    if ($deg < 0){ $min	= -$min;}
    $deg	+= $min/60.0;

    if ($as eq "deg"){ return $deg;}
    $decl	= deg2rad($deg);
    return $decl;
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

1; # End of DateTime::Event::Declination
