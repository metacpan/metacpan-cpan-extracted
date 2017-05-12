package DateTimeX::Fiscal::Fiscal5253;

our $VERSION = '2.01';

use Carp;
use DateTime;
use POSIX qw( strftime );

use Moo;
use MooX::StrictConstructor;

my @periodmonths = (
    qw(
      January
      February
      March
      April
      May
      June
      July
      August
      September
      October
      November
      December
      )
);

# Figure out if the epoch is a 32- or 64-bit value and use DT if needed
my $_use_dt = sub {
    my $year = shift;

    # test for 32- or 64-bit time values. This is in an eval because there
    # is apparently a bug in Perl 5.10.0 on a Win32 v5 build that causes
    # gmtime to return undefs when the epoch rolls over. This of course
    # will throw an uninitialized error with "use warnings FATAL => 'all'"
    # in effect.
    my $is_32 = eval {
        my @tdata = gmtime(2147483651);    # This is 4 sec past the rollover
        return ( $tdata[5] == 138 );
    };

    return $is_32 && ( $year < 1903 || $year > 2037 );
};

# Utility function to convert a date string to a DT object
my $_str2dt = sub {
    my $date = shift;

    return $date if ref($date);

    # convert date param to DT object
    my ( $y, $m, $d );
    if ( $date =~ m{^(\d{4})-(\d{1,2})-(\d{1,2})(?:$|\D+)} ) {
        $y = $1, $m = $2, $d = $3;
    }
    elsif ( $date =~ m{^(\d{1,2})/(\d{1,2})/(\d{4})(?:$|\D+)} ) {
        $y = $3, $m = $1, $d = $2;
    }
    else {
        croak "Unable to parse date string: $date";
    }
    eval { $date = DateTime->new( year => $y, month => $m, day => $d ); }
      or croak "Invalid date: $date";

    return $date;
};

# Utility function to validate values supplied as a calendar style.
my $_valid_cal_style = sub {
    my $style = shift || 'fiscal';

    $style =~ tr/A-Z/a-z/;
    croak "Invalid calendar style specified: $style"
      unless $style =~ /^(fiscal|restated|truncated)$/;

    return $style;
};

# Define attributes and psuedo-attributes
has end_month => (
    is  => 'ro',
    isa => sub {
        croak "Invalid value for param end_month: $_[0]"
          unless $_[0] =~ /^(?:1[0-2]|[1-9])\z/;
    },
    default => 12,
);

has end_dow => (
    is  => 'ro',
    isa => sub {
        croak "Invalid value for param end_dow: $_[0]"
          unless $_[0] =~ /^[1-7]\z/;
    },
    default => 6,
);

has end_type => (
    is     => 'ro',
    coerce => sub { my $tmp = $_[0]; $tmp =~ tr[A-Z][a-z]; return $tmp; },
    isa    => sub {
        croak "Invalid value for param end_type: $_[0]"
          unless $_[0] =~ /^(?:last|closest)$/;
    },
    default => 'last',
);

has leap_period => (
    is     => 'ro',
    coerce => sub { my $tmp = $_[0]; $tmp =~ tr[A-Z][a-z]; return $tmp; },
    isa    => sub {
        croak "Invalid value for param leap_period: $_[0]"
          unless $_[0] =~ /^(?:first|last)$/;
    },
    default => 'last',
);

has year => (
    is      => 'rwp',
    builder => 1,
    lazy    => 1,
);

has _date => (
    is       => 'rw',
    init_arg => 'date',
    coerce   => $_str2dt,
    isa      => sub {
        croak 'Object in "date" parameter is not a member of DateTime'
          unless $_[0]->isa('DateTime');
    },
);

has _start_ymd => (
    is       => 'rw',
    init_arg => undef,
    reader   => 'start',
);

has _end_ymd => (
    is       => 'rw',
    init_arg => undef,
    reader   => 'end',
);

has _weeks => (
    is       => 'rw',
    init_arg => undef,
    reader   => 'weeks',
);

has style => (
    is       => 'rw',
    init_arg => undef,
    coerce   => sub { my $tmp = $_[0]; $tmp =~ tr[A-Z][a-z]; return $tmp; },
    isa      => $_valid_cal_style,
    default  => 'fiscal',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    # which one would be correct?
    croak 'Mutually exclusive parameters "year" and "date" are present'
      if $args{year} && $args{date};

    # clone the DT object if present
    $args{date} = $args{date}->clone
      if ref( $args{date} ) && $args{date}->isa('DateTime');

    # supply a default date if needed
    $args{date} = DateTime->today() unless $args{date} || $args{year};

    return $class->$orig(%args);
};

# One of the few cases where modifying "new" is the right thing to do.
# NOTE! testing reveals that this B<must not> come before "BUILDARGS".
before new => sub {
    croak 'Must be called as a class method only' if ref( $_[0] );
};

# Initialize the internal structures now that we know our params are good.
sub BUILD {
    my $self = shift;

    $self->{_fiscal}    = undef;
    $self->{_restated}  = undef;
    $self->{_truncated} = undef;

    $self->{_start}     = $self->_start5253;
    $self->{_start_ymd} = $self->{_start}->ymd;
    $self->{_end}       = $self->_end5253;
    $self->{_end_ymd}   = $self->{_end}->ymd;

    $self->{_weeks} =
      $self->{_start}->clone->add( days => 367 ) > $self->{_end} ? 52 : 53;

    $self->_build_weeks;
    $self->_build_periods('fiscal');

    if ( $self->{_weeks} == 53 ) {
        $self->_build_periods('restated');
        $self->_build_periods('truncated');
    }

    return;
}

sub _build_year {
    my $self = shift;

    # we *should be* guaranteed that _date contains a DateTime object
    # if this is reached because no value was supplied for 'year'.
    $self->{_date}->truncate( to => 'day' )->set_time_zone('floating');

    return $self->_find5253;
}

# Build the week array once, then manipulate as needed.
# Using epoch math is more than an order of magnitude faster
# than DT, but the size of the epoch value must be tested.
sub _build_weeks {
    my $self = shift;

    my $weeks = {};
    if ( &{$_use_dt}( $self->{year} ) ) {
        my $wstart = $self->{_start}->clone;
        my $wend = $self->{_start}->clone->add( days => 6 );

        for ( 1 .. $self->{_weeks} ) {
            $weeks->{$_} = {
                start => $wstart->ymd,
                end   => $wend->ymd,
            };

            # skip the last step so the ending values are preserved
            # if needed for something else in the future.
            last if $_ == $self->{_weeks};

            $wstart->add( days => 7 );
            $wend->add( days => 7 );
        }
    }
    else {
        my $daysecs  = ( 60 * 60 * 24 );
        my $weeksecs = $daysecs * 7;

        my $wstart = $self->{_start}->epoch + ( $daysecs / 2 );
        my $wend = $wstart + ( $daysecs * 6 );

        for ( 1 .. $self->{_weeks} ) {
            $weeks->{$_} = {
                start => strftime( '%Y-%m-%d', localtime($wstart) ),
                end   => strftime( '%Y-%m-%d', localtime($wend) ),
            };

            # skip the last step so the ending values are preserved
            # if needed for something else in the future.
            last if $_ == $self->{_weeks};

            $wstart += $weeksecs;
            $wend   += $weeksecs;
        }
    }

    $self->{_weeks_raw} = $weeks;

    return;
}

# Build the basic calendar structures as needed.
sub _build_periods {
    my $self = shift;
    my $style = shift || $self->{style};

    # not strictly needed, but makes for easier to read code
    my $restate  = $style eq 'restated'  ? 1 : 0;
    my $truncate = $style eq 'truncated' ? 1 : 0;

    # Avoid re-builds when possible.
    return if $restate  && defined( $self->{_restated} );
    return if $truncate && defined( $self->{_truncated} );

    # Disabled this for now, becomes problematic for various
    # methods such as "contains" in normal years.
    # return if ($restate || $truncate) && $self->{_weeks} == 52;

    my $pstart = $self->{_start}->clone;

    # This value is confusing only because it is 0-based unlike
    # the other month values.
    my $p1month = $self->{end_month} == 12 ? 0 : $self->{end_month};
    my @pweeks = ( 4, 4, 5, 4, 4, 5, 4, 4, 5, 4, 4, 5 );
    my $wkcnt = 52;

    # a truncated structure ignores the last week in a 53 week year
    if ( $self->{_weeks} == 53 && !$truncate ) {
        if ($restate) {

            # ignore the fist week and treat as any other 52 week year
            $pstart->add( days => 7 );
        }
        elsif ( $self->{leap_period} eq 'first' ) {
            $pweeks[$p1month] += 1;
            $wkcnt = 53;
        }
        else {
            $pweeks[ $self->{end_month} - 1 ] += 1;
            $wkcnt = 53;
        }
    }

    my $pdata = {
        summary => {
            style       => $style,
            year        => $self->{year},
            end_month   => $self->{end_month},
            end_dow     => $self->{end_dow},
            end_type    => $self->{end_type},
            leap_period => $self->{leap_period},
            weeks       => $wkcnt,
            start       => $pstart->ymd,
            end => undef,    # this is set after the cache is built
        }
    };

    my $wdata  = {};
    my $wkcntr = 1;
    for ( 0 .. 11 ) {
        my $p_index = ( $p1month + $_ ) % 12;

        my $pinfo = {
            period => $_ + 1,
            weeks  => $pweeks[$p_index],
            month  => $periodmonths[$p_index]
        };

        for my $pw ( 1 .. $pweeks[$p_index] ) {
            my $wksrc = $restate ? $wkcntr + 1 : $wkcntr;
            my $winfo = {
                week        => $wkcntr,
                period      => $_ + 1,
                period_week => $pw,
                start       => $self->{_weeks_raw}->{$wksrc}->{start},
                end         => $self->{_weeks_raw}->{$wksrc}->{end},
            };
            $pinfo->{start} = $winfo->{start} if $pw == 1;
            $pinfo->{end}   = $winfo->{end}   if $pw == $pweeks[$p_index];
            $wdata->{$wkcntr} = $winfo;
            $wkcntr++;
        }

        $pdata->{ $_ + 1 } = $pinfo;
    }
    $pdata->{summary}->{end} = $pdata->{12}->{end};

    if ( $self->{_weeks} == 52 ) {

        # Set style to 'fiscal' and assign the structure to all
        # three calendar types in a normal year to save time and space.
        $pdata->{summary}->{style} = 'fiscal';
        $self->{_fiscal} = $self->{_restated} = $self->{_truncated} = $pdata;
        $self->{_fiscal_weeks}    = $wdata;
        $self->{_restated_weeks}  = $wdata;
        $self->{_truncated_weeks} = $wdata;
    }
    else {
        $self->{"_$style"}         = $pdata;
        $self->{"_${style}_weeks"} = $wdata;
    }

    return;
}

# The end day for a specified year is trivial to determine. In normal
# accounting use, a fiscal year is named for the calendar year it ends in,
# not the year it begins.
sub _end5253 {
    my $self = shift;

    my $dt = DateTime->last_day_of_month(
        year      => $self->{year},
        month     => $self->{end_month},
        time_zone => 'floating'
    );

    my $eom_day = $dt->day;
    my $dt_dow  = $dt->dow;

    if ( $dt_dow > $self->{end_dow} ) {
        $dt->subtract( days => $dt_dow - $self->{end_dow} );
    }
    elsif ( $dt_dow < $self->{end_dow} ) {
        $dt->subtract( days => ( $dt_dow + 7 ) - $self->{end_dow} );
    }
    $dt->add( weeks => 1 )
      if $self->{end_type} eq 'closest' && $eom_day - $dt->day > 3;

    return $dt;
}

# Finding the starting day for a specified year is easy. Simply find
# the last day of the preceding year since the year is defined by
# the ending day and add 1 day to that. This avoids calendar year and month
# boundary issues.
sub _start5253 {
    my $self = shift;

    # do not assume it is safe to change the year attribute
    local $self->{year} = $self->year - 1;
    my $dt = $self->_end5253->add( days => 1 );

    return $dt;
}

# Determine the correct fiscal year for any given date
sub _find5253 {
    my $self = shift;

    my $y1 = $self->{_date}->year;

    # do not assume it is safe to change the year attribute
    local $self->{year} = $y1;

    my $e1 = $self->_end5253;
    return $y1 + 1 if $e1 < $self->{_date};

    my $s1 = $self->_start5253;
    return $y1 - 1 if $s1 > $self->{_date};

    return $y1;
}

sub has_leap_week {
    my $self = shift;

    return ( $self->{_weeks} == 53 ? 1 : 0 );
}

# return summary data about a calendar.
sub summary {
    my $self = shift;
    my %args = @_ == 1 ? ( style => shift ) : @_;

    $args{style} ||= $self->{style};
    croak 'Unknown parameter present' if scalar( keys(%args) ) > 1;

    my $cal = &{$_valid_cal_style}( $args{style} );

    my %cdata;
    for (qw( style year start end weeks )) {
        $cdata{$_} = $self->{"_$cal"}->{summary}->{$_};
    }

    return wantarray ? %cdata : \%cdata;
}

sub contains {
    my $self = shift;
    my %args = @_ == 1 ? ( date => shift ) : @_;

    $args{date}  ||= 'today';
    $args{style} ||= $self->{style};

    croak 'Unknown parameter present' if scalar( keys(%args) ) > 2;

    my $cal = &{$_valid_cal_style}( $args{style} );

    # Yes, a DT object set to "today" would work, but this is faster.
    # NOTE! This will break in 2038 on 32-bit builds!
    $args{date} = strftime( "%Y-%m-%d", localtime() )
      if ( lc( $args{date} ) eq 'today' );

    # _str2dt will croak on error
    my $date = &{$_str2dt}( $args{date} )->ymd;

    my $whash = $self->{"_${cal}_weeks"};
    my $cdata = $self->{"_$cal"}->{summary};

    # it is NOT an error if the date isn't in the calendar,
    # so return undef to differentiate this from an error condition
    return if $date lt $cdata->{start} || $date gt $cdata->{end};

    # since the date is in the calendar, let's return it's week,
    # and optionally, a structure with period and week number.

    my $w;
    for ( $w = 1 ; $date gt $whash->{$w}->{end} ; $w++ ) {

        # this should NEVER fire!
        croak 'FATAL ERROR! RAN OUT OF WEEKS' if $w > $cdata->{weeks};
    }
    my $p = $whash->{$w}->{period};

    return wantarray ? ( period => $p, week => $w ) : $w;
}

# Utiliy routine, hidden from public use, to prevent duplicate code in
# the period attribute accessors.
my $_period_attr = sub {
    my $self = shift;
    my $attr = shift;
    my %args = @_ == 1 ? ( period => shift ) : @_;

    $args{period} ||= 0;
    $args{style}  ||= $self->{style};

    croak 'Unknown parameter present' if scalar( keys(%args) ) > 2;

    my $cal = &{$_valid_cal_style}( $args{style} );

    if ( $args{period} < 1 || $args{period} > 12 ) {
        croak "Invalid period specified: $args{period}";
    }

    # return a copy so the guts hopefully can't be changed
    my %phash = %{ $self->{"_$cal"}->{ $args{period} } };

    return $attr eq 'period' ? %phash : $phash{$attr};
};

# Automate creating period attribute mehtods
for my $p_attr (qw( month start end weeks )) {
    my $method = join( '::', __PACKAGE__, "period_${p_attr}" );
    {
        no strict 'refs';
        *$method = sub {
            my $self = shift;

            return $self->$_period_attr( $p_attr, @_ );
          }
    }
}

sub period {
    my $self = shift;
    my %args = @_ == 1 ? ( period => shift ) : @_;

    my %phash = $self->$_period_attr( 'period', %args );

    return wantarray ? %phash : \%phash;
}

# Utiliy routine, hidden from public use, to prevent duplicate code in
# the week attribute accessors.
my $_week_attr = sub {
    my $self = shift;
    my $attr = shift;
    my %args = @_ == 1 ? ( week => shift ) : @_;

    $args{week}  ||= 0;
    $args{style} ||= $self->{style};

    croak 'Unknown parameter present' if scalar( keys(%args) ) > 2;

    my $cal = &{$_valid_cal_style}( $args{style} );

    if (   $args{week} < 1
        || $args{week} > $self->{"_$cal"}->{summary}->{weeks} )
    {
        croak "Invalid week specified: $args{week}";
    }

    # make a copy so the outside (hopefully) won't change the guts
    my %whash = %{ $self->{"_${cal}_weeks"}->{ $args{week} } };

    return $attr eq 'week' ? %whash : $whash{$attr};
};

sub week {
    my $self = shift;
    my %args = @_ == 1 ? ( week => shift ) : @_;

    my %whash = $self->$_week_attr( 'week', %args );

    return wantarray ? %whash : \%whash;
}

# Automate creating week attribute mehtods
for my $w_attr (qw( period period_week start end )) {
    my $method = join( '::', __PACKAGE__, "week_${w_attr}" );
    {
        no strict 'refs';
        *$method = sub {
            my $self = shift;

            return $self->$_week_attr( $w_attr, @_ );
          }
    }
}

1;

__END__

=pod

=head1 NAME

DateTimeX::Fiscal::Fiscal5253 - Create fiscal 52/53 week calendars

=head1 SYNOPSIS

 use DateTimeX::Fiscal::Fiscal5253;
  
 my $fc = DateTimeX::Fiscal::Fiscal5253->new( year => 2012 );

=head1 DESCRIPTION

This module generates calendars for a "52/53 week" fiscal year. They are
also known as "4-4-5" or "4-5-4" calendars due to the repeating week
patterns of the periods in each quarter. A 52/53 week year will B<always>
have either 52 or 53 weeks (364 or 371 days.) One of the best known of
this type is the standard Retail 4-5-4 calendar as defined by the National
Retail Federation.

You are B<strongly> advised to speak with your accounting people
(after all, the reason you are reading this is because they want reports,
right?) and show them the summary data for any given year and see if it
matches what they expect.

Keep in mind that when an accountant says they want data for fiscal year 2012
they are probably talking about an accounting year that B<ends> in 2012. An
accountant will usually think in terms of "the fiscal year ending in October,
2012." (Unless they are talking about Retail 4-5-4 years, see the section
below that deals specifically with this.)

=head1 ERROR HANDLING

All error conditions die via C<croak>. Please see the F<README> file for the
rationale behind this.

B<Note!> This is a change in the API! The first releases returned C<undef>
on error with a message emitted via C<carp>. It was felt that this change
would not impose an undue hardship in the code changes required to accomdate
it and that the new behavior would not introduce any undesired side-effects
in any existing code.

=head1 CONSTRUCTOR

=head2 new

 my $fc = DateTimeX::Fiscal::Fiscal5253->new();
 
 my $fc = DateTimeX::Fiscal::Fiscal5253->new(
     end_month => 12,
     end_dow => 6,
     end_type => 'last',
     leap_period => 'last',
 );

The constructor B<must> be called as a class method and will throw an
exception if not. It accepts the following parameters:

=over 4

=item C<end_month>

set the last calendar month of the fiscal year. This should be
an integer in the range 1 .. 12 where "1" is January.
Default: 12

=item C<end_dow>

sets the last day of the week of the fiscal year. This is an
integer in the range 1 .. 7 with Monday being 1. Remember, a 52/53 week
fiscal calendar always ends on the same weekday. Default: 6 (Saturday)

=item C<end_type>

determines how to calculate the last day of the fiscal year
based on the C<end_month> and C<end_dow>. There are two legal vaules:
"last" and "closest". Default: "last"

"last" says to use the last weekday in the month of the type specified
in C<end_dow> as the end of the fiscal year.

"closest" says to use the weekday of the type specified that is closest
to the end of the calendar month as the last day, B<even if it is in the
following month>.

=item C<leap_period>

determines what period the 53rd week (if needed) is placed in.
This could be of importance when creating year-over-year reports.
There are two legal values: "first" and "last". Default: "last"

"first" says to place the extra week in period 1.

"last" says to place the extra week in period 12.

=back

The last two parameters control what year the calendar is generated for.
These parameters are optional but B<mutually exclusive> and will
throw an exception if both are present.

=over 4

=item C<year>

sets the B<fiscal year> to build for. It defaults to the correct
fiscal year for the current date or to the fiscal year containing the date
specified by C<date>.

The fiscal year value will often be different than the calendar year for
dates that are near the beginning or end of the fiscal year. For example,
Jan 3, 2015 is the last day of FYE2014 when using an C<end_type> of "closest".

B<NOTE!> In normal accounting terms, a fiscal year is named for the calendar
year it ends in. That is, for a fiscal year that ends in October, fiscal year
2005 would begin in October or November of calendar year 2004
(depending upon the setting of C<end_type>.) However, Retail 4-5-4
calendars are named for the year they B<begin> in. This means that a Retail
4-5-4 calendar for 2005 would begin in 2005 and not 2004 as an accountant
would normally think. See the discussion at the end of this documentation
about Retail 4-5-4 calendars for more information.

=item C<date>

if present, is either a string representing a date or a
L<DateTime> object. This will be used to build a calendar that contains
the given value. Again, be aware that dates that are close to the end
of a given fiscal year might have different values for the calendar year
vs the fiscal year.

If the value for C<date> is a string, it must be specified as either
"YYYY-MM-DD" or "MM/DD/YYYY" or some reasonable variant of those such as
single digit days and months. Time components, if present, are discarded.
Any other format will throw an exception. A L<DateTime> object will be
cloned before being used to prevent unwanted changes to the original object.

=back

=head1 ACCESSORS

The accessors allow you to examine the parameters used to create the calendar
and the resulting base values. All accessors are read-only and will throw
an exception if a parameter is passed to them.

If you want to change any of the underlying properties that define an
object, B<create a new object!>

=head2 end_month

 my $end_month = $fc->end_month();

=head2 end_dow

 my $end_dow = $fc->end_dow();

=head2 end_type

 my $end_type = $fc->end_type();

=head2 leap_period

 my $leap_period = $fc->leap_period();

=head2 year

 my $year = $fc->year();

Returns the either the value that was supplied for the C<year> parameter to
the constuctor or the year that resulted from the value supplied in the
constructor's C<date> parameter. This is what will be used as the name of
the fiscal year.

=head2 start

 my $start = $fc->start();

Returns the first date in the fiscal year as constructed from the parameters
given to the constructor.

=head2 end

 my $end = $fc->end();

Returns the last date in the fiscal year as constructed from the parameters
given to the constructor.

=head2 weeks

 my $weeks = $fc->weeks();

Returns the number of weeks in the fiscal year as generated by the
parameters given to the construtor. The value will be either "52" or "53"
depending on whether a leap week was added. This value does B<not> look
at the calendar style but rather is based on only the fiscal year itself.

=head2 has_leap_week

 my $fc = DateTimeX::Fiscal::Fiscal5253->new( year => 2006 );
 print "This is a Fiscal Leap Year" if $fc->has_leap_week;

This method is basically syntactic sugar for the C<weeks> accessor and
returns a Boolean value indicating whether or not the fiscal Year for the
object has 53 weeks instead of the standard 52 weeks.

=head1 METHODS

=head2 style

 my $fc = DateTimeX::Fiscal::Fiscal5253->new( year => 2006 );
 my $cal_style = $fc->style; # returns the current style
 $fc->style( 'restated );    # set the style to 'restated'

This method reads and sets the calendar style to be used by all of the
following methods. It can be overridden on a case by case basis as needed
by those methods.

The legal values are "fiscal", "restated", and "truncated" when the style
is being set. A new object has the style set to 'fiscal' by default.

The value 'fiscal' will use a calendar with the full number of weeks
without regard to whether there are 52 or 53 weeks in the year.

The value 'restated' says to ignore the first week in a 53 week year and
create a calendar with only 52 weeks. This allows for more accurate
year-over-year comparisons involving a year that would otherwise have
53 weeks.

The value 'truncated' says to ignore the last week in a 53 week year and
create a calendar with only 52 weeks. This may allow for more accurate
year-over-year comparisons involving a year that would otherwise have
53 weeks.

"restated" and "truncated" have no effect in normal 52 week years.

=head2 summary

 my %summary = $fc->summary();
 my $summary = $fc->summary();
 
 my %summary = $fc->summary( style => 'restated');
 my $summary = $fc->summary( 'restated' );

This method will return either a hash or a reference to a hash (depending
upon context) containing a summary of the current calendar style or the one
specified by the style parameter.

 my $fc = DateTimeX::Fiscal::Fiscal5253->new( year => 2012 );
 my $fc_info = $fc->summary();
  
 print Dumper($fc_info);
 $VAR1 = {
          'style => 'fiscal',
          'year' => 2012,
          'start' => '2012-01-01',
          'end' => '2012-12-29',
          'weeks' => 52
        };

The value contained in C<$fc_info-E<gt>{year}> is the name of the fiscal
year as commonly used by accountants (as in "fye2012") and is usually the
same as the calendar year the fiscal year B<ends> in. However, it is
possible for the actual ending date to be in the B<following> calendar
year when the C<end_month> is '12' (the default) and an C<end_type> of
"closest" is specified, fiscal year 2014 built as shown below demonstrates
this:

 my $fc = DateTimeX::Fiscal::Fiscal5253->new(
              year => 2014,
              end_type => 'closest'
          );
 
 print Dumper($fc->summary());
 $VAR1 = {
          'style => 'fiscal',
          'year' => 2014,
          'start' => '2013-12-29',
          'end' => '2015-01-03',
          'weeks' => 53
        };

=head2 contains

 my $fc = DateTimeX::Fiscal::Fiscal5253->new( year => 2012 );
  
 if ( my $wnum = $fc->contains() ) {
     print "The current date is in week $wnum\n";
 }
  
 if ( $fc->contains( date => 'today', style => 'restated' ) ) {
     print 'The current day is in the fiscal calendar';
 }
  
 if ( $fc->contains( date => '2012-01-01', style => 'fiscal' ) ) {
     print '2012-01-01 is in the fiscal calendar';
 }
  
 my $dt = DateTime->today( time_zone => 'floating' );
 if ( my $wnum = $fc->contains( date => $dt ) ) {
     print "$dt is in week $wnum\n";
 }
  
 my %containers = $fc->contains( '2012-06-04' );
 print Dumper(\%containers);
 $VAR1 = {
          'period' => 6,
          'week' => 23
        };

Returns the week number in the designated style that contains the given
date or C<undef> if not. The method will C<croak> if an error occurs such
as an invalid date format or unknown style type.

This method takes two named parameters, 'date' and 'style'. Bear in mind
that some dates that are in the fiscal calendar might not be in a restated
or truncated calendar. A single un-named parameter can be used as a shorthand
for supplying only the date.

A hash containing both the period and week numbers is returned if the
method is called in list context and the date is present.

=over 4

=item C<date>

Accepts the same formats as the constructor as well as the special
keyword 'today'. Defaults to the current date if not supplied.

=item C<style>

Specifies which calendar style to check against and accepts
the same values as the 'style' method does. The default is the current value
returned as set by the C<style> method.

=back

=head2 period

 my %pdata = $fc->period( period => 5, style => 'restated' );
 my $pdata = $fc->period( period => 1, style => 'fiscal' );

Read-only method that returns a hash or a reference to a hash depending
upon context that contains all of the data for the requested period in
the specified style type.

=over 4

=item C<period>

Must be a number in the range 1 - 12. An exception will be thrown if this
parameter is not given.

=item C<style>

Specifies what calendar style to retrieve the period information from. Legal
values are the same as those for the C<style> method. The current value of
the C<style> method will be used by default.

=back

The returned data is as follows:

 print Dumper($pdata);
 $VAR1 = { 
          'period' => 1,
          'month' => 'February',
          'start' => '2012-02-04',
          'weeks' => 4,
          'end' => '2012-03-02'
        };

The following methods are syntactic sugar for those who prefer to access the
individual components of the period structure without dealing with a hash.
They return a scalar value and accept the same parameters as C<period> does.

=over 4

=item period_month

 my $pmonth = $fc->period_month( period => 3, style => 'fiscal' );

=item period_start

 my $pstart = $fc->period_start( period => 5 );

=item period_end

 my $pend = $fc->period_end( style => 'fiscal' );

=item period_weeks

 my $pweeks = $fc->period_weeks( period => 2, style => 'restated' );

=back

There is no method to return the period number component because presumably
you already know that. Use C<contains> to get the period number for the
current date if applicable. (Besides, C<$fc-E<gt>period_period> is just
plain ugly!)

=head2 week

 my %wdata = $fc->week( week => 5, style => 'restated' );
 my $wdata = $fc->week( week => 5, style => 'restated' );

Read-only method that returns a hash or a reference to a hash depending
upon context that contains all of the data for the requested week in
the specified style type.

=over 4

=item C<week>

Must be a number in the range 1 - 52 (53 if a leap week is present in the
requested style.) An exception will be thrown if not given.

=item C<style>

Specifies what calendar style to retrieve the week information from. Legal
values are the same as those for the C<style> method. The current value for
the C<style> method will be used by default.

=back

The returned data is as follows:

 print Dumper($wdata);
 $VAR1 = { 
          'week' => 5,
          'period' => 2,
          'period_week' => 1,
          'start' => '2012-01-29'
          'end' => '2012-02-04',
        };

The following methods are syntactic sugar for those who prefer to access the
individual components of the week structure without dealing with a hash.
They return a scalar value and accept the same parameters as C<week> does.

=over 4

=item week_period

 my $wperiod = $fc->week_period( week => 3, style => 'fiscal' );

=item week_period_week

 my $wperiod = $fc->week_period_week( week => 3, style => 'fiscal' );

=item week_start

 my $wstart = $fc->week_start( week => 5 );

=item week_end

 my $wend = $fc->week_end( style => 'fiscal' );

=back

There is no method to return the week number component because presumably
you already know that. Use C<contains> to get the week number for the current
date if applicable. (Besides, C<$fc-E<gt>week_week> is just plain ugly!)

=head1 RETAIL 4-5-4 CALENDARS

A Retail 4-5-4 calendar (as described by the National Retail Federation here:
L<http://www.nrf.com/modules.php?name=Pages&sp_id=392>) is an example of a
fiscal 52/53 week year that starts on the Sunday closest to Jan 31 of
the specified year.

In other words, to create a Retail 4-5-4 calendar for 2012, you will create
a Fiscal5253 object that ends in 2013 on the Saturday closest to Jan 31.

B<Note!> Fiscal years are named for the year they end in, Retail 4-5-4
years are named for the year they B<begin> in!

 # Create a Retail 4-5-4 calendar for 2012
 my $r2012 = DateTimeX::Fiscal::Fiscal5253->new(
     year => 2013,          # This will be the ending year for the calendar
     end_month => 1,        # End in January
     end_dow => 6,          # on the Saturday
     end_type => 'closest', # closest to the end of the month
     leap_period => 'last'  # and any leap week in the last period
 );
 
 print Dumper(\%{$r2012->summary()});
 $VAR1 = { 
          'style' => 'fiscal',
          'year' => '2013',
          'weeks' => 53,
          'start' => '2012-01-29'
          'end' => '2013-02-02',
         };
 
 print Dumper(\%{$r2012->summary( style => 'restated' )});
 $VAR1 = { 
          'style' => 'restated',
          'year' => '2013',
          'weeks' => 52,
          'start' => '2012-02-05'
          'end' => '2013-02-02',
        };
 
 print Dumper(\%{$r2012->summary( style => 'truncated' )});
 $VAR1 = { 
          'style' => 'truncated',
          'year' => '2013',
          'weeks' => 52,
          'start' => '2012-01-29'
          'end' => '2013-01-26',
        };

You can verify that this is correct by viewing the calendars available at
the NRF website: L<http://www.nrf.com/4-5-4Calendar>

The reporting date can be determined by adding 5 days to the end of any
given period. Using L<DateTime> makes this trivial:

 # Get the reporting date for period 5 for the object created above
 my ($y,$m,$d) = split(/\-/,$r2012->period_end( period => 5 ));
 my $report_date = DateTime->new(
     year => $y,
     month => $m,
     day => $d
 )->add( days => 5 )->ymd;

=head1 DEPENDENCIES

L<DateTime>, L<Carp>

=head1 TO DO

Allow the C<leap_period> parameter to 'new' to accept a number in the
range 1 .. 12 besides 'first' and 'last' to specify explicitly which
period to place any leap week in.

Anything else that users of this module deem desirable.

=head1 SEE ALSO

L<DateTime> to get ideas about how to work with an object suppiled to
the constructor as the C<date> parameter.

Do a Google (or comparable) search to learn more about fiscal Years and
the 52/53 week. This is a fairly arcane subject that usually is of interest
only to accountants and those of us who must provide reports to them.

Of particular interest will be how a Retail 4-5-4 calendar differs in
definition from an accounting 4-4-5 fiscal year.

=head1 CREDITS

This module, like any other in the L<DateTime> family, could not exist
without the work and dedication of Dave Rolsky.

=head1 SUPPORT

Support is provided by the author. Please report bugs or make feature
requests to the author or use the GitHub repository:

L<http://github.com/boftx/DateTimeX-Fiscal-Fiscal5253>

=head1 AUTHOR

Jim Bacon, E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jim Bacon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
