package Date::RangeParser::EN;

use strict;
use warnings;

use Date::Manip;
use DateTime;

our $VERSION = '0.08';

=head1 NAME

Date::RangeParser::EN - Parser for plain English date/time range strings

=head1 SYNOPSIS

    use Date::RangeParser::EN;

    my $parser = Date::RangeParser::EN->new;
    my ($begin, $end) = $parser->parse_range("this week");

=head1 DESCRIPTION

Parses plain-English strings representing date/time ranges

=cut

my %bod = (hour =>  0, minute =>  0, second =>  0);
my %eod = (hour => 23, minute => 59, second => 59);

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
    qr/\bthirteenths\b/     => "13th", qr/\bfourteenth\b/       => "14th",
    qr/\bfifteenth\b/       => "15th", qr/\bsixteenth\b/        => "16th",
    qr/\bseventeenth\b/     => "17th", qr/\beighteenth\b/       => "18th",
    qr/\bnineteenth\b/      => "19th", qr/\btwentieth\b/        => "20th",
    qr/\btwenty-?first\b/   => "21st", qr/\btwenty-?second\b/   => "22nd",
    qr/\btwenty-?third\b/   => "23rd", qr/\btwenty-?fourth\b/   => "24th",
    qr/\btwenty-?fifth\b/   => "25th", qr/\btwenty-?sixth\b/    => "26th",
    qr/\btwenty-?seventh\b/ => "27th", qr/\btwenty-?eighth\b/   => "28th",
    qr/\btwenty-?ninth\b/   => "29th", qr/\bthirtieth\b/        => "30th",
    qr/\bthirty-?first\b/   => "31st",
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

=cut

sub new
{
    my ($class, %params) = @_;

    my $self = \%params;

    bless $self, $class;

    return $self;
}

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

The word "the" will always be ignored and can appear anywhere.

=item *

Cardinal numbers may be spelled out as words, i.e. "September first" instead of
"September 1st".

=item * 

Any plural or singular period shown above can be used with the opposite.

=item *

All dates are parsed relative to the parser's notion of now. You can control
this by setting the C<now_callback> option on the constructor.

=back

Returns two L<DateTime> objects, reprensenting the beginning and end of the range.

=cut

sub parse_range
{
    my ($self, $string, %params) = @_;
    my ($beg, $end, $y, $m, $d);

    $string = lc $string;
    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;
    $string =~ s/\s+/ /g;

    # Special cases, except in even more special cases
    unless ($string =~ /\d+ (quarter|day|week|month|year)/)
    {
        if ($string =~ s/ ago$//)
        {
            $string = "past $string";
        }
        elsif ($string =~ s/ (?:hence|from\s+now)$//)
        {
            $string = "next $string";
        }
    }

    # We address the ordinals (let's not get silly, though).  If we wanted
    # to get silly, we'd use Lingua::EN::Words2Nums, which would horribly
    # complicate the general parsing
    while (my ($str, $num) = each %ordinal)
    {
        $string =~ s/$str/$num/g;
    }

    # The word "the" may be used with ridiculous impunity
    $string =~ s/\bthe\b//g;

    # Yes, again.
    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;

    $string =~ s/\s+/ /g;

    # "This thing" and "current thing"
    if ($string eq "today" || $string =~ /^(?:this|current) day$/)
    {
        $beg = $self->_bod();
        $end = $self->_eod();
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
        $end = $self->_datetime_class()->last_day_of_month(year => $self->_now()->year,
                                           month => $self->_now()->month, %eod);
    }
    elsif ($string =~ /^(?:this|current) quarter$/)
    {
        my $zq = int(($self->_now()->month - 1) / 3);     # 0..3
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1);
        $end = $self->_datetime_class()->last_day_of_month(year => $self->_now()->year,
                                           month => $zq * 3 + 3 , %eod);
    }
    elsif ($string =~ /^(?:this|current) year$/)
    {
        $beg = $self->_datetime_class()->new(year => $self->_now()->year, month => 1, day => 1, %bod);
        $end = $self->_datetime_class()->new(year => $self->_now()->year, month => 12, day => 31, %eod);
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
    elsif ($string =~ /^(?:last|past) (\d+) hours?$/)
    {
        # The "+0" math avoids call-by-reference side effects
        $beg = $self->_now();
        $beg->subtract(hours => $1 + 0);

        $end = $self->_now();
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
        $end = $self->_datetime_class()->last_day_of_month(year => $self->_now()->year,
                                       month => $self->_now()->month, %eod);
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
    elsif ($string =~ /^(\d+) ((?:month|day|week|quarter)s?) ago$/)
    {
        # "N days|weeks|months ago"
        my $ct = $1 + 0;
        my $unit = $2;
        if($unit !~ /s$/) {
            $unit .= 's';
        }
        if($unit eq 'quarters') {
            $unit = 'months';
            $ct *= 3;
        }
        $beg = $self->_bod()->subtract($unit => $ct);
        $end = $beg->clone->set(hour => 23, minute => 59, second => 59);
     }
    elsif ($string =~ /^past (\d+) ($weekday)s?$/)
    {
        # really "N weekdays ago", thanks to s/ago/.../ above
        my $dow = $self->_now()->day_of_week % 7;          # Monday == 1
        my $adjust = $weekday{$2} - $dow;
        $adjust -= 7 if $adjust >=0;
        $adjust -= 7*($1 - 1);
        $beg = $self->_bod()->subtract(days => abs($adjust));
        $end = $beg->clone->add(days => 1)->subtract(seconds => 1);
    }
    # "Last thing" and "Previous thing"
    elsif ($string =~ /^yesterday$/)
    {
        $beg = $self->_bod()->subtract("days" => 1);
        $end = $beg->clone->set(hour => 23, minute => 59, second => 59);
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
    elsif ($string =~ /^next (\d+)?\s*hours?$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_now();
        $end = $beg->clone->add(hours => $c);
    }
    elsif ($string =~ /^(?:next (\d+)?\s*days?|tomorrow)$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->add(days => 1);
        $end = $beg->clone->add(days => $c)->subtract(seconds => 1)
    }
    elsif ($string =~ /^next (\d+)?\s*weeks?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $dow = $self->_now()->day_of_week % 7;        # Monday == 1
        $beg = $self->_bod()->add(days => 7 - $dow);        # Add to Sunday
        $end = $self->_eod()->add(days => 6 + 7*$c - $dow); # Add N Saturdays following
    }
    elsif ($string =~ /^next (\d+)?\s*months?$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->add(months => 1, end_of_month => 'preserve')->set_day(1);
        my $em = $self->_now()->add(months => $c, end_of_month => 'preserve');
        $end = $self->_datetime_class()->last_day_of_month(year => $em->year, month => $em->month, %eod);
    }
    elsif ($string =~ /^next (\d+)?\s*quarters?$/)
    {
        my $c = defined $1 ? $1 : 1;
        my $zq = int(($self->_now()->month - 1) / 3);
        $beg = $self->_bod()->set_month($zq * 3 + 1)->set_day(1)
                    ->add(months => 3, end_of_month => 'preserve');
        $end = $beg->clone ->add(months => 3 * $c, end_of_month => 'preserve')
                    ->subtract(seconds => 1);
    }
    elsif ($string =~ /^next (\d+)?\s*years?$/)
    {
        my $c = defined $1 ? $1 : 1;
        $beg = $self->_bod()->set_month(1)->set_day(1)->add(years => 1);
        $end = $self->_eod()->set_month(12)->set_day(31)->add(years => $c);
    }
    elsif ($string =~ /^next (\d+)?\s*($weekday)s?$/)
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
    elsif ($string =~ /^(this|last|next)?\s*($month_re)$/)
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
        $end = $self->_datetime_class()->last_day_of_month(year => $y, month => $m, %eod);
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
        $end = $self->_datetime_class()->last_day_of_month(year => $y, month => $m, %eod);
    }

    # See if the date is a range between two other dates separated by
    # to,thru,through
    elsif ($string =~ /\s(?:to|thru|through|-)\s/) 
    {
        my ($first, $second) = split /\s+(?:to|thru|through|-)\s+/, $string, 2;
        ($beg) = $self->parse_range($first);
        (undef, $end) = $self->parse_range($second);
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
        $end = $self->_now()->clone->set(hour => 23, minute => 59, second => 59);
    }

    # See if this is a range between two other dates separated by -
    elsif ($string !~ /^\d+-\d+$/ and $string =~ /^[^-]+-[^-]+$/) 
    {
        my ($first, $second) = split /\s*-\s*/, $string, 2;
        ($beg) = $self->parse_range($first);
        (undef, $end) = $self->parse_range($second);
    }

    # If all else fails, see if Date::Manip can figure this out
    elsif ($beg = $self->_parse_date_manip($string))
    {
        $beg = $beg->set(%bod);
        $end = $beg->clone->set(hour => 23, minute => 59, second => 59);
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
    return $now->set(%bod);
}

sub _eod {
    my $self = shift;
    my $now = $self->_now();
    return $now->set(hour => 23, minute => 59, second => 59);
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

sub _parse_date_manip
{
    my ($self, $val) = @_;

    my $date;

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

            ($y, $m, $d, $H, $M, $S) = $dm->value unless $err;
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

    return $date;
}

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

The CPAN distribution is maintained by Michael Aquilina (aquilina@cpan.org).

=head1 THANK YOU

Sterling Hanenkamp, for adding support for explicit date ranges, improved parsing, and improving the documentation.

Sam Varshavchik, for for fixing a bug affecting the "[ordinal] of [last/next] month" syntax.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 Grant Street Group.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

