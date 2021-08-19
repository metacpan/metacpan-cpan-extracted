package DateTime::Fiction::JRRTolkien::Shire;

use 5.008004;

use strict;
use warnings;

use Carp ();
use Date::Tolkien::Shire::Data 0.001 qw{
    __date_to_day_of_year
    __day_of_week
    __day_of_year_to_date
    __format
    __holiday_name __holiday_abbr
    __holiday_name_to_number
    __is_leap_year
    __month_name __month_abbr
    __month_name_to_number
    __quarter __quarter_name __quarter_abbr
    __rata_die_to_year_day
    __trad_weekday_name __trad_weekday_abbr
    __week_of_year
    __weekday_name __weekday_abbr
    __year_day_to_rata_die
    GREGORIAN_RATA_DIE_TO_SHIRE
};
use DateTime 0.14;
use DateTime::Fiction::JRRTolkien::Shire::Duration;
use DateTime::Fiction::JRRTolkien::Shire::Types ();
use Params::ValidationCompiler 0.13 ();

# This Conan The Barbarian-style import is because I am reluctant to use
# any magic more subtle than I myself posess; to wit
# namespace::autoclean.
*__t = \&DateTime::Fiction::JRRTolkien::Shire::Types::t;

our $VERSION = '0.907';

use constant DAY_NUMBER_MIDYEARS_DAY	=> 183;

use constant HASH_REF	=> ref {};

my @delegate_to_dt = qw( hour minute second nanosecond locale );

# This assumes all the values in the info hashref are valid, and doesn't
# do validation However, the day and month parameters will be given
# defaults if not present
sub _recalc_DateTime {
    my ($self, %dt_args) = @_;

    my $shire_rd = __year_day_to_rata_die(
	$self->{year},
	__date_to_day_of_year(
	    $self->{year},
	    $self->{month},
	    $self->{day} || $self->{holiday},
	),
    );

    # Because the leap year algorithm is the same in both calendars, I
    # can use __rata_die_to_year_day() on the Gregorian Rata Die day.
    ( $dt_args{year}, $dt_args{day_of_year} ) = __rata_die_to_year_day(
	$shire_rd - GREGORIAN_RATA_DIE_TO_SHIRE );

    # We may be calling this because we have fiddled with the Shire date
    # and need to preserve stuff that is maintained by the embedded
    # DateTime object. So if we actually have said object, preserve
    # everything not explicitly specified.
    if ( $self->{dt} ) {
	foreach my $name ( @delegate_to_dt ) {
	    defined $dt_args{$name}
		or $dt_args{$name} = $self->{dt}->$name();
	}
    }

    $self->{dt} = DateTime->from_day_of_year( %dt_args );

    return;
}

sub _recalc_Shire {
    my ( $self ) = @_;

    my $greg_rd = ( $self->local_rd_values() )[0];

    my ( $year, $day_of_year ) = __rata_die_to_year_day(
	$greg_rd + GREGORIAN_RATA_DIE_TO_SHIRE );

    my ( $month, $day ) = __day_of_year_to_date( $year, $day_of_year );

    $self->{year} = $year;
    $self->{leapyear} = __is_leap_year( $year );
    $self->{wday} = __day_of_week( $month, $day );
    if ( $month ) {
	$self->{month} = $month;
	$self->{day} = $day;
	$self->{holiday} = 0;
    } else {
	$self->{holiday} = $day;
	$self->{month} = $self->{day} = 0;
    }

    $self->{recalc} = 0;

    return;
}

# Constructors

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_new',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
	    },
	    month		=> {
		type		=> __t( 'Month' ),
		optional	=> 1,
	    },
	    day			=> {
		type		=> __t( 'DayOfMonth' ),
		optional	=> 1,
	    },
	    holiday		=> {
		type		=> __t( 'Holiday' ),
		optional	=> 1,
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		default		=> 0,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		default		=> 0,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		default		=> 0,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		default		=> 0,
	    },
	    time_zone		=> {
		type		=> __t( 'TimeZone' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	    formatter		=> {
		type		=> __t( 'Formatter' ),
		optional	=> 1,
	    },
	    accented		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	    traditional		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	},
    );

    sub new {
	my ( $class, @args ) = @_;

	my %my_arg = $validator->( @args );

	_check_date( \%my_arg );

	return $class->_new( %my_arg );
    }
}

# For internal use only - no validation.
sub _new {
    my ( $class, %my_arg ) = @_;

    if ( $my_arg{month} ) {
	$my_arg{month} = __month_name_to_number( $my_arg{month} );
	$my_arg{day} ||= 1;
	$my_arg{holiday} = 0;
    } else {
	$my_arg{holiday} ||= $my_arg{day} || 1;
	$my_arg{holiday} = __holiday_name_to_number(
	    $my_arg{holiday} );
	$my_arg{month} = $my_arg{day} = 0;
    }
    $my_arg{leapyear} = __is_leap_year( $my_arg{year} );
    $my_arg{wday} = __day_of_week(
	$my_arg{month},
	$my_arg{day} || $my_arg{holiday},
    );

    my %dt_arg;
    foreach my $key ( @delegate_to_dt ) {
	defined $my_arg{$key}
	    and $dt_arg{$key} = delete $my_arg{$key};
    }

    my $self = bless \%my_arg, $class;

    $self->_recalc_DateTime(%dt_arg);

    return $self;
}

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_output_options',
	name_is_optional	=> 1,
	params			=> {
	    accented		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	    traditional		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	},
    );

    # sub from_epoch; sub now; sub today;
    foreach my $method ( qw{ from_epoch now today } ) {
	no strict qw{ refs };
	*$method = sub {
	    my ( $class, %arg ) = @_;

	    my %my_arg;
	    exists $my_arg{$_} and $my_arg{$_} = delete $arg{$_}
		for qw{ accented traditional };

	    %my_arg = $validator->( %my_arg );

	    return bless {
		dt		=> DateTime->$method( %arg ),
		recalc	=> 1,
		%my_arg,
	    }, $class;
	}
    }

    sub from_object {
	my ( $class, %arg ) = @_;

	my %my_arg;
	my $shire_object = $arg{object} && eval {
	    $arg{object}->isa( __PACKAGE__ ) };
	foreach my $name ( qw{ accented traditional } ) {
	    if ( exists $arg{$name} ) {
		$my_arg{$name} = delete $arg{$name};
	    } elsif ( $shire_object ) {
		$my_arg{$name} = $arg{object}->$name();
	    }
	}

	%my_arg = $validator->( %my_arg );

	my $self = bless {
	    dt	=> DateTime->from_object( %arg ),
	    recalc	=> 1,
	    %my_arg,
	}, $class;

	return $self;
    }
}

sub last_day_of_month {
    my ( $class, %arg ) = @_;
    $arg{day} = 30; # The shire calendar is nice this way
    return $class->new( %arg );
}

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_from_day_of_year',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
	    },
	    day_of_year		=> {
		type		=> __t( 'DayOfYear' ),
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		default		=> 0,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		default		=> 0,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		default		=> 0,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		default		=> 0,
	    },
	    time_zone		=> {
		type		=> __t( 'TimeZone' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	    formatter		=> {
		type		=> __t( 'Formatter' ),
		optional	=> 1,
	    },
	    accented		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	    traditional		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	},
    );

    sub from_day_of_year {
	my ( $class, @args ) = @_;

	my %arg = $validator->( @args );

	( $arg{month}, $arg{day} ) = __day_of_year_to_date(
	    $arg{year},
	    delete $arg{day_of_year},
	);

	return $class->_new( %arg );
    }
}

sub now_local {
    my ( $class, %arg ) = @_;
    my %dt_arg;
    @dt_arg{ qw< second minute hour day month year > } = localtime;
    $dt_arg{month} += 1;
    $dt_arg{year}  += 1900;
    return $class->from_object( %arg, object => DateTime->new( %dt_arg ) );
}

sub calendar_name {
    return 'Shire';
}

sub clone {
    my ( $self ) = @_;
    my $clone = { %{ $self } };
    $clone->{dt} = $self->{dt}->clone();
    return bless $clone, ref $self;
}

# Get methods
sub year {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{year};
} # end sub year

sub month {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{month};
} # end sub month

*mon = \&month;		# sub mon;

sub month_name {
    my ( $self ) = @_;
    return __month_name( $self->month() );
}

sub month_abbr {
    my ( $self ) = @_;
    return __month_abbr( $self->month() );
}

sub day_of_month {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{day};
} # end sub day_of_month

*day = \&day_of_month;		# sub day;
*mday = \&day_of_month;		# sub mday;

sub day_of_week {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{wday};
} # end sub day_of_week

*wday  = \&day_of_week;			# sub wday;
*dow  = \&day_of_week;			# sub dow;
*local_day_of_week = \&day_of_week;	# sub local_day_of_week;

sub day_name {
    my ( $self ) = @_;
    return __weekday_name( $self->day_of_week() );
}

sub day_name_trad {
    my ( $self ) = @_;
    return __trad_weekday_name( $self->day_of_week() );
}

sub day_abbr {
    my ( $self ) = @_;
    return __weekday_abbr( $self->day_of_week() );
}

sub day_abbr_trad {
    my ( $self ) = @_;
    return __trad_weekday_abbr( $self->day_of_week() );
}

sub holiday {
    my ( $self ) = @_;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{holiday};
}

sub holiday_name {
    my ( $self ) = @_;
    return __holiday_name( $self->holiday() );
}

sub holiday_abbr {
    my ( $self ) = @_;
    return __holiday_abbr( $self->holiday() );
}

sub is_leap_year {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{leapyear};
}

sub day_of_year {
    my ( $self ) = @_;

    $self->_recalc_Shire if $self->{recalc};

    return __date_to_day_of_year(
	$self->{year},
	$self->{month},
	$self->{day} || $self->{holiday},
    );
}

*doy  = \&day_of_year;	# sub doy

sub week { return ($_[0]->week_year, $_[0]->week_number); }

*week_year  = \&year;	# sub week_year; the shire calendar is nice this way

sub week_number {
    my $self = shift;
    # TODO re-implement in terms of __week_of_year
    my $yday = $self->day_of_year;

    DAY_NUMBER_MIDYEARS_DAY == $yday
	and return 0;
    DAY_NUMBER_MIDYEARS_DAY < $yday
	and --$yday;

    if ( $self->is_leap_year() ) {
	# In the following, DAY_NUMBER_MIDYEARS_DAY really refers to the
	# Ovelithe, because days greater than Midyear's day were
	# decremented above.
	DAY_NUMBER_MIDYEARS_DAY == $yday
	    and return 0;
	DAY_NUMBER_MIDYEARS_DAY < $yday
	    and --$yday;
    }

    return int( ( $yday - 1 ) / 7 ) + 1;
}

sub quarter {
    my ( $self ) = @_;
    return __quarter( $self->month(), $self->day() || $self->holiday() );
}

sub quarter_name {
    my ( $self ) = @_;
    return __quarter_name( $self->quarter() );
}

sub quarter_abbr {
    my ( $self ) = @_;
    return __quarter_abbr( $self->quarter() );
}

sub day_of_quarter {
    my ( $self ) = @_;
    my $clone = $self->clone();
    $clone->truncate( to => 'quarter' );
    return ( $self->local_rd_values() )[0] - ( $clone->local_rd_values())[0] + 1;
}

# sub doq;
*doq = \&day_of_quarter;

sub am_or_pm {
    splice @_, 1, $#_, '%p';
    goto &strftime;
}

sub era_abbr {
    return $_[0]->year() < 1 ? 'BSR' : 'SR';
}

# deprecated in DateTime
# *era = \&era_abbr;

*christian_era = *secular_era = \&era_abbr;

sub year_with_era {
    return join '', abs( $_[0]->ce_year() ), $_[0]->era_abbr();
}

sub year_with_christian_era {
    return join '', abs( $_[0]->ce_year() ), $_[0]->christian_era();
}

sub year_with_secular_era {
    return join '', abs( $_[0]->ce_year() ), $_[0]->secular_era();
}

sub era_name {
    return $_[0]->year() < 1 ? 'Before Shire Reckoning' : 'Shire Reckoning';
}

sub ce_year {
    my $year = $_[0]->year();
    return $year > 0 ? $year : $year - 1;
}

sub ymd {
    my ( $self, $sep ) = @_;
    defined $sep
	or $sep = '-';
    return $self->strftime( "%{{%Y$sep%m$sep%d||%Y$sep%Ee}}" );
}

# sub date;
*date = \&ymd;

sub dmy {
    my ( $self, $sep ) = @_;
    defined $sep
	or $sep = '-';
    return $self->strftime( "%{{%d$sep%m$sep%Y||%Ee$sep%Y}}" );
}

sub mdy {
    my ( $self, $sep ) = @_;
    defined $sep
	or $sep = '-';
    return $self->strftime( "%{{%m$sep%d$sep%Y||%Ee$sep%Y}}" );
}

sub hms {
    my ( $self, $sep ) = @_;
    defined $sep
	or $sep = ':';
    return $self->strftime( "%H$sep%M$sep%S" );
}

# sub time;
# The DateTime code says the following circumlocution prevents
# overriding of CORE::time
*DateTime::Fiction::JRRTolkien::Shire::time = \&hms;

sub iso8601 { return join 'S', map { $_[0]->$_() } qw{ ymd hms } }

sub accented { return $_[0]->{accented} }
sub traditional { return $_[0]->{traditional} }

*datetime = \&iso8601;		# sub datetime;

# Set methods

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_set',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
		optional	=> 1,
	    },
	    month		=> {
		type		=> __t( 'Month' ),
		optional	=> 1,
	    },
	    day			=> {
		type		=> __t( 'DayOfMonth' ),
		optional	=> 1,
	    },
	    holiday		=> {
		type		=> __t( 'Holiday' ),
		optional	=> 1,
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		optional	=> 1,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		optional	=> 1,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		optional	=> 1,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	    accented		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	    traditional		=> {
		type		=> __t( 'Bool' ),
		optional	=> 1,
	    },
	},
    );

    sub set {
	my ( $self, @args ) = @_;

	my %my_arg = $validator->( @args );

	_check_date( \%my_arg );

	$self->_recalc_Shire if $self->{recalc};

	$my_arg{day}
	    and not $my_arg{month}
	    and not $self->{month}
	    and _croak( 'Need to set month as well as day' );

	if ( $my_arg{month} ) {
	    $my_arg{day} ||= 1;
	    $self->{month} = __month_name_to_number( $my_arg{month} );
	    $self->{holiday} = 0;
	}

	if ( $my_arg{holiday} ) {
	    $self->{holiday} = __holiday_name_to_number( $my_arg{holiday} );
	    $self->{day} = $self->{month} = 0;
	}

	if ( $my_arg{day} ) {
	    $self->{day} = $my_arg{day};
	    $self->{holiday} = 0;
	}

	foreach my $name ( qw{ year accented traditional } ) {
	    defined $my_arg{$name}
		and $self->{$name} = $my_arg{$name};
	}

	$self->{leapyear} = __is_leap_year( $self->{year} );
	$self->{wday} = __day_of_week(
	    $self->{month},
	    $self->{day} || $self->{holiday},
	);

	my %dt_args;
	foreach my $arg ( @delegate_to_dt ) {
	    $dt_args{$arg} = $my_arg{$arg} if defined $my_arg{$arg};
	}

	$self->_recalc_DateTime( %dt_args );

	return $self;
    }
}

# sub set_year; sub set_month; sub set_day; sub set_holiday;
# sub set_hour; sub set_minute; sub set_second; sub set_nanosecond;
# sub set_accented; sub set_traditional;
foreach my $attr ( qw{
    year month day holiday
    hour minute second nanosecond
    accented traditional
} ) {
    my $method = "set_$attr";
    no strict qw{ refs };
    *$method = sub { $_[0]->set( $attr => $_[1] ) };
}

{
    my @midnight = (
	hour	=> 0,
	minute	=> 0,
	second	=> 0,
	nanosecond	=> 0,
    );

    my @quarter_start = (
	undef,
	[ holiday	=> 1 ],
	[ month		=> 4,	day	=> 1 ],
	[ holiday	=> 5 ],
	[ month		=> 10,	day	=> 1 ],
    );

    my %handler = (
	year	=> sub {
	    $_[0]->set(
		holiday	=> 1,
		@midnight,
	    );
	},
	quarter	=> sub {
	    my ( $self ) = @_;
	    # This is an extension to the Shire calendar by Tom Wyant.
	    # It has no textual justification whatsoever. Feel free to
	    # pretend it does not exist.
	    if ( my $quarter = $self->quarter() ) {
		# The start of a quarter is tricky since quarters 1 and
		# 3 start on holidays, so we just do a table lookup.
		$self->set(
		    @{ $quarter_start[ $quarter ] },
		    @midnight,
		);
	    } else {
		# Since Midyear's day and the Overlithe are not part of
		# any quarter, we just truncate them to the nearest day.
		$self->{dt}->truncate( to => 'day' );
	    }
	},
	month	=> sub {
	    my ( $self ) = @_;
	    if ( $self->{holiday} ) {
		# since holidays aren't in any month, this means we just
		# lop off any time
		$self->{dt}->truncate( to => 'day' );
	    } else {
		$self->set(
		    day		=> 1,
		    @midnight,
		);
	    }
	},
	week	=> sub {
	    my ( $self ) = @_;
	    if ( $self->{wday} ) {
		# TODO we do not, at this point in the coding, have date
		# arithmetic. So we do it with rata die.
		my ( $year, $day_of_year ) = __rata_die_to_year_day(
		    ( $self->local_rd_values() )[0] - $self->{wday} + 1 +
		    GREGORIAN_RATA_DIE_TO_SHIRE
		);
		my ( $month, $day ) = __day_of_year_to_date(
		    $year, $day_of_year );
		my %set_arg = (
		    year	=> $year,
		    @midnight,
		);
		if ( $month ) {
		    @set_arg{ qw{ month day } } = ( $month, $day );
		} else {
		    $set_arg{holiday} = $day;
		}
		$self->set( %set_arg );
	    } else {
		$self->{dt}->truncate( to => 'day' );
	    }
	},
    );

    # Weeks in the Shire start on Sterday, but that's what 'week' gives
    # us.
    $handler{local_week} = $handler{week};

    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_truncate',
	name_is_optional	=> 1,
	params			=> {
	    to			=> {
		type		=> __t( 'TruncationLevel' ),
	    },
	},
    );

    sub truncate : method {		## no critic (ProhibitBuiltInHomonyms)
	my ( $self, @args ) = @_;

	my %my_arg = $validator->( @args );

	$self->_recalc_Shire if $self->{recalc};

	if ( my $code = $handler{$my_arg{to}} ) {
	    $code->( $self );
	} else {
	    # only time components will change, DateTime can handle it
	    # fine on its own
	    $self->{dt}->truncate( to => $my_arg{to} );
	}

	return $self;
    }
}

sub set_time_zone {
    my ($self, $tz) = @_;
    $self->{dt}->set_time_zone($tz);
    $self->{recalc} = 1; # in case the day flips when the timezone changes
    return $self;
}

# The following two methods were lifted pretty much verbatim from
# DateTime. The only changes were the guard against holidays (month ==
# 0) and the use of POSIX::floor() rather than int() or use integer;
sub weekday_of_month {
    my ( $self ) = @_;
    $self->month()
	or return 0;
    return POSIX::floor( ( ( $_[0]->day - 1 ) / 7 ) + 1 );
}
# ISO says that the first week of a year is the first week containing
# a Thursday. Extending that says that the first week of the month is
# the first week containing a Thursday. ICU agrees.
# ISO does not really apply to the Shire calendar. This method is
# algorithmically the same as the DateTime method, which amounts to
# taking the first week of the year to be the first week containing a
# Hevensday. We return nothing (undef in scalar context) on a holiday
# because zero is a valid return (e.g. for 1 Rethe). -- TRW
sub week_of_month {
    my ( $self ) = @_;
    $self->month()
	or return;
    my $hev  = $self->day() + 4 - $self->day_of_week();
    return POSIX::floor( ( $hev + 6 ) / 7 );
}

sub strftime {
    my ( $self, @fmt ) = @_;

    return wantarray ?
	( map { __format( $self, $_ ) } @fmt ) :
	__format( $self, $fmt[0] );
}

# Arithmetic

sub duration_class {
    return 'DateTime::Fiction::JRRTolkien::Shire::Duration';
}

sub _make_duration {
    my ( $self, @arg ) = @_;

    1 == @arg
	and _isa( $arg[0], $self->duration_class() )
	and return $arg[0];

    return $self->duration_class()->new( @arg );
}

sub add {
    my ( $self, @arg ) = @_;
    return $self->add_duration( $self->_make_duration( @arg ) );
}

{
    my $validate = Params::ValidationCompiler::validation_for(
        name             => '_check_add_duration_params',
        name_is_optional => 1,
        params           => [
            { type => __t( 'Duration' ) },
        ],
    );

    sub add_duration {
	my ( $self, @arg ) = @_;
	my ( $dur ) = $validate->( @arg );
	return $self->_add_duration( $dur );
    }

    sub subtract_duration {
	my ( $self, @arg ) = @_;
	my ( $dur ) = $validate->( @arg );
	return $self->_add_duration( $dur->inverse() );
    }
}

{
    # The _offset arrays are accessed by
    # @xx_offset[$self->is_leap_year][$forward][$holiday];
    my @month_offset = (
	[	# Not a leap year
	    [ 0, -2, -1, -2,  0, -3, -1 ],	# Going backward
	    [ 0,  1,  3,  2,  0,  1,  2 ],	# Going forward
	],
	[	# A leap year
	    [ 0, -2, -1, -2, -3, -4, -1 ],	# Going backward
	    [ 0,  1,  4,  3,  2,  1,  2 ],	# Going forward
	],
    );
    my @week_offset = (	# Note that we only use indices 3 & 4
	[	# Not a leap year
	    [ 0, 0, 0, -1,  0, 0, 0 ],	# Going backward
	    [ 0, 0, 0,  1,  0, 0, 0 ],	# Going forward
	],
	[	# A leap year
	    [ 0, 0, 0, -1, -2, 0, 0 ],	# Going backward
	    [ 0, 0, 0,  2,  1, 0, 0 ],	# Going forward
	],
    );

    sub _add_duration {
	my ( $self, $dur ) = @_;

        # simple optimization (cribbed shamelessly from DateTime)
	$dur->is_zero()
	    and return $self;

        my %delta = $dur->deltas();

	# This bit isn't quite right since DateTime::Infinite::Future -
	# infinite duration should NaN (cribbed shamelessly from
	# DateTime)
        foreach my $val ( values %delta ) {
            my $inf;
            if ( $val == DateTime->INFINITY ) {
                $inf = DateTime::Infinite::Future->new;
            }
            elsif ( $val == DateTime->NEG_INFINITY ) {
                $inf = DateTime::Infinite::Past->new;
            }

            if ($inf) {
                %$self = %$inf;
                bless $self, ref $inf;

                return $self;
            }
        }

	$self->is_infinite()
	    and return $self;

	if ( $delta{years} || $delta{months} || $delta{weeks} ) {

	    my $forward = $dur->is_forward_mode();
	    my $holiday = $self->holiday();
	    my $leap = $self->is_leap_year();
	    my $orig_rd = my $shire_rd = ( $self->local_rd_values() )[0] +
		GREGORIAN_RATA_DIE_TO_SHIRE;

	    if ( my $months = delete $delta{months} ) {
		$shire_rd +=
		    $month_offset[$leap][$forward][$holiday];
		$holiday = 0;	# No further adjustment needed
		my ( $year, $day_of_year ) = __rata_die_to_year_day(
		    $shire_rd );
		my ( $month, $day ) = __day_of_year_to_date( $year,
		    $day_of_year );
		$month += $months - 1;	# now zero-based
		$year += POSIX::floor( $month / 12 );
		$leap = __is_leap_year( $year );
		$month = 1 + $month % 12;	# now one-based again
		$day_of_year = __date_to_day_of_year( $year, $month,
		    $day );
		$shire_rd = __year_day_to_rata_die( $year, $day_of_year );
	    }

	    if ( my $weeks = delete $delta{weeks} ) {
		$shire_rd += $week_offset[$leap][$forward][$holiday];
		my ( $year, $day_of_year ) = __rata_die_to_year_day(
		    $shire_rd );
		my ( $month, $day ) = __day_of_year_to_date( $year,
		    $day_of_year );
		my $week = __week_of_year( $month, $day );
		my $day_of_week = __day_of_week( $month, $day );
		$week += $weeks - 1;	# now zero-based
		$year += POSIX::floor( $week / 52 );
		$leap = __is_leap_year( $year );
		$week = $week % 52;
		$day_of_year = $week * 7 + $day_of_week;
		$week > 25	# Still zero-based, remember
		    and $day_of_year += $leap + 1;
		$shire_rd = __year_day_to_rata_die( $year, $day_of_year );
	    }

	    if ( my $years = delete $delta{years} ) {
		my ( $year, $day_of_year ) = __rata_die_to_year_day(
		    $shire_rd );
		my ( $month, $day ) = __day_of_year_to_date( $year,
		    $day_of_year );
		my $y = $year + $years;
		my $l = __is_leap_year( $y );
		# If we're leap year day and the new year is not a leap
		# year we have to adjust.
		if ( ! $l && ! $month && $day == 4 ) {
		    $day += $forward ? 1 : -1;
		}
		$day_of_year = __date_to_day_of_year( $y, $month, $day);
		$shire_rd = __year_day_to_rata_die( $y, $day_of_year );
		$leap = $l;
		$holiday = $month ? 0 : $day;
	    }

	    $delta{days} += $shire_rd - $orig_rd;
	}

	if ( grep { $delta{$_} } qw{ days minutes seconds nanoseconds }
	    ) {
	    $self->{dt}->add( %delta );
	    $self->{recalc} = 1;
	}

        return $self;
    }
}

sub subtract {
    my ( $self, @arg ) = @_;
    return $self->subtract_duration( $self->_make_duration( @arg ) );
}

sub subtract_datetime {
    my ( $left, $right ) = @_;
    _isa( $right, __PACKAGE__ )
	or Carp::croak( 'Operand must be a ', __PACKAGE__ );
    my %delta = $left->{dt}->subtract_datetime( $right->{dt}
    )->deltas();
    $delta{years} = $left->year() - $right->year();
    if ( $left->month() && $right->month() ) {
	$delta{months} = $left->month() - $right->month();
	$delta{days} = $left->day() - $right->day();
    } else {
	$delta{days} = $left->day_of_year() - $right->day_of_year();
    }
    return $left->duration_class()->new( %delta );
}

foreach my $method ( qw{ subtract_datetime_absolute delta_days delta_md
    delta_ms } ) {
    no strict qw{ refs };
    *$method = sub {
	my ( $left, $right ) = @_;
	_isa( $right, __PACKAGE__ )
	    and $right = $right->{dt};
	_isa( $right, 'DateTime' )
	    or Carp::croak( 'Operand must be a DateTime or a ', __PACKAGE__ );
	return $left->duration_class()->new(
	    $left->{dt}->$method( $right )->deltas() );
    };
}

# Comparison overloads come with DateTime.  Stringify will be our own
use overload
    '<=>'	=> \&_overload_space_ship,
    'cmp'	=> \&_overload_cmp,
    '""'	=> \&_stringify,
    ;

sub _overload_space_ship {
    defined $_[1]
	or return undef;	## no critic (ProhibitExplicitReturnUndef)
    return $_[2] ? - $_[0]->compare( $_[1] ) : $_[0]->compare( $_[1] );
}

sub _overload_cmp {
    local $@ = undef;
    eval { $_[1]->can( 'utc_rd_values' ) }
	and goto &_overload_space_ship;
    return ( "$_[0]" cmp "$_[1]" ) * ( $_[2] ? -1 : 1 );
}

sub _check_date {
    my ( $arg ) = @_;

    if ( $arg->{holiday} ) {
	$arg->{month}
	    and _croak( 'May not specify both holiday and month' );
	$arg->{day}
	    and _croak( 'May not specify both holiday and day' );
    }

    return;
}

sub _stringify {
    splice @_, 1, $#_, '%Ex';
    goto &strftime;
}

sub on_date {
    splice @_, 1, $#_, '%Ex%n%En%Ed';
    goto &strftime;
}

# sub hour; sub minute; sub min; sub second; sub sec; sub nanosecond;
# sub hour_1; sub hour_12; sub hour_12_0;
# sub fractional_second; sub millisecond; sub microsecond;
# sub time_zone; sub time_zone_long_name; sub time_zone_short_name
# sub epoch; sub hires_epoch; sub utc_rd_values; sub utc_rd_as_seconds;
# sub set_formatter; sub offset; sub locale; sub set_locale;
# sub mjd; sub jd;
# sub is_dst; sub is_finite; sub is_infinite; sub leap_seconds;
# sub formatter; sub utc_year;
# sub local_rd_as_seconds; sub local_rd_values;
foreach my $method ( qw{
    hour minute min second sec nanosecond
    hour_1 hour_12 hour_12_0
    fractional_second millisecond microsecond
    time_zone time_zone_long_name time_zone_short_name
    epoch hires_epoch utc_rd_values utc_rd_as_seconds
    set_formatter offset locale set_locale
    mjd jd
    is_dst is_finite is_infinite leap_seconds
    formatter utc_year
    local_rd_as_seconds local_rd_values
} ) {
    no strict qw{ refs };
    *$method = sub {
	my ( $self, @arg ) = @_;
	return $self->{dt}->$method( @arg )
    };
}

*DefaultLocale = \&DateTime::DefaultLocale;

# These assume the corresponding DateTime routines only use the public
# interface. The last time I assumed that, second thoughts made me
# re-implement. We'll see how long this code stands. Though it may stand
# for a while, since the documentation also says that all that is needed
# is a utc_rd_values() method, which we have.
sub compare {
    ref $_[0]
	or shift @_;
    return DateTime->compare( @_ );
}

sub compare_ignore_floating {
    ref $_[0]
	or shift @_;
    return DateTime->compare_ignore_floating( @_ );
}

# NOTE: I do not feel the need to load Storable, because if these are
# being called it has already been loaded. Either that or somebody is
# mucking around in the internals, in which case they are on their own.
sub STORABLE_freeze {
    my ( $self ) = @_;
    return Storable::freeze(
	{
	    accented	=> $self->{accented},
	    traditional	=> $self->{traditional},
	},
    ),
    $self->{dt},
};

sub STORABLE_thaw {
    my ( $self, undef, $serialized, $dt ) = @_;
    %{ $self } = %{ Storable::thaw( $serialized ) };
    $self->{dt} = $dt;
    $self->{recalc} = 1;
    return $self;
}

# Date::Tolkien::Shire::Data::__format() interface.

*__fmt_shire_year	= \&year;	# sub __fmt_shire_year
*__fmt_shire_month	= \&month;	# sub __fmt_shire_month;

sub __fmt_shire_day {
    my ( $self ) = @_;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{day} || $self->{holiday};
}

*__fmt_shire_day_of_week = \&day_of_week;	# sub __fmt_shire_day_of_week
*__fmt_shire_hour	= \&hour;	# sub __fmt_shire_hour;
*__fmt_shire_minute	= \&minute;	# sub __fmt_shire_minute;
*__fmt_shire_second	= \&second;	# sub __fmt_shire_second;
*__fmt_shire_nanosecond	= \&nanosecond;	# sub __fmt_shire_nanosecond;
*__fmt_shire_epoch	= \&epoch;	# sub __fmt_shire_epoch;
*__fmt_shire_zone_offset	= \&offset;	# sub __fmt_shire_zone_offset;
*__fmt_shire_zone_name	= \&time_zone_short_name;	# sub __fmt_shire_zone_name;
*__fmt_shire_accented = \&accented;		# sub __fmt_shire_accented;
*__fmt_shire_traditional = \&traditional;	# sub __fmt_shire_traditional

# sub day_of_month_0; sub day_0; sub mday_0;
# sub day_of_year_0; sub doy_0;
# sub quarter_0; sub day_of_quarter_0; sub doq_0;
# sub day_of_week_0; sub wday_0; sub dow_0;
# sub month_0; sub mon_0;
foreach my $method ( qw{
    day_of_month day mday
    day_of_year doy
    quarter day_of_quarter doq
    day_of_week wday dow
    month mon
} ) {
    my $method_0 = $method . '_0';
    no strict qw{ refs };
    *$method_0 = sub { $_[0]->$method() - 1 };
}

sub _croak {
    my @msg = @_;
    Carp::croak( __PACKAGE__ . ": @msg" );
}

sub _isa { return Scalar::Util::blessed( $_[0] ) && $_[0]->isa( $_[1] ) }

1;

__END__

=head1 NAME

DateTime::Fiction::JRRTolkien::Shire - DateTime implementation of the Shire calendar.

=head1 SYNOPSIS

    use DateTime::Fiction::JRRTolkien::Shire;

    # Constructors
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 'Rethe',
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 3,
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          holiday => '2 Lithe');

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_epoch(
	epoch = $time);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->today;
	# same as from_epoch(epoch = time());

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_object(
        object => $some_other_DateTime_object);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(
        year => 1420,
        day_of_year => 182);
    my $shire2 = $shire->clone;

    # Accessors
    $year = $shire->year;
    $month = $shire->month;            # 1 - 12, or 0 on a holiday
    $month_name = $shire->month_name;
    $day = $shire->day;                # 1 - 30, or 0 on a holiday

    $dow = $shire->day_of_week;        # 1 - 7, or 0 on certain holidays
    $day_name = $shire->day_name;

    $holiday = $shire->holiday;
    $holiday_name = $shire->holiday_name;

    $leap = $shire->is_leap_year;

    $time = $shire->epoch;
    @rd = $shire->utc_rd_values;

    # Set Methods
    $shire->set(year => 7463,
                month => 5,
                day => 3);
    $shire->set(year => 7463,
                holiday => 6);
    $shire->truncate(to => 'month');

    # Comparisons
    $shire < $shire2;
    $shire == $shire2;

    # Strings
    print "$shire1\n"; # Prints Sunday 25 Rethe 1419

    # On this date in history
    print $shire->on_date;

=head1 DESCRIPTION

Implementation of the calendar used by the hobbits in J.R.R. Tolkien's
exceptional novel The Lord of The Rings, as described in Appendix D of
that book (except where noted).  The calendar has 12 months, each with
30 days, and 5 holidays that are not part of any month.  A sixth
holiday, Overlithe, is added on leap years.  The holiday Midyear's Day
(and the Overlithe on a leap year) is not part of any week, which means
that the year always starts on Sterday.

This module is a follow-on to the
L<Date::Tolkien::Shire|Date::Tolkien::Shire> module, and is rewritten to
support Dave Rolsky and company's L<DateTime|DateTime> module. The
DateTime module must be installed for this module to work.

This module provides support for most L<DateTime|DateTime>
functionality, with the known exception of C<format_cldr()>, which may
be added later.

Support for L<strftime()|/strftime> comes from
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data>, and you should
see the documentation for that module for the details of the formatting
codes.

Some assumptions have had to be made on how the
hobbits represent time. We have references to (e.g.) "nine o'clock" (in
the morning), which seem to imply they start the day at midnight. But
there appears to be nothing to say whether they used a 12- or 24-hour
clock. Default time formats (say, '%X') use a 12-hour clock because that
is the English system and Tolkien did not specify anything to the
contrary.

Calendar quarters are not mentioned at all in any of Tolkien's writings
(that I can find -- Wyant), but are part of the L<DateTime|DateTime>
interface. This package implements a quarter as being exactly 13 weeks,
with Midyear's day and Overlithe not being part of any quarter, on no
better justification than that the present author thinks that is
consistent with the Shire's approach to horology.

=head1 METHODS

Most of these methods mimic their corresponding DateTime methods in
functionality.  For additional information on these methods, see the
DateTime documentation.

=head2 Constructors

=head3 new

 my $dt_ring = DateTime::Fiction::JRRTolkien::Shire->new(
     year   => 1419,
     month  => 3,
     day    => 25,
 );
 my $dt_aa = DateTime::Fiction::JRRTolkien::Shire->new(
     year    => 1419,
     holiday => 3,     # Midyear's day
 );

This method takes a year, month, and day parameter, or a year and
holiday parameter.  The year can be any value.  The month can be
specified with a string giving the name of the month (the same string
that would be returned by month_name, with the first letter capitalized
and the rest in lower case) or by giving the numerical value for the
month, between 1 and 12.  The day should always be between 1 and 30.  If
a holiday is given instead of a day and month, it should be the name of
the holiday as returned by holiday_name (with the first letter of each
word capitalized) or a value between 1 and 6.  The 1 through 6 numbers
map to holidays as follows:

    1 => 2 Yule
    2 => 1 Lithe
    3 => Midyear's Day
    4 => Overlithe      # Leap years only
    5 => 2 Lithe
    6 => 1 Yule

The C<new()> method will also take parameters for hour, minute, second,
nanosecond, time_zone and locale. If given, these parameters will be
stored in case the object is converted to another class that makes use
of these attributes.

Additionally, parameters C<accented> and C<traditional> control the form
of C<on_date()> text (accented or not) and week day names (traditional
or common) generated. These must be C<undef>, C<''>, or C<0> (for false)
or C<1> (for true).

If a day is not given, it will default to 1.  If neither a day or month
is given, the date will default to 2 Yule, the first day of the year.

=head3 from_epoch

     $dts = DateTime::Fiction::JRRTolkien::Shire->from_epoch(
         epoch  => time,
         ...
     );

Same as in DateTime, but you can also specify parameters C<accented> and
C<traditional> (see L<new()|/new>).

=head3 now

    $dts = DateTime::Fiction::JRRTolkien::Shire->now( ... );

Same as in DateTime, but you can also specify parameters C<accented> and
C<traditional> (see L<new()|/new>).  Note that this is equivalent to

    from_epoch( epoch => time() );

and produces an object whose time zone is C<UTC>.

=head3 now_local

    $dts = DateTime::Fiction::JRRTolkien::Shire->now_local( ... );

This static method creates a new object set to the current local time.
Under the hood it just calls the C<localtime()> built-in, and then calls
L<new()|/new> with the results. Unlike L<now()|/now>, this method
produces an object whose zone is C<floating>.

=head3 today

    $dts = DateTime::Fiction::JRRTolkien::Shire->today( ... );

Same as in DateTime, but you can also specify parameters C<accented> and
C<traditional> (see L<new()|/new>).

=head3 from_object

    $dts = DateTime::Fiction::JRRTolkien::Shire->from_object(
        object  => $object,
        ...
    );

Same as in DateTime, but you can also specify parameters C<accented> and
C<traditional> (see L<new()|/new>). Takes any other DateTime calendar
object and converts it to a DateTime::Fiction::JRRTolkien::Shire object.

=head3 last_day_of_month

    $dts = DateTime::Fiction::JRRTolkien::Shire->last_day_of_month(
        year    => 1419,
        month   => 3,
        ...
    );

Same as in DateTime.  Like the C<new()> constructor, but it does not
take a day parameter.  Instead, the day is set to 30, which is the last
day of any month in the shire calendar. A holiday parameter should not
be used with this method.  Use L<new()|/new> instead.

=head3 from_day_of_year

    $dts = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(
        year           => 1419,
        day_of_year    => 86,
        ...
    );

Same as in DateTime.  Gets the date from the given year and day of year,
both of which must be given.  Hour, minute, second, time_zone, etc.
parameters may also be given, and will be passed to the underlying
DateTime object, just like in C<new()>.

=head3 clone

    $dts2 = $dts->clone();

Creates a new Shire object that is the same date (and underlying time)
as the calling object.

=head2 "Get" Methods

=head3 calendar_name

    print $dts->calendar_name(), "\n";

Returns C<'Shire'>.

=head3 year

    print 'Year: ', $dts->year(), "\n";

Returns the year.

=head3 month

    print 'Month: ', $dts->month(), "\n";

Returns the month number, from 1 to 12.  If the date is a holiday, a 0
is returned for the month.

=head3 mon

Synonym for L<month()|/month>.

=head3 month_name

    print 'Month name: ', $dts->month_name(), "\n";

Returns the name of the month. If the date is a holiday, an empty
string is returned.

=head3 day_of_month

    print 'Day of month: ', $dts->day_of_month(), "\n";

Returns the day of the current month, from 1 to 30.  If the date is a
holiday, 0 is returned.

=head3 day

Synonym for L<day_of_month()|/day_of_month>.

=head3 mday

Synonym for L<day_of_month()|/day_of_month>.

=head3 day_of_week

    print 'Day of week: ', $dts->day_of_week(), "\n";

Returns the day of the week from 1 to 7.  If the day is not part of
any week (Midyear's Day or the Overlithe), 0 is returned.

=head3 wday

Synonym for L<day_of_week|/day_of_week>.

=head3 dow

Synonym for L<day_of_week|/day_of_week>.

=head3 day_name

    print 'Common name of day of week: ',
        $dts->day_name(), "\n";

Returns the common name of the day of the week, or an empty string if
the day is not part of any week. This method is not affected by the
L<traditional()|/traditional> setting, for historical reasons.

=head3 day_name_trad

    print 'Traditional name of day of week: ',
        $dts->day_name_trad(), "\n";

Returns the common name of the day of the week, or an empty string if
the day is not part of any week. This method is not affected by the
L<traditional()|/traditional> setting, for historical reasons.

=head3 day_abbr

    print 'Common abbreviation of day of week: ',
        $dts->day_abbr(), "\n";

Returns the common abbreviation of the day of the week, or an empty
string if the day is not part of any week. This method is not affected
by the L<traditional()|/traditional> setting, for consistency with
L<day_name()|/day_name>.

=head3 day_abbr_trad

    print 'Traditional abbreviation of day of week: ',
        $dts->day_abbr_trad(), "\n";

Returns the traditional abbreviation of the day of the week, or an empty
string if the day is not part of any week. This method is not affected
by the L<traditional()|/traditional> setting, for consistency with
L<day_name_trad()|/day_name_trad>.

=head3 day_of_year

    print 'Day of year: ', $dts->day_of_year(), "\n";

Returns the day of the year, from 1 to 366

=head3 doy

Synonym for L<day_of_year()|/day_of_year>.

=head3 holiday

    print 'Holiday number: ', $dts->holiday(), "\n";

Returns the holiday number (given in the description of the
L<new()|/new> constructor).  If the day is not a holiday, 0 is returned.

=head3 holiday_name

    print 'Holiday name: ', $dts->holiday_name(), "\n";

Returns the name of the holiday. If the day is not a holiday, an empty
string is returned.

=head3 holiday_abbr

    print 'Holiday abbreviation: ', $dts->holiday_abbr(), "\n";

Returns the abbreviation of the holiday. If the day is not a holiday, an
empty string is returned.

=head3 is_leap_year

    my @ly = ( 'is not', 'is' );
    printf "%d %s a leap year\n", $dts->year(),
        $ly[ $dts->is_leap_year() ];

Returns 1 if the year is a leap year, and 0 otherwise.

Leap years are given the same rule as the Gregorian calendar.  Every
four years is a leap year, except the first year of the century, which
is not a leap year.  However, every fourth century (400 years), the
first year of the century is a leap year (every 4, except every 100,
except every 400).  This is a slight change from the calendar described
in Appendix D, which uses the rule of once every 4 years, except every
100 years (the same as in the Julian calendar).  Given some uncertainty
about how many years have passed since the time in Lord of the Rings
(see note below), and the expectations of most people that the years
match up with what they're used to, I have changed this rule for this
implementation.  However, this does mean that this calendar
implementation is not strictly that described in Appendix D.

=head3 week_year

    print 'The week year is ', $dts->week_year(), "\n";

This is always the same as the year in the shire calendar, but is
present for compatibility with other DateTime objects.

=head3 week_number

    print 'The week number is ', $dts->week_number(), "\n";

Returns the week of the year, or C<0> for days that are not part of any
week: Midyear's day and the Overlithe.

=head3 week

    printf "Year %d; Week number %d\n", $dts->week();

Returns a two element array, where the first is the week_year and the
latter is the week_number.

=head3 weekday_of_month

Same as L<DateTime|DateTime>, but returns C<0> for a holiday.

=head3 week_of_month

Same as L<DateTime|DateTime>, but returns nothing (C<undef> in scalar
context) for a holiday. The return for a holiday can not be C<0>,
because this is a valid return, e.g. for 1 Rethe.

=head3 epoch

    print scalar gmtime $dts->epoch(), "UT\n";

Returns the epoch of the given object, just like in DateTime.

=head3 hires_epoch

Returns the epoch as a floating point number, with the fractional
portion for fractional seconds.  Functions the same as in DateTime.

=head3 quarter

Returns the number of the quarter the day is in, in the range 1 to 4. If
the day is part of no quarter (Midyear's day and the Overlithe), returns
0.

There is no textual justification for quarters, but they are in the
L<DateTime|DateTime> interface, so I rationalized the concept the same
way the Shire calendar rationalizes weeks. If you are not interested in
non-canonical functionality, please ignore anything involving quarters.

=head3 quarter_0

Returns the number of the quarter the day is in, in the range 0 to 3. If
the day is part of no quarter (Midyear's day and the Overlithe), returns
-1.

=head3 quarter_name

Returns the name of the quarter.

=head3 quarter_abbr

Returns the abbreviation of the quarter.

=head3 day_of_quarter

Returns the day of the date in the quarter, in the range 1 to 91. If the
day is Midyear's day or the Overlithe, you get 1.

=head3 era_name

Returns either C<'Shire Reckoning'> if the year is positive, or
C<'Before Shire Reckoning'> otherwise.

=head3 era_abbr

Returns either C<'SR'> if the year is positive, or C<'BSR'> otherwise.

=head3 christian_era

This really does not apply to the Shire calendar, but it is part of the
L<DateTime|DateTime> interface. Despite its name, it returns the same
thing that L<era_abbr()|/era_abbr> does.

=head3 secular_era

Returns the same thing L<era_abbr()|/era_abbr> does.

=head3 utc_rd_values

Returns the UTC rata die days, seconds, and nanoseconds. Ignores
fractional seconds.  This is the standard method used by other methods
to convert the shire calendar to other calendars.  See the DateTime
documentation for more information.

=head3 utc_rd_as_seconds

Returns the UTC rata die days entirely as seconds.

=head3 on_date

Returns the current day, with day of week if present, and with all names
in full.  If the day has some events that transpired
on it (as defined in Appendix B of the Lord of the Rings), those events
are appended. This can be fun to put in a F<.bashrc> or F<.cshrc>.
Try

    perl -MDateTime::Fiction::JRRTolkien::Shire
      -le 'print DateTime::Fiction::JRRTolkien::Shire->now->on_date;'

=head3 iso8601

This is not, of course, a true ISO-8601 implementation. The differences
are that holidays are represented by their abbreviations (e.g.
C<'1419-Myd'>, and that the date and time are separated by the letter
C<'S'>, not C<'T'>.

=head3 strftime

    print $dts->strftime( '%Ex%n' );

This is a re-implementation imported from
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data>. It is intended
to be reasonably compatible with the same-named L<DateTime|DateTime>
method, but has some additions to deal with the peculiarities of the
Shire calendar.

See L<__format()|Date::Tolkien::Shire::Data/__format> in
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data> for the
documentation, since that is the code that does the heavy lifting for
us.

=head3 accented

This method returns a true value if the event descriptions returned by
L<on_date()|/on_date> and L<strftime()|/strftime> are to be accented.

=head3 traditional

This method returns a true value if the dates returned by
L<on_date()|/on_date>, L<strftime()|/strftime>, and stringification are
to use traditional rather than common weekday names.

=head2 "Set" Methods

=head3 set

    $dts->set(
        month   => 3,
        day     => 25,
    );

Allows the day, month, and year to be changed.  It takes any parameters
allowed by the L<new()|/new> constructor, including all those supported
by DateTime and the holiday parameter, except for time_zone. Any
parameters not given will be left as is.  However, with holidays not
falling in any month, it is recommended that a day and month always be
given together.  Otherwise, unanticipated results may occur.

As in the L<new()|/new> constructor, time parameters have no effect on
the Shire dates returned.  However, they are maintained in case the
object is converted to another calendar which supports time.

All C<set_*()> methods from L<DateTime|DateTime> are provided. In
addition, you get the following:

=head3 set_holiday

This convenience method is implemented in terms of

    $dts->set( holiday => ... );

=head3 set_accented

This convenience method is implemented in terms of

    $dts->set( accented => ... );

=head3 set_traditional

This convenience method is implemented in terms of

    $dts->set( traditional => ... );

=head3 truncate

    $dts->truncate( to => 'day' );

Like the corresponding L<DateTime|DateTime> method, with the following
exceptions:

If the date is a holiday, truncation to C<'month'> is equivalent to
truncation to C<'day'>, since holidays are not part of any month.

Similarly, if the date is Midyear's day or the Overlithe, truncation to
C<'week'>, C<'local_week'>, or C<'quarter'> is equivalent to truncation
to C<'day'>, since these holidays are not part of any week (or, by
extension, quarter).

The week in the Shire calendar begins on Sterday, so both C<'week'> and
C<'local_week'> truncate to that day.

There is no textual justification for quarters, but they are in the
L<DateTime|DateTime> interface, so I rationalized the concept the same
way the Shire calendar rationalizes weeks. If you are not interested in
non-canonical functionality, please ignore anything involving quarters.

=head3 set_time_zone

    $dts->set_time_zone( 'UTC' );

Just like in DateTime. This method has no effect on the shire calendar,
but be stored with the date if it is ever converted to another calendar
with time support.

=head2 Comparisons and Stringification

All comparison operators should work, just as in DateTime.  In addition,
all C<DateTime::Fiction::JRRTolkien::Shire> objects will interpolate
into a string representing the date when used in a double-quoted string.

=head2 Durations and Date Math

Durations and date math are supported as of 0.900_01.
Because of the peculiarities of the Shire calendar, the relevant
duration object is
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>,
which is B<not> a subclass of L<DateTime::Duration|DateTime::Duration>.

The date portion of the math is done in the order L<month|/month>,
L<week|/week>, L<year|/year>, L<day|/day>. Before adding (or
subtracting) months or weeks from a date that is not part of any month
(or week), that date will be adjusted forward or backward to the nearest
date that is part of a month (or week). The direction of adjustment is
specified by the
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object; see its documentation for the details. The order of operation
was chosen to ensure that only one such adjustment would be necessary
for any computation.

=head3 add

This convenience method takes as arguments either a
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object or the arguments needed to manufacture one. The duration is then
passed to L<add_duration()|/add_duration>.

=head3 add_duration

This method takes as its argument a
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object. This is added to the invocant (i.e. it is a mutator). The
invocant is returned.

=head3 subtract

This convenience method takes as arguments either a
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object or the arguments needed to manufacture one. The duration is then
passed to L<subtract_duration()|/subtract_duration>.

=head3 subtract_duration

This convenience method takes as its argument a
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object. The inverse of this object is then passed to
L<add_duration()|/add_duration>.

=head3 subtract_datetime

This takes as its argument a
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
object. The return is a
L<DateTime::Fiction::JRRTolkien::Shire::Duration|DateTime::Fiction::JRRTolkien::Shire::Duration>
object representing the difference between the two objects. If either
the invocant or the argument represents a holiday, the date portion of
this difference will contain C<years> and C<days>. Otherwise it will
contain C<years>, C<months> and C<days>.

=head3 subtract_datetime_absolute, delta_days, delta_md, delta_ms

These are just delegated to the corresponding L<DateTime|DateTime>
method.  The argument can be either a
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
object or a L<DateTime|DateTime> object.

=head1 NOTE: YEAR CALCULATION

L<https://www.glyphweb.com/arda/f/fourthage.html> references a letter sent
by Tolkien in 1958 in which he estimates approximately 6000 years have
passed since the War of the Ring and the end of the Third Age.  (Thanks
to Danny O'Brien from sending me this link).  I took this approximate as
an exact amount and calculated back 6000 years from 1958.  This I set as
the start of the 4th age (1422 S.R.).  Thus the fourth age begins in our
B.C 4042.

According to Appendix D of the Lord of the Rings, leap years in the
hobbits'
calendar are every 4 years unless it is the turn of the century, in which
case it is not a leap year. Our calendar (Gregorian) uses every 4 years
unless it's 100 years unless its 400 years.  So, if no changes have been
made to the hobbits' calendar since the end of the third age, their
calendar would be about 15 days further behind ours now than when the
War of the Ring took place.  Implementing this seemed to me to go
against Tolkien's general habit of converting dates in the novel to our
equivalents to give us a better sense of time.  My thought, at least
right now, is that it is truer to the spirit of things for years to line
up, and for Midyear's day to still be approximately on the summer
solstice.  So instead, I have modified Tolkien's description of the
hobbit calendar so that leap years occur once every 4 years unless it's
100 years unless it's 400 years, so as it matches the Gregorian calendar
in that regard.  These 100 and 400 year intervals occur at different
times in the two calendars, so there is not a one to one correspondence
of days regardless of years.  However, the variations follow a 400 year
cycle.

I<The "I" in the above is Tom Braun -- TRW>

=head1 AUTHOR

Tom Braun <tbraun@pobox.com>

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 Tom Braun. All rights reserved.

Copyright (C) 2017-2021 Thomas R. Wyant, III

The calendar implemented on this module was created by J.R.R. Tolkien,
and the copyright is still held by his estate.  The license and
copyright given herein applies only to this code and not to the
calendar itself.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text
of the licenses in the LICENSES directory included with this module.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 SUPPORT

Support on this module may be obtained by emailing me. However, I am
not a developer on the other classes in the DateTime project. For
support on them, please see the support options in the DateTime
documentation.

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Fiction-JRRTolkien-Shire>,
L<https://github.com/trwyant/perl-DateTime-Fiction-JRRTolkien-Shire/issues>, or in
electronic mail to the author.

=head1 BIBLIOGRAPHY

Tolkien, J. R. R. I<Return of the King>.  New York: Houghton Mifflin
Press, 1955.

L<https://www.glyphweb.com/arda/f/fourthage.html>

=head1 SEE ALSO

The DateTime project documentation (perldoc DateTime, datetime@perl.org
mailing list, or L<http://datetime.perl.org/>).

=cut

1;

# ex: set textwidth=72 :
