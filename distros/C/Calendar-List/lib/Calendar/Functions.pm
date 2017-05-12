package Calendar::Functions;

use strict;
use warnings;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '0.28';

#----------------------------------------------------------------------------

=head1 NAME

Calendar::Functions - A module containing functions for dates and calendars.

=head1 SYNOPSIS

  use Calendar::Functions;
  $ext       = ext($day);
  $moty      = moty($monthname);
  $monthname = moty($moty);
  $dotw      = dotw($dayname);
  $dayname   = dotw($dotw);

  use Calendar::Functions qw(:dates);
  my $dateobj               = encode_date($day,$month,$year);
  ($day,$month,$year,$dotw) = decode_date($dateobj);
  $cmp = compare_dates($dateobj1, $dateobj2);

  use Calendar::Functions qw(:form);
  $str = format_date( $fmt, $day, $month, $year, $dotw);
  $str = reformat_date( $date, $fmt1, $fmt2 );

  use Calendar::Functions qw(:all);
  fail_range($year);

=head1 DESCRIPTION

The module is intended to provide numerous support functions for other
date and/or calendar functions

=head1 EXPORT

  ext, moty, dotw

  dates:    encode_date, decode_date, compare_dates, add_day

  form:     format_date, reformat_date

  all:      encode_date, decode_date, compare_dates, add_day
            format_date, reformat_date,
            ext, moty, dotw, fail_range

=cut

#----------------------------------------------------------------------------

#############################################################################
#Export Settings                                                            #
#############################################################################

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'basic' => [ qw( ext moty dotw ) ],
    'dates' => [ qw( ext moty dotw
                     encode_date decode_date compare_dates add_day ) ],
    'form'  => [ qw( ext moty dotw format_date reformat_date ) ],
    'all'   => [ qw( ext moty dotw format_date reformat_date fail_range
                     encode_date decode_date compare_dates add_day ) ],
    'test'  => [ qw( _caltest ) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'test'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'basic'} } );

#############################################################################
#Library Modules                                                            #
#############################################################################

use Time::Local;
eval "use Date::ICal";
my $di = ! $@;
eval "use DateTime";
my $dt = ! $@;
eval "use Time::Piece";
my $tp = ! $@;

if($tp) {
    require Time::Piece;
}

#############################################################################
#Variables
#############################################################################

# prime our print out names
my @months  = qw(   NULL January February March April May June July
                    August September October November December );
my @dotw    = qw(   Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

my $MinYear     = 1902;
my $MaxYear     = 2037;
my $EpoYear     = 1970;

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions                                                        #
#############################################################################

=head1 FUNCTIONS

=over 4

=item encode_date( DD, MM, YYYY )

Translates the given date values into a date object or number.

=cut

# name: encode_date
# args: day,month,year .... standard numerical day/month/year values
# retv: date object or number
# desc: Translates the given date values into a date object or number.

sub encode_date {
    my ($day,$mon,$year) = @_;
    my $this;

    if($day && $mon && $year) {
        if($dt) {       # DateTime.pm loaded
            $this = DateTime->new(day=>$day,month=>$mon,year=>$year);
        } elsif($di) {  # Date::ICal loaded
            $this = Date::ICal->new(day=>$day,month=>$mon,year=>$year,offset=>0);
        } else {        # using Time::Local
            return  if(fail_range($year));
            $this = timegm(0,0,12,$day,$mon-1,$year);
        }
    }

    return $this
}

=item decode_date( date )

Translates the given date object into date values.

=cut

# name: decode_date
# args: date1 .... date object or number
# retv: the standard numerical day/month/year values
# desc: Translates the date object or number into date values.

sub decode_date {
    my $date = shift || return;
    my ($day,$month,$year,$dow);

    if($dt) {           # DateTime.pm loaded
        ($day,$month,$year,$dow) =
            ($date->day,$date->month,$date->year,$date->dow);
        $dow %= 7;
    } elsif($di) {      # Date::ICal loaded
        ($day,$month,$year,$dow) =
            ($date->day,$date->month,$date->year,$date->day_of_week);
    } else {            # using Time::Local
        ($day,$month,$year,$dow) = (localtime($date))[3..6];
        (undef,undef,undef,$day,$month,$year,$dow) = (localtime($date));
        $month++;
        $year+=1900;
    }

    return $day,$month,$year,$dow;
}

=item compare_dates( date, date )

Using the appropriate method, determines ther ordering of the two given dates.

=cut

# name: compare_dates
# args: date1 .... date object or string
#       date2 .... date object or string
# retv: the compare value, as per the 'cmp' or '<=>' functionality.
# desc: Using the selected module, determines whether the first date is before,
#       after or the same as the second.

sub compare_dates {
    my ($d1,$d2) = @_;
    return  0   if(! defined $d1 && ! defined $d2);
    return  1   if(  defined $d1 && ! defined $d2);
    return -1   if(! defined $d1);

    my $diff = 0;
    if($dt)     { $diff = DateTime->compare( $d1, $d2 ); }
    elsif($di)  { $diff = $d1->compare($d2); }
    else        { $diff = $d1 < $d2 ? -1 : ($d1 > $d2 ? 1 : 0); }

    return $diff;
}

=item add_day( date )

Add one day to the date object.

=cut

sub add_day {
    my $d1 = shift;

    if($dt)     { $d1->add( days => 1 ); }
    elsif($di)  { $d1->add( day  => 1 ); }
    else        { $d1 += 60 * 60 * 24; }

    return $d1;
}

=item format_date( fmt, day, mon, year [, dotw])

transposes the standard date values into a formatted string.

=cut

# name: format_date
# args: fmt ............. format string
#       day/mon/year .... standard date values
#       dotw ............ day of the week number (optional)
# retv: newly formatted date
# desc: Transposes the format string and date values into a correctly
#       formatted date string.

sub format_date {
    my ($fmt,$day,$mon,$year,$dotw) = @_;
    return  unless($day && $mon && $year);

    unless($dotw) {
        (undef,undef,undef,$dotw) = decode_date(encode_date($day,$mon,$year));
    }

    # create date mini strings
    my $fday    = sprintf "%02d", $day;
    my $fmon    = sprintf "%02d", $mon;
    my $fyear   = sprintf "%04d", $year;
    my $fmonth  = sprintf "%s",   $months[$mon];
    my $fdotw   = sprintf "%s",   $dotw[$dotw];
    my $fddext  = sprintf "%d%s", $day, ext($day);
    my $amonth  = substr($fmonth,0,3);
    my $adotw   = substr($fdotw,0,3);
    my $epoch   = -1;   # an arbitory number

    # epoch only supports the same dates in the 32-bit range
    if($tp && $fmt =~ /\bEPOCH\b/ && $year >= $EpoYear && $year <= $MaxYear) {
        my $date = timegm 0, 0, 12, $day, $mon -1, $year;
        my $t = Time::Piece::gmtime($date);
        $epoch = $t->epoch  if($t);
    }

    # transpose format string into a date string
    $fmt =~ s/\bDMY\b/$fday-$fmon-$fyear/i;
    $fmt =~ s/\bMDY\b/$fmon-$fday-$fyear/i;
    $fmt =~ s/\bYMD\b/$fyear-$fmon-$fday/i;
    $fmt =~ s/\bMABV\b/$amonth/i;
    $fmt =~ s/\bDABV\b/$adotw/i;
    $fmt =~ s/\bMONTH\b/$fmonth/i;
    $fmt =~ s/\bDAY\b/$fdotw/i;
    $fmt =~ s/\bDDEXT\b/$fddext/i;
    $fmt =~ s/\bYYYY\b/$fyear/i;
    $fmt =~ s/\bMM\b/$fmon/i;
    $fmt =~ s/\bDD\b/$fday/i;
    $fmt =~ s/\bEPOCH\b/$epoch/i;

    return $fmt;
}

=item reformat_date( date, form1, form1 )

transposes the standard date values into a formatted string.

=cut

# name: reformat_date
# args: date ..... date string
#       form1 .... format string
#       form2 .... format string
# retv: converted date string
# desc: Transposes the date from one format to another.

sub reformat_date {
    my ($date,$form1,$form2) = @_;
    my ($year,$mon,$day,$dotw) = ();

    while($form1) {
        if($form1 =~ /^YYYY/) {
            ($year) = ($date =~ /^(\d{4})/);
            $form1 =~ s/^....//;
            $date =~ s/^....//;

        } elsif($form1 =~ /^MONTH/) {
            my ($month) = ($date =~ /^(\w+)/);
            $mon = moty($month);
            $form1 =~ s/^\w+//;
            $date =~ s/^\w+//;

        } elsif($form1 =~ /^MM/) {
            ($mon) = ($date =~ /^(\d{2})/);
            $form1 =~ s/^..//;
            $date =~ s/^..//;

        } elsif($form1 =~ /^DDEXT/) {
            ($day) = ($date =~ /^(\d{1,2})/);
            $form1 =~ s/^.....//;
            $date =~ s/^\d{1,2}..//;

        } elsif($form1 =~ /^DD/) {
            ($day) = ($date =~ /^(\d{2})/);
            $form1 =~ s/^..//;
            $date =~ s/^..//;

        } elsif($form1 =~ /^DAY/) {
            my ($wday) = ($date =~ /^(\w+)/);
            $dotw = dotw($wday);
            $form1 =~ s/^\w+//;
            $date =~ s/^\w+//;

        } else {
            $form1 =~ s/^.//;
            $date =~ s/^.//;
        }
    }

    # return original date if badly formed date
    return $_[0]    unless(int($day) && int($mon) && int($year));

    # get the day of the week, if we need it
    $dotw = dotw($day,$mon,$year)   if($form2 =~ /DAY/ && !$dotw);

    # rebuild date into second format
    return format_date($form2,$day,$mon,$year,$dotw);
}

=item ext( day )

Returns the extension associated with the given day value.

=cut

# name: ext
# args: day .... day value
# retv: day value extension
# desc: Returns the extension associated with the given day value.

sub ext {
    return 'st' if($_[0] == 1 ||$_[0] == 21 || $_[0] == 31);
    return 'nd' if($_[0] == 2 ||$_[0] == 22);
    return 'rd' if($_[0] == 3 ||$_[0] == 23);
    return 'th';
}

=item dotw( day | dayname )

Returns the day number (0..6) if passed the day name, or the day
name if passed a numeric.

=cut

sub dotw {
    return $dotw[$_[0]] if($_[0] =~ /\d/);

    foreach my $inx (0..6) {
        return $inx if($_[0] =~ /$dotw[$inx]/i);
    }

    return;
}

=item moty( month | monthname )

Returns the month number (1..12) if passed the month name, or the month
name if passed a numeric.

=cut

sub moty {
    return $months[$_[0]]   if($_[0] =~ /\d/);

    foreach my $inx (1..12) {
        return $inx if($_[0] =~ /$months[$inx]/i);
    }

    return;
}

=item fail_range( year )

Returns true or false based on whether the date given will break the
basic date range, 01-01-1902 to 31-12-2037.

=cut

sub fail_range {
    return 1    unless($_[0]);
    return 0    if($dt || $di);
    return 1    if($_[0] < $MinYear || $_[0] > $MaxYear);
    return 0;
}

sub _caltest {
    $dt = $_[0] if($dt);
    $di = $_[1] if($di);
}

1;

__END__

#----------------------------------------------------------------------------

=back

=head1 DATE FORMATS

=over 4

=item Parameters

The date formatting parameters passed to the two formatting functions can
take many different formats. A formatting string can contain several key
strings, which will be replaced with date components. The following are
key strings which are currently supported:

  DD
  MM
  YYYY
  DAY
  MONTH
  DDEXT
  DMY
  MDY
  YMD
  MABV
  DABV

The first three are tranlated into the numerical day/month/year strings.
The DAY format is translated into the day of the week name, and MONTH
is the month name. DDEXT is the day with the appropriate suffix, eg 1st,
22nd or 13th. DMY, MDY and YMD default to '13-09-1965' (DMY) style strings.
MABV and DABV provide 3 letter abbreviations of MONTH and DAY respectively.

=back

=head1 DATE MODULES

Internal to this module is some date comparison code. As a consequence this
requires some date modules that can handle a wide range of dates. There are
three modules which are tested for you, these are, in order of preference,
DateTime, Date::ICal and Time::Local.

Each module has the ability to handle dates, although only Time::Local exists
in the core release of Perl. Unfortunately Time::Local is limited by the
Operating System. On a 32bit machine this limit means dates before 1st January
1902 and after 31st December 2037 will not be represented. If this date range
is well within your scope, then you can safely allow the module to use
Time::Local. However, should you require a date range that exceedes this
range, then it is recommended that you install one of the two other modules.

=head1 ERROR HANDLING

In the event that Time::Local is being used and dates that exceed the range
of 1st January 1902 to 31st December 2037 are passed, an undef is returned.

=head1 SEE ALSO

  Date::ICal
  DateTime
  Time::Local
  Time::Piece

  The Calendar FAQ at http://www.tondering.dk/claus/calendar.html

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-List

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 THANKS TO

Dave Cross, E<lt>dave at dave.orgE<gt> for creating Calendar::Simple, the
newbie poster on a technical message board who inspired me to write the
original wrapper code and Richard Clamp E<lt>richardc at unixbeard.co.ukE<gt>
for testing the beta versions.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
