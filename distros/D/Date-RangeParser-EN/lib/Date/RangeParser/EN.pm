package Date::RangeParser::EN;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Parse plain English date/time range strings
use version;
our $VERSION = 'v1.2.0'; # VERSION

use strict;
use warnings;
use utf8;

use Date::Manip;
use DateTime;

my $dm_backend = $Date::Manip::Backend || '';
if ($Date::Manip::VERSION lt '6' or $dm_backend eq 'DM5') {
    warnings::warnif 'deprecated', "Versions of Date::Manip prior to 6.0.0 and DM5 backend will be deprecated in future releases.";
}

#pod =head1 NAME
#pod
#pod Date::RangeParser::EN - Parser for plain English date/time range strings
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Date::RangeParser::EN;
#pod
#pod     my $parser = Date::RangeParser::EN->new;
#pod     my ($begin, $end) = $parser->parse_range("this week");
#pod
#pod =head1 DESCRIPTION
#pod
#pod Parses plain-English strings representing date/time ranges
#pod
#pod =cut

my %BOD = (hour =>  0, minute =>  0, second =>  0);
my %EOD = (hour => 23, minute => 59, second => 59);
my %BOY = (month => 1, day => 1, %BOD);
my %EOY = (month => 12, day=> 31, %EOD);

my $US_FORMAT_WITH_DASHES = qr/^ (0[1-9]|1[012]) - (0[1-9]|[12][0-9]|3[01]) - ( (?:[12][0-9]) [0-9]{2} ) $/x;

my %weekday = (
    sunday    => 0,
    monday    => 1,
    tuesday   => 2,
    wednesday => 3,
    thursday  => 4,
    friday    => 5,
    saturday  => 6,
);

my $weekday = qr/(?:mon|tues|wednes|thurs|fri|satur|sun)day/;

my %ordinal = (
    qr/\bfirst\b/           => "1st",  qr/\bsecond\b/           => "2nd",
    qr/\bthird\b/           => "3rd",  qr/\bfourth\b/           => "4th",
    qr/\bfifth\b/           => "5th",  qr/\bsixth\b/            => "6th",
    qr/\bseventh\b/         => "7th",  qr/\beighth\b/           => "8th",
    qr/\bninth\b/           => "9th",  qr/\btenth\b/            => "10th",
    qr/\beleventh\b/        => "11th", qr/\btwelfth\b/          => "12th",
    qr/\bthirteenth\b/      => "13th", qr/\bfourteenth\b/       => "14th",
    qr/\bfifteenth\b/       => "15th", qr/\bsixteenth\b/        => "16th",
    qr/\bseventeenth\b/     => "17th", qr/\beighteenth\b/       => "18th",
    qr/\bnineteenth\b/      => "19th", qr/\btwentieth\b/        => "20th",
    qr/\btwenty-?first\b/   => "21st", qr/\btwenty-?second\b/   => "22nd",
    qr/\btwenty-?third\b/   => "23rd", qr/\btwenty-?fourth\b/   => "24th",
    qr/\btwenty-?fifth\b/   => "25th", qr/\btwenty-?sixth\b/    => "26th",
    qr/\btwenty-?seventh\b/ => "27th", qr/\btwenty-?eighth\b/   => "28th",
    qr/\btwenty-?ninth\b/   => "29th", qr/\bthirtieth\b/        => "30th",
    qr/\bthirty-?first\b/   => "31st",
    qr/\bone\b/             => "1",    qr/\btwo\b/              => "2",
    qr/\bthree\b/           => "3",    qr/\bfour\b/             => "4",
    qr/\bfive\b/            => "5",    qr/\bsix\b/              => "6",
    qr/\bseven\b/           => "7",    qr/\beight\b/            => "8",
    qr/\bnine\b/            => "9",    qr/\bten\b/              => "10",
    qr/\beleven\b/          => "11",   qr/\btwelve\b/           => "12",
    qr/\bthirteen\b/        => "13",   qr/\bfourteen\b/         => "14",
    qr/\bfifteen\b/         => "15",   qr/\bsixteen\b/          => "16",
    qr/\bseventeen\b/       => "17",   qr/\beighteen\b/         => "18",
    qr/\bnineteen\b/        => "19",   qr/\btwenty\b/           => "20",
    qr/\btwenty-one\b/      => "21",   qr/\btwenty-two\b/       => "22",
    qr/\btwenty-three\b/    => "23",   qr/\btwenty-four\b/      => "24",
    qr/\btwenty-five\b/     => "25",   qr/\btwenty-six\b/       => "26",
    qr/\btwenty-seven\b/    => "27",   qr/\btwenty-eight\b/     => "28",
    qr/\btwenty-nine\b/     => "29",   qr/\bthirty\b/           => "30",
    qr/\bthirty-one\b/      => "31",
);

my %month = (
    qr/jan(?:uary)?/    => 1,   qr/feb(?:ruary)?/   => 2,
    qr/mar(?:ch)?/      => 3,   qr/apr(?:il)?/      => 4,
    qr/may/             => 5,   qr/jun(?:e)?/       => 6,
    qr/jul(?:y)?/       => 7,   qr/aug(?:ust)?/     => 8,
    qr/sep(?:tember)?/  => 9,   qr/oct(?:ober)?/    => 10,
    qr/nov(?:ember)?/   => 11,  qr/dec(?:ember)?/   => 12,
);

my $month_re = qr/\b(?:
    a(?:pr(?:il)?|ug(?:ust)?)       |
    dec(?:ember)?                   |
    feb(?:ruary)?                   |
    j(?:an(?:uary)?|u(?:ne?|ly?))   |
    ma(?:y|r(?:ch)?)                |
    nov(?:ember)?                   |
    oct(?:ober)?                    |
    sep(?:tember)?
    )\b/x;

#pod =head1 METHODS
#pod
#pod =head2 new
#pod
#pod Returns a new instance of Date::RangeParser::EN.
#pod
#pod Takes an optional hash of parameters:
#pod
#pod =over 4
#pod
#pod =item * B<datetime_class>
#pod
#pod By default, Date::RangeParser::EN returns two L<DateTime> objects representing the beginning and end of the range. If you use a subclass of DateTime (or another module that implements the DateTime API), you may pass the name of this class to use it instead.
#pod
#pod At the very least, this given class must implement a C<new> method that accepts a hash of arguments, where the following keys will be set:
#pod
#pod   year
#pod   month
#pod   day
#pod   hour
#pod   minute
#pod   second
#pod
#pod This gives you the freedom to set your time zones and such however you need to.
#pod
#pod =item * B<infinite_past_class>
#pod =item * B<infinite_future_class>
#pod
#pod By default, Date::RangeParser::EN uses DateTime::Infinite::Past and DateTime::Infinite::Future to create open-ended ranges (for example "after today"). If you have extended these classes, you may pass the corresponding names in.
#pod
#pod The given classes must implement a C<new> method that accepts no arguments.
#pod
#pod =item * B<now_callback>
#pod
#pod By default, Date::RangeParser::EN uses DateTime->now to determine the current date/time for calculations. If you need to work with a different time (for instance, if you need to adjust for time zones), you may pass a callback (code reference) which returns a DateTime object.
#pod
#pod =back
#pod
#pod =cut

sub new
{
    my ($class, %params) = @_;

    my $self = \%params;

    bless $self, $class;

    return $self;
}

#pod =head2 parse_range
#pod
#pod Accepts a string representing a plain-English date range, for instance:
#pod
#pod =over 4
#pod
#pod =item * today
#pod
#pod =item * this week
#pod
#pod =item * the past 2 months
#pod
#pod =item * next Tuesday
#pod
#pod =item * two weeks ago
#pod
#pod =item * the next 3 hours
#pod
#pod =item * the 3rd of next month
#pod
#pod =item * the end of this month
#pod
#pod =back
#pod
#pod More formally, this will parse the following kinds of date strings:
#pod
#pod   NUMBER : ordinary number (1)
#pod   PERIOD : one of: hour, day, week, month, quarter, or year (or the plural of these)
#pod   WEEKDAY : one of: Monday, Tuesday, Wedensday, Thursday, Friday, Saturday, or Sunday
#pod   CARDINAL : a cardinal number (21st) or the word for that number (twenty-first) or end
#pod   MONTH : a month name: January, Feburary, March, April, May, June, July August, 
#pod           September, October, November, or Decmeber or any 3-letter abbreviation
#pod   YEAR : a 4-digit year (2-digits will not work)
#pod   TIMES: January 1st, 2000 at 10:00am through January 1st, 2000 at 2:00pm
#pod   RANGE : any date range that can be parsed by parse_range
#pod   ELEMENT : any element of a date range that can be parsed by parse_range
#pod
#pod   today                             : today, midnight to midnight
#pod
#pod   this PERIOD                       : the current period, start to end
#pod   this month
#pod
#pod   current PERIOD                    : the current period, start to end
#pod   current year
#pod
#pod   this WEEKDAY                      : the WEEKDAY that is in the current week, midnight to midnight
#pod   this Monday
#pod
#pod   NUMBER PERIOD ago                 : past date relative to now until now
#pod   3 days ago
#pod
#pod   past NUMBER PERIOD                : past date relative to now until now
#pod   past 2 weeks
#pod
#pod   last NUMBER PERIOD                : past date relative to now until now
#pod   last 6 hours
#pod
#pod   past NUMBER WEEKDAY               : the weekday a number of weeks before now until now
#pod   past 4 Saturdays
#pod
#pod   NUMBER WEEKDAY ago                : the weekday a number of weeks before now until now
#pod   3 Fridays ago
#pod
#pod   yesterday                         : yesterday, midnight to midnight
#pod
#pod   last WEEKDAY                      : the WEEKDAY that is in the week prior to this, midnight to midnight
#pod   last Wednesday
#pod
#pod   previous WEEKDAY                  : the WEEKDAY that is in the week prior to this, midnight to midnight
#pod   previous Friday
#pod
#pod   past WEEKDAY                      : the WEEKDAY that is in the week prior to this, midnight to midnight
#pod   past Tuesday
#pod
#pod   this past WEEKDAY                 : the WEEKDAY that is in the week prior to this, midnight to midnight
#pod   this past Saturday
#pod
#pod   coming WEEKDAY                    : the WEEKDAY that is in the week after this, midnight to midnight
#pod   coming Monday
#pod
#pod   this coming WEEKDAY               : the WEEKDAY that is in the week after this, midnight to midnight
#pod   this coming Thursday
#pod
#pod   NUMBER Business days ago          : past number of business days relative to now until now
#pod
#pod   NUMBER weekdays ago               : past number of weekdays relative to now until now
#pod
#pod   LAST or PAST NUMBER weekdays ago  : past number of weekdays relative to now until now
#pod
#pod   NUMBER PERIOD hence               : now to a future date relative to now
#pod   4 months hence
#pod
#pod   NUMBER PERIOD from now            : now to a future date relative to now
#pod   6 days from now
#pod
#pod   next NUMBER PERIOD                : now to a future date relative to now
#pod   next 7 years
#pod
#pod   tomorrow                          : tomorrow, midnight to midnight
#pod
#pod   next NUMBER WEEKDAY               : the WEEKDAY that is in a number of weeks after this, midnight to midnight
#pod   next 4 Sundays
#pod
#pod   CARDINAL of this month            : the specified day of the current month, midnight to midnight
#pod   14th of this month
#pod
#pod   CARDINAL of last month            : the specified day of the previous month, midnight to midnight
#pod   31st of last month
#pod
#pod   CARDINAL of next month            : the specified day of the month following this, midnight to midnight
#pod   3rd of next month
#pod
#pod   CARDINAL of NUMBER months ago     : the specified day of a previous month, midnight to midnight
#pod   12th of 2 months ago
#pod
#pod   CARDINAL of NUMBER months from now : the specified day of a following month, midnight to midnight
#pod   7th of 22 months from now
#pod
#pod   CARDINAL of NUMBER months hence   : the specified day of a following month, midnight to midnight
#pod   22nd of 6 months hence
#pod
#pod   CARDINAL of TIME                  : the specific time of day which can be accompanied by a date
#pod   10:00am through 12:00pm             defaults to today if no date is given
#pod
#pod   MONTH                             : the named month of the current year, 1st to last day
#pod   August
#pod
#pod   this MONTH                        : the named month of the current year, 1st to last day
#pod   this Sep
#pod
#pod   last MONTH                        : the named month of the previous year, 1st to last day
#pod   last January
#pod
#pod   next MONTH                        : the named month of the next year, 1st to last day
#pod   next Dec
#pod
#pod   MONTH YEAR                        : the named month of the named year, 1st to last day
#pod   June 1969
#pod
#pod   RANGE to RANGE                    : the very start of the first range to the very end of the second
#pod   Tuesday to Next Saturday
#pod
#pod   RANGE thru RANGE                  : the very start of the first range to the very end of the second
#pod   2 hours ago thru the next 6 hours
#pod
#pod   RANGE through RANGE               : the very start of the first range to the very end of the second
#pod   August through December
#pod
#pod   RANGE - RANGE                     : the very start of the first range to the very end of the second
#pod   9-1-2012 - 9-30-2012
#pod
#pod   RANGE-RANGE                       : the very start of the first range to the very end of the second
#pod   10/10-10/20                         (ranges must not contain hyphens, "-")
#pod
#pod   American style dates              : Month / Day / Year
#pod   6/15/2000
#pod
#pod   before ELEMENT                    : all dates before the very start of the date specified in the ELEMENT
#pod        < ELEMENT
#pod   before today
#pod
#pod   <= ELEMENT                        : all dates up to the very end of the date specified in the ELEMENT
#pod   <= today
#pod
#pod   after ELEMENT                     : all dates after the very end of the date specified in the ELEMENT
#pod       > ELEMENT
#pod   after next Tuesday
#pod
#pod   >= ELEMENT                        : the date specified in the ELEMENT to the end of forever
#pod   >= this Friday
#pod
#pod   since ELEMENT                     : the date specified in the ELEMENT to the end of the current day
#pod   since last Sunday
#pod
#pod Anything else is parsed by L<Date::Manip>. If Date::Manip is unable to parse the
#pod date given either, then the dates returned will be undefined.
#pod
#pod Also, when parsing:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod The words "the" and "and" will always be ignored and can appear anywhere.
#pod
#pod =item *
#pod
#pod Cardinal numbers may be spelled out as words, i.e. "September first" instead of
#pod "September 1st". Similarly, "two weeks ago" and "2 weeks ago" will be treated as the same
#pod
#pod =item * 
#pod
#pod Any plural or singular period shown above can be used with the opposite.
#pod
#pod =item *
#pod
#pod All dates are parsed relative to the parser's notion of now. You can control
#pod this by setting the C<now_callback> option on the constructor.
#pod
#pod =back
#pod
#pod Returns two L<DateTime> objects, representing the beginning and end of the range.
#pod
#pod =cut

sub parse_range
{
    my ($self, $string, %params) = @_;
    my ($beg, $end, $y, $m, $d);

    $string = lc $string;

    # The words "the" and "and" may be used with ridiculous impunity
    $string =~ s/\bthe\b//g;
    $string =~ s/\band\b//g;

    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;
    $string =~ s/\s+/ /g;

    # We address the ordinals (let's not get silly, though).  If we wanted
    # to get silly, we'd use Lingua::EN::Words2Nums, which would horribly
    # complicate the general parsing
    while (my ($str, $num) = each %ordinal)
    {
        $string =~ s/$str/$num/g;
    }
    # at this point, we may have changed the word 'second' into '2nd'
    # when we did not mean to. So we swap back. We do this outside of
    # the while loop above, because this function is recursive, and
    # the following regex is anchored to the end of the string.
    $string =~ s/2nd$/second/;

    # Handle weekdays as we do business days
    if ($string =~ /^(?:last|past)\s?(\d+)?\s?weekdays?/) {
        my $interval = $1 || 1;
        $string =~ s/^(?:last|past)\s?(\d+)?\s?weekdays?/$interval business days ago/;
    }

    # Sometimes we get a bare US style date, but the user has used dashes.
    # Let's de-scramble that before moving on.
    $string = $self->_convert_from_us_dashed($string);

    if ($string =~ /\s(?:to|thru|through|-|–|—)\s/) 
    {
        my ($first, $second) = split /\s+(?:to|thru|through|-|–|—)\s+/, $string, 2;

        ($beg) = $self->parse_range($first);
        (undef, $end) = $self->parse_range($second);
    }

    # See if this is a range between two other dates separated by -
    elsif ($string !~ /^\d+-\d+$/ and $string =~ /^[^-]+-[^-]+$/) 
    {
        my ($first, $second) = split /\s?-\s?/, $string, 2;
        ($beg) = $self->parse_range($first);
        (undef, $end) = $self->parse_range($second);
    }

    # "This thing" and "current thing"
    elsif ($string eq "today" || $string =~ /^(?:this|current) day$/)
    {
        $beg = $self->_bod();
        $end = $self->_eod();
    }
    elsif ($string =~ /^(?:this|current) hour$/) {
        $beg = $self->_now()->set(minute => 0, second => 0);
        $end = $beg->clone->set(minute => 59, second => 59);
    }
    elsif ($string =~ /^(?:this|current) minute$/) {
        $beg = $self->_now()->set(second => 0);
        $end = $beg->clone->set(second => 59);
    }
    elsif ($string =~ /^(?:this|current) second$/) {
        # Relly this comes from this or current second,
        # but our ordinals messed this up.
        $beg = $self->_now();
        $end = $beg->clone;
    }
    elsif ($string =~ /^(?:this|current) week$/)
    {
        my $dow = $self->_now()->day_of_week % 7;       # Monday == 1
        $beg = $self->_bod()->subtract(days => $dow);   # Subtract to Sunday
        $end = $self->_eod()->add(days => 6 - $dow);    # Add to Saturday
    }
    elsif ($string =~ /^(?:this|current) month$/)
    {
        $beg = $self->_bod()->set_day(1);
        $end = $self->_datetime_class()->last_day_of_month(
            year => $self->_now()->year,
            month => $self->_now()->month,
            %EOD);
    }
    elsif ($string =~ /^(?:this|current) quarter$/)
    {
        my $zq = int(($self->_now()->month - 1) / 3);     # 0..3
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1);
        $end = $self->_datetime_class()->last_day_of_month(
            year => $self->_now()->year,
            month => $zq * 3 + 3 ,
            %EOD);
    }
    elsif ($string =~ /^(?:this|current) year$/)
    {
        $beg = $self->_datetime_class()->new(year => $self->_now()->year, %BOY);
        $end = $self->_datetime_class()->new(year => $self->_now()->year, %EOY);
    }
    elsif ($string =~ /^this ($weekday)$/)
    {
        my $dow = $self->_now()->day_of_week % 7;           # Monday == 1
        my $adjust = $weekday{$1} - $dow;
        if ($adjust < 0)
        {
            $beg = $self->_bod()->subtract(days => abs($adjust));
        }
        elsif ($adjust > 0)
        {
            $beg = $self->_bod()->add(days => $adjust);
        }
        else
        {
            $beg = $self->_bod();
        }
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # "Last N things" and "Past N things"
    elsif ($string =~ /^(?:last|past) (\d+)?\s?(hour|minute|second)s?$/)
    {
        my $unit = $self->_clean_units($2);
        my $offset = $1;

        # The "+0" math avoids call-by-reference side effects
        $beg = $self->_now();
        $beg->subtract($unit => $offset // 1 + 0);
        $end = $self->_now();

        if ($unit eq 'hours') {
            $beg->set(minute => 0, second => 0);
            $end->set(minute => 59, second => 59);
        } elsif ($unit eq 'minutes') {
            $beg->set(second => 0);
            $end->set(second => 59);
        }
    }
    elsif ($string =~ /^(?:last|past) (\d+) days?$/)
    {
        $beg = $self->_bod()->subtract(days => $1 - 1);
        $end = $self->_eod();
    }
    elsif ($string =~ /^(?:last|past) (\d+) weeks?$/)
    {
        my $offset = $self->_now()->day_of_week % 7; # sun offset: 0 ... sat offset: 6
        $beg = $self->_bod()->subtract(days => $offset)->subtract(weeks => $1 - 1); # sunday
        $end = $self->_eod()->add(days => 6 - $offset); #saturday of current week
    }
    elsif ($string =~ /^(?:last|past) (\d+) months?$/)
    {
        $beg = $self->_bod()->set_day(1)->subtract(months => $1 - 1);
        $end = $self->_datetime_class()->last_day_of_month(
            year => $self->_now()->year,
            month => $self->_now()->month,
            %EOD);
    }
    elsif ($string =~ /^(?:last|past) (\d+) years?$/)
    {
        $beg = $self->_bod()->set_month(1)->set_day(1)->subtract(years => $1 - 1);
        $end = $self->_eod()->set_month(12)->set_day(31);
    }
    elsif ($string =~ /^(?:last|past) (\d+) quarters?$/)
    {
        my $zq = int(($self->_now()->month - 1) / 3);
        $end = $self->_bod()->set_month($zq * 3 + 1)->set_day(1)
                    ->add(months => 3)->subtract(seconds => 1);
        $beg = $end->clone->set_day(1)
                   ->subtract(months => (3 * $1) - 1)
                   ->subtract(days => 1)->add(seconds => 1);
     }
    elsif ($string =~ /^(?:last|past) (\d+) ($weekday)s?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;          # Monday == 1
        my $adjust = $weekday{$2} - $dow;
        $adjust -= 7 if $adjust >=0;
        $adjust -= 7*($1 - 1);
        $end = $self->_eod()->subtract(days => abs($adjust));
        $beg = $end->clone->subtract(days => 7*($c-1)+1)->add(seconds => 1);
    }
    # "Last thing" and "Previous thing"
    elsif ($string =~ /^yesterday$/)
    {
        $beg = $self->_bod()->subtract("days" => 1);
        $end = $beg->clone->set(%EOD);
    }
    elsif ($string =~ /^(?:last|previous) week$/)
    {
        my $dow = $self->_now()->day_of_week % 7;           # Monday == 1
        $beg = $self->_bod()->subtract(days => 7 + $dow);   # Subtract to last Sunday
        $end = $self->_eod()->subtract(days => 1 + $dow);   # Subtract to Saturday
    }
    elsif ($string =~ /^(?:last|previous) month$/)
    {
        $beg = $self->_bod()->set_day(1)->subtract(months => 1);
        $end = $self->_bod()->set_day(1)->subtract(seconds => 1);
    }
    elsif ($string =~ /^(?:last|previous) quarter$/)
    {
        my $zq = int(($self->_now()->month - 1) / 3);
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1)->subtract(months => 3);
        $end = $beg->clone->add(months => 3)->subtract(seconds => 1);
    }
    elsif ($string =~ /^(?:last|previous) year$/)
    {
        $beg = $self->_bod()->set_month(1)->set_day(1)->subtract(months => 12);
        $end = $self->_bod()->set_month(1)->set_day(1)->subtract(seconds => 1);
    }
    elsif ($string =~ /^(?:last|previous) ($weekday)$/) {
        my $dow = $self->_now()->day_of_week % 7;           # Monday == 1
        my $adjust = $weekday{$1} - $dow - 7;
        $beg = $self->_bod()->subtract(days => abs($adjust));
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # "Past weekday" and "This past weekday"
    elsif ($string =~ /^(?:this )?past ($weekday)$/)
    {
        my $dow = $self->_now()->day_of_week % 7;           # Monday == 1
        my $adjust = $weekday{$1} - $dow;
        $adjust -= 7 if $adjust >= 0;
        $beg = $self->_bod()->subtract(days => abs($adjust));
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }

    # Dates ago
    elsif ($string =~ /^(\d+) ((?:month|day|week|year|quarter)s?) ago$/)
    {
        # "N months|days|weeks|years|quarters ago"
        my $ct = $1 + 0;
        my $unit = $self->_clean_units($2);

        if($unit eq 'quarters') {
            $unit = 'months';
            $ct *= 3;
        }

        $beg = $self->_bod()->subtract($unit => $ct);
        $end = $beg->clone->set(%EOD);
    }

    # Strictly time ago
    elsif ($string =~ /^(\d+) ((?:hour|minute|second)s?) ago$/) {
        my $ct = $1 + 0;
        my $unit = $self->_clean_units($2);

        $beg = $self->_now()->subtract($unit => $ct);

        if ($unit eq 'hours') {
            $beg->set(minute => 0, second => 0);
            $end = $beg->clone()->set(minute => 59, second => 59);
        } elsif($unit eq 'minutes') {
            $beg->set(second => 0);
            $end = $beg->clone()->set(second => 59);
        } elsif($unit eq 'seconds') {
            $end = $self->_now();
        }
    }

    # N <Day of the week>s ago
    elsif ($string =~ /^(\d+) ($weekday)s? ago$/) {
        my $dow = $self->_now()->day_of_week % 7;          # Monday == 1
        my $adjust = $weekday{$2} - $dow;
        $adjust -= 7 if $adjust >=0;
        $adjust -= 7*($1 - 1);
        $beg = $self->_bod()->subtract(days => abs($adjust));
        $end = $beg->clone->set(%EOD);
    }

    # Hence from now portions
    elsif ($string =~ /^(\d+) ($weekday)s? (?:hence|from\s+now)$/) {
        # That's both "next sunday" and "3 sundays from now"
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;        # Monday == 1
        my $adjust = $weekday{$2} - $dow;        # get to right day of week
        $adjust += 7 if $adjust <= 0;            # add 7 days if its today or in the past
        $adjust += 7*($c - 1);
        $beg = $self->_bod()->add(days => $adjust);
        $end = $beg->clone->set(%EOD);
    }
    elsif ($string =~ /^(\d+)? weeks? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(weeks => $1);
    }
    # from now pieces
    elsif ($string =~ /^(\d+)? days? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(days => $1);
    }
    elsif ($string =~ /^next (\d+)?\s?($weekday)s?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;        # Monday == 1
        my $adjust = $weekday{$2} - $dow;        # get to right day of week
        $adjust += 7 if $adjust <= 0;            # add 7 days if its today or in the past
        $beg = $self->_bod()->add(days => $adjust);
        $adjust += 7*($c - 1);
        $end = $beg->clone->add(days => 7*$c - 6)->subtract(seconds => 1);
    }
    # "Coming weekday" and "This coming weekday"
    elsif ($string =~ /^(?:this )?coming ($weekday)$/)
    {
        my $dow = $self->_now()->day_of_week % 7;           # Monday == 1
        my $adjust = $weekday{$1} - $dow;
        $adjust += 7 if $adjust <= 0;
        $beg = $self->_bod()->add(days => $adjust);
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # "Next thing" and "Next N things"
    elsif ($string =~ /^next (\d+)?\s?(second|minute|hour)s?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $unit = $self->_clean_units($2);

        $beg = $self->_now();
        $end = $beg->clone->add($unit => $c);
    }
    elsif ($string =~ /^(?:next (\d+)?\s?days?|tomorrow)$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->add(days => 1);
        $end = $beg->clone->add(days => $c)->subtract(seconds => 1)
    }
    elsif ($string =~ /^next (\d+)?\s?weeks?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;        # Monday == 1
        $beg = $self->_bod()->add(days => 7 - $dow);        # Add to Sunday
        $end = $self->_eod()->add(days => 6 + 7*$c - $dow); # Add N Saturdays following
    }
    elsif ($string =~ /^next (\d+)?\s?months?$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->add(months => 1, end_of_month => 'preserve')->set_day(1);
        my $em = $self->_now()->add(months => $c, end_of_month => 'preserve');
        $end = $self->_datetime_class()->last_day_of_month(year => $em->year, month => $em->month, %EOD);
    }
    elsif ($string =~ /^next (\d+)?\s?quarters?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $zq = int(($self->_now()->month - 1) / 3);
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1)
                    ->add(months => 3, end_of_month => 'preserve');
        $end = $beg->clone ->add(months => 3 * $c, end_of_month => 'preserve')
                    ->subtract(seconds => 1);
    }
    # Add support for N quarters from now
    elsif ($string =~ /^(\d+)?\s?quarters? (?:hence|from\s+now)$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $zq = int(($self->_now()->month - 1) / 3);
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1)
                    ->add(months => 3, end_of_month => 'preserve');
        $end = $beg->clone ->add(months => 3, end_of_month => 'preserve')
                    ->subtract(seconds => 1);
    }
    elsif ($string =~ /^next (\d+)?\s?years?$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->set_month(1)->set_day(1)->add(years => 1);
        $end = $self->_eod()->set_month(12)->set_day(31)->add(years => $c);
    }
    elsif ($string =~ /^next (\d+)?\s?($weekday)s?$/)
    {
        # That's both "next sunday" and "3 sundays from now"
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;        # Monday == 1
        my $adjust = $weekday{$2} - $dow;        # get to right day of week
        $adjust += 7 if $adjust <= 0;            # add 7 days if its today or in the past
        $adjust += 7*($c - 1);
        $beg = $self->_bod()->add(days => $adjust);
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # The something of the month (or this, last, next, or previous...)
    elsif ($string =~ /^(\d+(?:st|nd|rd|th)?|end) of (this|last|next) month$/)
    {
        $beg = $self->_bod()->set_day(1);

        if ($2 eq "last") {
            $beg = $beg->subtract(months => 1);
        } elsif ($2 eq "next") {
            $beg = $beg->add(months => 1);
        }

        if ($1 eq "end") {
            $beg = $beg->add(months => 1)->add(days => -1);
        } else {
            my ($d) = $1 =~ /(^\d+)/;   # remove st/nd/rd/th
            $beg = $beg->set_day($d);
        }

        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # Add support for N (Time) from now
    elsif ($string =~ /^(\d+) seconds? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(seconds => $1);
    }
    elsif ($string =~ /^(\d+) minutes? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(minutes => $1);
    }
    elsif ($string =~ /^(\d+) hours? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(hours => $1);
    }
    elsif ($string =~ /^(\d+)? months? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(months => $1);
    }
    elsif ($string =~ /^(\d+)? years? (?:hence|from\s+now)$/) {
        $beg = $self->_now();
        $end = $beg->clone->add(years => $1);
    }
    # The something of N month (ago|from now|hence)
    elsif ($string =~ /^(\d+(?:st|nd|rd|th)?|end) of (\d+) months? (ago|from now|hence)$/)
    {
        $beg = $self->_bod()->set_day(1);

        my $n = $2;     # Avoid call-by-reference side effects in add/subtract

        if ($3 eq "ago") {
            $beg = $beg->subtract(months => $n);
        } elsif ($3 eq "from now" || $3 eq "hence") {
            $beg = $beg->add(months => $n);
        }

        if ($1 eq "end") {
            $beg = $beg->add(months => 1)->add(days => -1);
        } else {
            my ($d) = $1 =~ /(^\d+)/;   # remove st/nd/rd/th
            $beg = $beg->set_day($d);
        }

        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # Handle rewriting things with months in them
    elsif ($string =~ /^(this|last|next)?\s?($month_re)$/)
    {
        my ($y, $m) = ($1, $2);
        if (defined $y and $y eq 'last') {
            $y = $self->_now->year - 1;
        } elsif (defined $y and $y eq 'next') {
            $y = $self->_now->year + 1;
        } else {
            $y = $self->_now->year;
        }
        while (my ($re, $val) = each %month) {
            if ($m =~ /$re/) {
                $m = $val;
                keys %month;    # Reset each counter
                last;
            }
        }
        $beg = $self->_bod()->set(year => $y, month => $m, day => 1);
        $end = $self->_datetime_class()->last_day_of_month(year => $y, month => $m, %EOD);
    }

    # Match a month with a 4-digit year
    elsif ($string =~ /^($month_re)\s+(\d{4})$/) 
    {
        my ($y, $m) = ($2, $1);
        while (my ($re, $val) = each %month) {
            if ($m =~ /$re/) {
                $m = $val;
                keys %month;    # Reset each counter
                last;
            }
        }
        $beg = $self->_bod()->set(year => $y, month => $m, day => 1);
        $end = $self->_datetime_class()->last_day_of_month(year => $y, month => $m, %EOD);
    }

    elsif ($string =~ /^<=/) {
        $string =~ s/^<=//;
        $beg   = $self->_infinite_past_class->new();
        (undef, $end) = $self->parse_range($string);
    }
    elsif ($string =~ /^(?:before |<)/i) {
        $string =~ s/^(?:before |<)//i;
        ($end) = $self->parse_range($string);

        if ( defined $end ) {
            $beg = $self->_infinite_past_class->new();
            $end = $end->subtract(seconds => 1);
        }
    }

    elsif ($string =~ /^>=/) {
        $string =~ s/^>=//;
        ($beg) = $self->parse_range($string);
        $end   = $self->_infinite_future_class->new();
    }
    elsif ($string =~ /^(?:after |>)/i) {
        $string =~ s/^(?:after |>)//i;
        (undef, $beg) = $self->parse_range($string);

        if ( defined $beg ) {
            $beg = $beg->add(seconds => 1);
            $end = $self->_infinite_future_class->new();
        }
    }

    elsif ($string =~ /^since /i) {
        $string =~ s/^since //i;
        ($beg) = $self->parse_range($string);
        # Merriam-Webster defines since as "from a definite past time until now",
        # thus $end is the end of the day today and not infinity.
        $end = $self->_now()->clone->set(%EOD);
    }

    # If all else fails, see if Date::Manip can figure this out
    # If some component of the date or time is missing, Date::Manip
    # will default it, generally to 00.
    elsif (($beg, my $incomplete) = $self->_parse_date_manip($string))
    {
        # We have dropped into date manip because the previous cases have not
        # been triggered. Generally speaking that means we have to deal with
        # when there is a time given in addition to a date.

        $end = $beg->clone;

        # If we think that we got a complete datetime object but did not.
        # Primarily, we need this to help us out with our business day logic.
        if (!scalar @$incomplete) {
            # business days ago is always one day long.
            if ($string =~ /^(\d+)? (business day)(s?) ago$/) {
                $beg->set(%BOD);
                $end = $beg->clone()->set(%EOD);
            }

            # past N business days
            # generally includes today, unless it is being run on a weekend.
            if ($string =~ /^past (\d+)? (business day)(s?)$/) {

                $beg->set(%BOD);
                my $bdow = $beg->day_of_week % 7;         # Monday == 1

                $end = $self->_now()->set(%EOD);
                my $edow = $end->day_of_week % 7;         # Monday == 1

                # Back up if today is not a business day.
                # But keep Date::Manip's starting date

                if ($edow == 0) {
                    # Sunday
                    $end->subtract(days => 2);
                } elsif($edow == 6) {
                    # Saturday
                    $end->subtract(days => 1);
                }

                # We generally disagree with Date::Manip's starting date if
                # today is a weekday, so potentially move the starting date forward.
                # But, how far to move it depends on what day it is.
                elsif ($bdow == 5) {
                    # Include today since we are on a weekday.
                    # Date manip goes back one day too far.
                    $beg->add(days => 3);
                } else {
                    $beg->add(days => 1);
                }
            }

            # Dates in the MM/DD/YYYY format will have beginning and ending
            # time of midnight; however, we want them to be the entire day;
            # so, we set the end time to the end of the day.
            #
            # However, the user can specify midnight, which looks just the
            # same to us; so, we don't extend the range in those cases.
            #
            # TODO: Handle other ways of specifying midnight or fix
            # Date::Manip so that it doesn't return an empty incomplete array.
            if (  $beg->hms eq "00:00:00"
                && $end->hms eq "00:00:00"
                && $string !~ /(midnight|00:00:00|12(:00){0,2}AM)/  ) {
                    $end->set(%EOD);
            }
        }

        # If Date::Manip had to supply defaults for some parts,
        # it gave the earliest possible datetime.
        # For the end of the range, we swap those defaults with
        # the latest possible.
        for my $component (@$incomplete){
            if($component eq 'day'){
                $end->add(months => 1)->subtract(days => 1);
            }
            else{
                $end->set($component => $EOY{$component});
            }
        }
    }

    else
    {
        return ();
    }

    return ($beg, $end);
}

sub _bod {
    my $self = shift;
    my $now = $self->_now();
    return $now->set(%BOD);
}

sub _eod {
    my $self = shift;
    my $now = $self->_now();
    return $now->set(%EOD);
}

sub _now {
    my $self = shift;

    if (my $cb = $self->{now_callback}) {
        return &$cb($self);
    }

    return $self->_datetime_class->now;
}

sub _datetime_class {
    my $self = shift;
    return $self->{datetime_class} || 'DateTime';
}

sub _infinite_future_class {
    my $self = shift;
    return $self->{infinite_future_class} || 'DateTime::Infinite::Future';
}

sub _infinite_past_class {
    my $self = shift;
    return $self->{infinite_past_class} || 'DateTime::Infinite::Past';
}

my $abbrevs = [
    [month => 'm'],
    [day => 'd'],
    [hour => 'h'],
    [minute => 'mn'],
    [second => 's'],
];

sub _parse_date_manip
{
    my ($self, $val) = @_;

    my $date;
    my $incomplete = [];

    # wrap in eval as Date::Manip fatally dies on strange input (ie. 010101)
    eval {

        # we need to know what we consider to be "now"
        my $now = $self->_now;

        # If this is all we have or the DM5 interface has been selected by the
        # app, use the ol' functional and reset after each parse.
        my ($y, $m, $d, $H, $M, $S);
        my $dm_backend = $Date::Manip::Backend || '';
        if ($Date::Manip::VERSION lt '6' or $dm_backend eq 'DM5') {
            my @orig_config = Date::Manip::Date_Init();
            Date::Manip::Date_Init("ForceDate=" . $now->ymd . "-" . $now->hms);
            my $date = Date::Manip::ParseDate($val);
            Date::Manip::Date_Init(@orig_config);

            ($y, $m, $d, $H, $M, $S) = Date::Manip::UnixDate($date, "%Y", "%m", "%d", "%H", "%M", "%S");
        }

        # When available, use the DM6 OO API to prevent this configuration from
        # infecting the global state
        else {
            my $dm = Date::Manip::Date->new;
            $dm->config("forcedate", $now->ymd . '-' . $now->hms);
            my $err = $dm->parse($val);

            if (!$err){
                ($y, $m, $d, $H, $M, $S) = $dm->value;

                for my $section (@$abbrevs){
                    push (@$incomplete, $section->[0]) if !$dm->complete($section->[1]);
                }
            }
        }

        if ( $y )
        {
            $date = $self->_datetime_class->new( 
                year   => $y,
                month  => $m,
                day    => $d,
                hour   => $H,
                minute => $M,
                second => $S,
            );
        }
    };

    # Our caller expects a false value on failure
    return if !$date;

    return ($date, $incomplete);
}

#pod =head2 _convert_from_us_dashed
#pod
#pod Converts a US date string in the format MM-DD-YYYY into a datetime object.
#pod
#pod =cut

sub _convert_from_us_dashed {
    my ($self, $dashed_date) = @_;

    if ($dashed_date !~ m/$US_FORMAT_WITH_DASHES/) {
        return $dashed_date;
    }

    my $year = $3;
    my $month = 1 == length($1) ? "0$1"  : $1;
    my $day   = 1 == length($2) ? "0$2"  : $2;

    return $self->_datetime_class->new( 
        year   => $year,
        month  => $month,
        day    => $day,
    )->ymd;
}

#pod =head2 _clean_units
#pod
#pod Given a unit of measurement such as hours?, minutes?, seconds?, or days?, we will return a string of the form hours, minutes, seconds, or days.
#pod
#pod =cut

sub _clean_units {
    my ($self, $measure) = @_;

    if($measure !~ /s$/) {
        $measure .= 's';
    }

    return $measure;
}

#pod =head1 TO DO
#pod
#pod There's a lot more that this module could handle. A few items that come to mind:
#pod
#pod =over 4
#pod
#pod =item * 
#pod
#pod More testing to make sure certain date configurations are handled, like start of
#pod week.
#pod
#pod =item *
#pod
#pod Handle Unicode in places where such handling makes sense (like hyphen detection)
#pod
#pod =item * 
#pod
#pod Allow full words instead of digits ("two weeks ago" vs "2 weeks ago")
#pod
#pod =item * 
#pod
#pod Allow "between" for ranges ("between last February and this Friday") in addition
#pod to "to/through" ranges
#pod
#pod =item *
#pod
#pod This module is US English-centric (hence the "EN") and might do some things
#pod wrong for other variants of English and a generic C<Date::RangeParser> interface
#pod could be made to allow for other languages to be parsed this way.
#pod
#pod =item *
#pod
#pod Depends on L<Date::Manip>. This may or may not be a good thing.
#pod
#pod =back
#pod
#pod =head1 DEPENDENCIES
#pod
#pod L<DateTime>, L<Date::Manip>
#pod
#pod =head1 AUTHORS
#pod
#pod This module was authored by Grant Street Group (L<http://grantstreet.com>), who were kind enough to give it back to the Perl community.
#pod
#pod The CPAN distribution is maintained by
#pod Grant Street Group <developers@grantstreet.com>.
#pod
#pod =head1 THANK YOU
#pod
#pod Sterling Hanenkamp, for adding support for explicit date ranges, improved parsing, and improving the documentation.
#pod
#pod Sam Varshavchik, for fixing a bug affecting the "[ordinal] of [last/next] month" syntax.
#pod
#pod Allan Noah and James Hammer, for adding support for times in addition to dates and various bug fixes.
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2012-2023 Grant Street Group.
#pod
#pod This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::RangeParser::EN - Parse plain English date/time range strings

=head1 VERSION

version v1.2.0

=head1 SYNOPSIS

    use Date::RangeParser::EN;

    my $parser = Date::RangeParser::EN->new;
    my ($begin, $end) = $parser->parse_range("this week");

=head1 DESCRIPTION

Parses plain-English strings representing date/time ranges

=head1 NAME

Date::RangeParser::EN - Parser for plain English date/time range strings

=head1 METHODS

=head2 new

Returns a new instance of Date::RangeParser::EN.

Takes an optional hash of parameters:

=over 4

=item * B<datetime_class>

By default, Date::RangeParser::EN returns two L<DateTime> objects representing the beginning and end of the range. If you use a subclass of DateTime (or another module that implements the DateTime API), you may pass the name of this class to use it instead.

At the very least, this given class must implement a C<new> method that accepts a hash of arguments, where the following keys will be set:

  year
  month
  day
  hour
  minute
  second

This gives you the freedom to set your time zones and such however you need to.

=item * B<infinite_past_class>
=item * B<infinite_future_class>

By default, Date::RangeParser::EN uses DateTime::Infinite::Past and DateTime::Infinite::Future to create open-ended ranges (for example "after today"). If you have extended these classes, you may pass the corresponding names in.

The given classes must implement a C<new> method that accepts no arguments.

=item * B<now_callback>

By default, Date::RangeParser::EN uses DateTime->now to determine the current date/time for calculations. If you need to work with a different time (for instance, if you need to adjust for time zones), you may pass a callback (code reference) which returns a DateTime object.

=back

=head2 parse_range

Accepts a string representing a plain-English date range, for instance:

=over 4

=item * today

=item * this week

=item * the past 2 months

=item * next Tuesday

=item * two weeks ago

=item * the next 3 hours

=item * the 3rd of next month

=item * the end of this month

=back

More formally, this will parse the following kinds of date strings:

  NUMBER : ordinary number (1)
  PERIOD : one of: hour, day, week, month, quarter, or year (or the plural of these)
  WEEKDAY : one of: Monday, Tuesday, Wedensday, Thursday, Friday, Saturday, or Sunday
  CARDINAL : a cardinal number (21st) or the word for that number (twenty-first) or end
  MONTH : a month name: January, Feburary, March, April, May, June, July August, 
          September, October, November, or Decmeber or any 3-letter abbreviation
  YEAR : a 4-digit year (2-digits will not work)
  TIMES: January 1st, 2000 at 10:00am through January 1st, 2000 at 2:00pm
  RANGE : any date range that can be parsed by parse_range
  ELEMENT : any element of a date range that can be parsed by parse_range

  today                             : today, midnight to midnight

  this PERIOD                       : the current period, start to end
  this month

  current PERIOD                    : the current period, start to end
  current year

  this WEEKDAY                      : the WEEKDAY that is in the current week, midnight to midnight
  this Monday

  NUMBER PERIOD ago                 : past date relative to now until now
  3 days ago

  past NUMBER PERIOD                : past date relative to now until now
  past 2 weeks

  last NUMBER PERIOD                : past date relative to now until now
  last 6 hours

  past NUMBER WEEKDAY               : the weekday a number of weeks before now until now
  past 4 Saturdays

  NUMBER WEEKDAY ago                : the weekday a number of weeks before now until now
  3 Fridays ago

  yesterday                         : yesterday, midnight to midnight

  last WEEKDAY                      : the WEEKDAY that is in the week prior to this, midnight to midnight
  last Wednesday

  previous WEEKDAY                  : the WEEKDAY that is in the week prior to this, midnight to midnight
  previous Friday

  past WEEKDAY                      : the WEEKDAY that is in the week prior to this, midnight to midnight
  past Tuesday

  this past WEEKDAY                 : the WEEKDAY that is in the week prior to this, midnight to midnight
  this past Saturday

  coming WEEKDAY                    : the WEEKDAY that is in the week after this, midnight to midnight
  coming Monday

  this coming WEEKDAY               : the WEEKDAY that is in the week after this, midnight to midnight
  this coming Thursday

  NUMBER Business days ago          : past number of business days relative to now until now

  NUMBER weekdays ago               : past number of weekdays relative to now until now

  LAST or PAST NUMBER weekdays ago  : past number of weekdays relative to now until now

  NUMBER PERIOD hence               : now to a future date relative to now
  4 months hence

  NUMBER PERIOD from now            : now to a future date relative to now
  6 days from now

  next NUMBER PERIOD                : now to a future date relative to now
  next 7 years

  tomorrow                          : tomorrow, midnight to midnight

  next NUMBER WEEKDAY               : the WEEKDAY that is in a number of weeks after this, midnight to midnight
  next 4 Sundays

  CARDINAL of this month            : the specified day of the current month, midnight to midnight
  14th of this month

  CARDINAL of last month            : the specified day of the previous month, midnight to midnight
  31st of last month

  CARDINAL of next month            : the specified day of the month following this, midnight to midnight
  3rd of next month

  CARDINAL of NUMBER months ago     : the specified day of a previous month, midnight to midnight
  12th of 2 months ago

  CARDINAL of NUMBER months from now : the specified day of a following month, midnight to midnight
  7th of 22 months from now

  CARDINAL of NUMBER months hence   : the specified day of a following month, midnight to midnight
  22nd of 6 months hence

  CARDINAL of TIME                  : the specific time of day which can be accompanied by a date
  10:00am through 12:00pm             defaults to today if no date is given

  MONTH                             : the named month of the current year, 1st to last day
  August

  this MONTH                        : the named month of the current year, 1st to last day
  this Sep

  last MONTH                        : the named month of the previous year, 1st to last day
  last January

  next MONTH                        : the named month of the next year, 1st to last day
  next Dec

  MONTH YEAR                        : the named month of the named year, 1st to last day
  June 1969

  RANGE to RANGE                    : the very start of the first range to the very end of the second
  Tuesday to Next Saturday

  RANGE thru RANGE                  : the very start of the first range to the very end of the second
  2 hours ago thru the next 6 hours

  RANGE through RANGE               : the very start of the first range to the very end of the second
  August through December

  RANGE - RANGE                     : the very start of the first range to the very end of the second
  9-1-2012 - 9-30-2012

  RANGE-RANGE                       : the very start of the first range to the very end of the second
  10/10-10/20                         (ranges must not contain hyphens, "-")

  American style dates              : Month / Day / Year
  6/15/2000

  before ELEMENT                    : all dates before the very start of the date specified in the ELEMENT
       < ELEMENT
  before today

  <= ELEMENT                        : all dates up to the very end of the date specified in the ELEMENT
  <= today

  after ELEMENT                     : all dates after the very end of the date specified in the ELEMENT
      > ELEMENT
  after next Tuesday

  >= ELEMENT                        : the date specified in the ELEMENT to the end of forever
  >= this Friday

  since ELEMENT                     : the date specified in the ELEMENT to the end of the current day
  since last Sunday

Anything else is parsed by L<Date::Manip>. If Date::Manip is unable to parse the
date given either, then the dates returned will be undefined.

Also, when parsing:

=over

=item *

The words "the" and "and" will always be ignored and can appear anywhere.

=item *

Cardinal numbers may be spelled out as words, i.e. "September first" instead of
"September 1st". Similarly, "two weeks ago" and "2 weeks ago" will be treated as the same

=item * 

Any plural or singular period shown above can be used with the opposite.

=item *

All dates are parsed relative to the parser's notion of now. You can control
this by setting the C<now_callback> option on the constructor.

=back

Returns two L<DateTime> objects, representing the beginning and end of the range.

=head2 _convert_from_us_dashed

Converts a US date string in the format MM-DD-YYYY into a datetime object.

=head2 _clean_units

Given a unit of measurement such as hours?, minutes?, seconds?, or days?, we will return a string of the form hours, minutes, seconds, or days.

=head1 TO DO

There's a lot more that this module could handle. A few items that come to mind:

=over 4

=item * 

More testing to make sure certain date configurations are handled, like start of
week.

=item *

Handle Unicode in places where such handling makes sense (like hyphen detection)

=item * 

Allow full words instead of digits ("two weeks ago" vs "2 weeks ago")

=item * 

Allow "between" for ranges ("between last February and this Friday") in addition
to "to/through" ranges

=item *

This module is US English-centric (hence the "EN") and might do some things
wrong for other variants of English and a generic C<Date::RangeParser> interface
could be made to allow for other languages to be parsed this way.

=item *

Depends on L<Date::Manip>. This may or may not be a good thing.

=back

=head1 DEPENDENCIES

L<DateTime>, L<Date::Manip>

=head1 AUTHORS

This module was authored by Grant Street Group (L<http://grantstreet.com>), who were kind enough to give it back to the Perl community.

The CPAN distribution is maintained by
Grant Street Group <developers@grantstreet.com>.

=head1 THANK YOU

Sterling Hanenkamp, for adding support for explicit date ranges, improved parsing, and improving the documentation.

Sam Varshavchik, for fixing a bug affecting the "[ordinal] of [last/next] month" syntax.

Allan Noah and James Hammer, for adding support for times in addition to dates and various bug fixes.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2023 Grant Street Group.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

Michael Aquilina <aquilina@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
