package DateTime::Incomplete;

use strict;

use DateTime::Set 0.0901;
use DateTime::Event::Recurrence;
use Params::Validate qw( validate );

use vars qw( $VERSION );

my $UNDEF_CHAR;
my ( @FIELDS, %FIELD_LENGTH, @TIME_FIELDS, @FIELDS_SORTED );

BEGIN
{
    $VERSION = '0.08';

    $UNDEF_CHAR = 'x';

    @FIELDS = ( year => 0, month => 1, day => 1, 
                hour => 0, minute => 0, second => 0, nanosecond => 0 );
    %FIELD_LENGTH = ( 
                year => 4, month => 2, day => 2, 
                hour => 2, minute => 2, second => 2, nanosecond => 9,
                time_zone => 0, locale => 0 );
    @TIME_FIELDS = qw( hour minute second nanosecond );

    @FIELDS_SORTED = qw( year month day 
                hour minute second nanosecond 
                time_zone locale );

    # Generate named accessors

    for my $field ( @FIELDS_SORTED )
    {
	no strict 'refs';
	*{$field} = sub { $_[0]->_get($field) };
	*{"has_$field"} = sub { $_[0]->_has($field) };

        next if $field eq 'nanosecond';

	my $length = $FIELD_LENGTH{$field};

	next unless $length;

	*{"_$field"} = sub { defined $_[0]->$field() ?
			     sprintf( "%0.${length}d", $_[0]->$field() ) :
			     $UNDEF_CHAR x $length };
    }

    # Generate DateTime read-only functions

    for my $meth ( qw/
        epoch
        hires_epoch
        is_dst
        utc_rd_values
        utc_rd_as_seconds
        / )
    {
        no strict 'refs';
        *{$meth} = sub 
                   { 
                       # to_datetime() dies if there is no "base"
                       # we get 'undef' if this happens
                       eval { (shift)->to_datetime( @_ )->$meth() };
                   };
    }

    for my $meth ( qw/
        week week_year week_number week_of_month
        day_name day_abbr 
        day_of_week wday dow
        day_of_year doy
        quarter day_of_quarter doq
        weekday_of_month
        jd mjd
        / )
    {
	no strict 'refs';
	*{$meth} = sub { $_[0]->_datetime_method( $meth, 'year', 'month', 'day' ) };
    }

    for my $meth ( qw/
        is_leap_year ce_year era year_with_era
        / )
    {
	no strict 'refs';
	*{$meth} = sub { $_[0]->_datetime_method( $meth, 'year' ) };
    }

    for my $meth ( qw/
        month_name month_abbr
        / )
    {
	no strict 'refs';
	*{$meth} = sub { $_[0]->_datetime_method( $meth, 'month' ) };
    }

    for my $meth ( qw/
        hour_1 hour_12 hour_12_0
        / )
    {
	no strict 'refs';
	*{$meth} = sub { $_[0]->_datetime_method( $meth, 'hour' ) };
    }

    for my $meth ( qw/
        millisecond microsecond
        / )
    {
	no strict 'refs';
	*{$meth} = sub { $_[0]->_datetime_method( $meth, 'nanosecond' ) };
    }
}

*_nanosecond = \&_format_nanosecs;

*mon = \&month;
*day_of_month = \&day;
*mday = \&day;
*min = \&minute;
*sec = \&second;

# Internal sub to call "DateTime" methods
sub _datetime_method
{
    my ( $self, $method ) = ( shift, shift );
    my @fields = @_;   # list of required fields
    my $date;
    for ( @fields )
    {
        return undef unless ( $self->_has($_) )
    }
    my %param; 

    # if we don't need 'year', then we can safely set it to whatever.
    $param{year} = 1970 if ! @fields || $fields[0] ne 'year';

    $param{locale} = $self->locale if $self->has_locale;
    $param{time_zone} = $self->time_zone if $self->has_time_zone;
    $param{$_} = $self->$_() for @fields;
    $date = DateTime->new( %param );
    
    return $date->$method();
}

# DATETIME-LIKE METHODS

sub fractional_second {
    $_[0]->_datetime_method( 'fractional_second', 'second', 'nanosecond' );
}

sub offset {
    $_[0]->_datetime_method( 'offset' );
}
sub time_zone_short_name {
    $_[0]->_datetime_method( 'time_zone_short_name' );
}
sub time_zone_long_name  {
    $_[0]->_datetime_method( 'time_zone_long_name' );
}

sub _from_datetime
{
    my $class = shift;
    my $dt = shift;
    my %param;
    $param{$_} = $dt->$_() for @FIELDS_SORTED;
    return $class->new( %param );
}

sub last_day_of_month {
    my $self = shift;
    my %param = @_;
    my $result = $self->_from_datetime( DateTime->last_day_of_month( @_ ) );
    for ( @TIME_FIELDS ) {
        $result->set( $_, undef ) unless defined $param{$_};
    }
    return $result;
}

sub from_epoch {
    return (shift)->_from_datetime( DateTime->from_epoch( @_ ) );
}
sub now {
    return (shift)->_from_datetime( DateTime->now( @_ ) );
}
sub from_object {
    return (shift)->_from_datetime( DateTime->from_object( @_ ) );
}

sub from_day_of_year {
    my $self = shift;
    my %param = @_;
    my $result = $self->_from_datetime( DateTime->from_day_of_year( @_ ) );
    for ( @TIME_FIELDS ) {
        $result->set( $_, undef ) unless defined $param{$_};
    }
    return $result;
}

sub today
{
    my $class = shift;
    my $now = DateTime->now( @_ );
    my %param;
    my %fields = ( %FIELD_LENGTH );
    delete $fields{$_} for ( qw/ hour minute second nanosecond / );
    $param{$_} = $now->$_() for ( keys %fields );
    return $class->new( %param );
}

sub new 
{
    # parameter checking is done in "set" method.
    my $class = shift;
    my %param = @_;
    my $base = delete $param{base};
    die "base must be a datetime" if defined $base && 
                             ! UNIVERSAL::can( $base, 'utc_rd_values' );
    my $self = bless { 
        has => \%param,
    }, $class;
    $self->set_base( $base );
    $self->set( locale => $self->{has}{locale} ) if $self->{has}{locale};
    $self->set_time_zone( $self->{has}{time_zone} ) if $self->{has}{time_zone};
    return $self;
}

sub set_base 
{
    my $self = shift;
    $self->{base} = shift;
    if ( defined $self->{base} ) 
    {
        my ($key, $value);
        while (($key, $value) = each %{$self->{has}} ) {
            next unless defined $value;
            if ( $key eq 'time_zone' )
            {
                $self->{base}->set_time_zone( $value );
                next;
            }        
            $self->{base}->set( $key => $value );
        }
    }
}

sub base
{
    return undef unless defined $_[0]->{base};
    $_[0]->{base}->clone;
}

sub has_base
{
    return defined $_[0]->{base} ? 1 : 0;
}

sub set
{
    my $self = shift;
    my %p = @_;

    while ( my ( $k, $v ) = each %p )
    {
	if ( $k eq 'locale' )
	{
	    $self->_set_locale($v);
            next;
	}

	$self->{base}->set( $k => $v ) if $self->{base} && defined $v;

	$self->{has}{ $k } = $v;
    }
}

sub _get
{
    $_[0]->{has}{$_[1]};
}

sub _has
{
    defined $_[0]->{has}{$_[1]} ? 1 : 0;
}

sub has {  
    # returns true or false  
    my $self = shift;  
    foreach (@_) {  
        return 0 unless $self->_has( $_ )  
    }  
    return 1  
}  

sub has_date {
    $_[0]->has_year && $_[0]->has_month && $_[0]->has_day
}

sub has_time {
    $_[0]->has_hour && $_[0]->has_minute && $_[0]->has_second
}

sub defined_fields {  
    # no params, returns a list of fields  
    my $self = shift;  
    my @has = ();
    for ( @FIELDS_SORTED )
    {
        push @has, $_ if $self->_has( $_ );
    }
    return @has;
}  

sub can_be_datetime {  
    my $self = shift;  
    return 0 if ! $self->has_year;
    my $can = 1;
    for ( qw( month day hour minute second nanosecond ) )
    {
        return 0 if ! $can && $self->_has( $_ );
        $can = 0 if $can && ! $self->_has( $_ );
    }
    return 1;
}  

#sub become_datetime {
#    my $self = shift;
#    return undef unless $self->has_year;
#    # warn "param = @{[  %{$self->{has}}  ]} ";
#    # return DateTime->new( %{$self->{has}} );
#    my @parm = map { ( $_, $self->$_() ) } $self->defined_fields;
#    # warn "param = @parm";
#    return DateTime->new( @parm );
#}

sub set_time_zone
{
    die "set_time_zone() requires a time_zone value" unless $#_ == 1;
    my $time_zone = $_[1];
    if ( defined $time_zone )
    {
        $time_zone = DateTime::TimeZone->new( name => $time_zone ) unless ref $time_zone;
        $_[0]->{base}->set_time_zone( $time_zone ) if defined $_[0]->{base};
    }
    $_[0]->{has}{time_zone} = $time_zone;
}

sub _set_locale
{
    die "set_locale() requires a locale value" unless $#_ == 1;
    my $locale = $_[1];
    if ( defined $locale )
    {
        $locale = DateTime::Locale->load( $locale ) unless ref $locale;
        $_[0]->{base}->set( locale => $locale ) if defined $_[0]->{base};
    } 
    $_[0]->{has}{locale} = $locale;
}

sub clone 
{ 
    my $base;
    $base = $_[0]->{base}->clone if defined $_[0]->{base};
    bless { 
        has => { %{ $_[0]->{has} } }, 
        base => $base,
    }, 
    ref $_[0]; 
}

sub is_finite { 1 }
sub is_infinite { 0 }


sub truncate
{
    my $self = shift;
    my %p = validate( @_,
                      { to =>
                        { regex => qr/^(?:year|month|day|hour|minute|second)$/ },
                      },
                    );

    my @fields = @FIELDS;
    my $field;
    my $value;
    my $set = 0;

    while ( @fields )
    {
        ( $field, $value ) = ( shift @fields, shift @fields );
        $self->set( $field => $value ) if $set;
        $set = 1 if $p{to} eq $field;
    }
    return $self;
}


# Stringification methods

sub ymd
{
    my ( $self, $sep ) = ( @_, '-' );
    return $self->_year . $sep. $self->_month . $sep . $self->_day;
}
*date = \&ymd;

sub mdy
{
    my ( $self, $sep ) = ( @_, '-' );
    return $self->_month . $sep. $self->_day . $sep . $self->_year;
}

sub dmy
{
    my ( $self, $sep ) = ( @_, '-' );
    return $self->_day . $sep. $self->_month . $sep . $self->_year;
}

sub hms
{
    my ( $self, $sep ) = ( @_, ':' );
    return $self->_hour . $sep. $self->_minute . $sep . $self->_second;
}
# don't want to override CORE::time()
*DateTime::Incomplete::time = \&hms;

sub iso8601 { join 'T', $_[0]->ymd('-'), $_[0]->hms(':') }
*datetime = \&iso8601;


# "strftime"

# Modified from DateTime::strftime %formats; many changes.
my %formats =
    ( 'a' => sub { $_[0]->has_day ? 
                   $_[0]->day_abbr :
                   $UNDEF_CHAR x 3 },
      'A' => sub { $_[0]->has_day ? 
                   $_[0]->day_name :
                   $UNDEF_CHAR x 5 },
      'b' => sub { $_[0]->has_month ? 
                   $_[0]->month_abbr :
                   $UNDEF_CHAR x 3 },
      'B' => sub { $_[0]->has_month ? 
                   $_[0]->month_name :
                   $UNDEF_CHAR x 5 },
      'c' => sub { $_[0]->has_locale ?
                   $_[0]->strftime( $_[0]->locale->default_datetime_format ) :
                   $_[0]->datetime }, 
      'C' => sub { $_[0]->has_year ?
                   int( $_[0]->year / 100 ) :
                   $UNDEF_CHAR x 2},
      'd' => sub { $_[0]->_day },
      'D' => sub { $_[0]->strftime( '%m/%d/%y' ) },
      'e' => sub { $_[0]->has_month ? 
                   sprintf( '%2d', $_[0]->day_of_month ) :
                   " $UNDEF_CHAR" },
      'F' => sub { $_[0]->ymd('-') },
      'g' => sub { substr( $_[0]->week_year, -2 ) },
      'G' => sub { $_[0]->week_year },
      'H' => sub { $_[0]->_hour },   
      'I' => sub { $_[0]->has_hour ? 
                   sprintf( '%02d', $_[0]->hour_12 ) :
                   $UNDEF_CHAR x 2 },
      'j' => sub { defined $_[0]->day_of_year ? 
                   $_[0]->day_of_year :
                   $UNDEF_CHAR x 3 },
      'k' => sub { $_[0]->_hour },   
      'l' => sub { $_[0]->has_hour ? 
                   sprintf( '%2d', $_[0]->hour_12 ) :
                   " $UNDEF_CHAR" },
      'm' => sub { $_[0]->_month },  
      'M' => sub { $_[0]->_minute }, 
      'n' => sub { "\n" }, # should this be OS-sensitive?
      'N' => sub { (shift)->_format_nanosecs( @_ ) },   
      'p' => sub { $_[0]->_format_am_pm },           
      'P' => sub { lc $_[0]->_format_am_pm },     
      'r' => sub { $_[0]->strftime( '%I:%M:%S %p' ) },
      'R' => sub { $_[0]->strftime( '%H:%M' ) },
      's' => sub { $_[0]->_format_epoch }, 
      'S' => sub { $_[0]->_second }, 
      't' => sub { "\t" },
      'T' => sub { $_[0]->strftime( '%H:%M:%S' ) },
      'u' => sub { $_[0]->day_of_week },
      # algorithm from Date::Format::wkyr
      'U' => sub { my $dow = $_[0]->day_of_week;
                   return $UNDEF_CHAR x 2 unless defined $dow;
                   $dow = 0 if $dow == 7; # convert to 0-6, Sun-Sat
                   my $doy = $_[0]->day_of_year - 1;
                   return int( ( $doy - $dow + 13 ) / 7 - 1 )
                 },
      'w' => sub { my $dow = $_[0]->day_of_week;
                   return $UNDEF_CHAR unless defined $dow;
                   return $dow % 7;
                 },
      'W' => sub { my $dow = $_[0]->day_of_week;
                   return $UNDEF_CHAR x 2 unless defined $dow;
                   my $doy = $_[0]->day_of_year - 1;
                   return int( ( $doy - $dow + 13 ) / 7 - 1 )
                 },
      'x' => sub { $_[0]->has_locale ? 
                   $_[0]->strftime( $_[0]->locale->default_date_format ) :
                   $_[0]->date },
      'X' => sub { $_[0]->has_locale ?
                   $_[0]->strftime( $_[0]->locale->default_time_format ) :
                   $_[0]->time },
      'y' => sub { $_[0]->has_year ?  
                   sprintf( '%02d', substr( $_[0]->year, -2 ) ) :
                   $UNDEF_CHAR x 2 },
      'Y' => sub { $_[0]->_year },    
      'z' => sub { defined $_[0]->time_zone ?
                   DateTime::TimeZone::offset_as_string( $_[0]->offset ) :
                   $UNDEF_CHAR x 5 },
      'Z' => sub { defined $_[0]->time_zone ?
                   $_[0]->time_zone_short_name :
                   $UNDEF_CHAR x 5 },    
      '%' => sub { '%' },
    );

$formats{h} = $formats{b};

sub _format_epoch {
    my $epoch;
    $epoch = $_[0]->epoch;
    return $UNDEF_CHAR x 6 unless defined $epoch;
    return $epoch;
}

sub _format_am_pm { 
    defined $_[0]->locale ?
    $_[0]->locale->am_pm( $_[0] ) :
    $UNDEF_CHAR x 2
}

sub _format_nanosecs
{
    my $self = shift;
    my $precision = shift || 9;

    return $UNDEF_CHAR x $precision unless defined $self->nanosecond;

    # rd_nanosecs can have a fractional separator
    my ( $ret, $frac ) = split /[.,]/, $self->nanosecond;
    $ret = sprintf "09d" => $ret;  # unless length( $ret ) == 9;
    $ret .= $frac if $frac;

    return substr( $ret, 0, $precision );
}

sub strftime
{
    my $self = shift;
    # make a copy or caller's scalars get munged
    my @formats = @_;

    my @r;
    foreach my $f (@formats)
    {
        $f =~ s/
                %\{(\w+)\}
               /
                if ( $self->can($1) ) 
                {
                    my $tmp = $self->$1();
                    defined $tmp ?
                            $tmp :
                            ( exists $FIELD_LENGTH{$1} ?
                                   $UNDEF_CHAR x $FIELD_LENGTH{$1} :
                                   $UNDEF_CHAR x 2 );
                }
               /sgex;

        # regex from Date::Format - thanks Graham!
       $f =~ s/
                %([%a-zA-Z])
               /
                $formats{$1} ? $formats{$1}->($self) : $1
               /sgex;

        # %3N
        $f =~ s/
                %(\d+)N
               /
                $formats{N}->($self, $1)
               /sgex;

        return $f unless wantarray;

        push @r, $f;
    }

    return @r;
}

# DATETIME::INCOMPLETE METHODS


sub is_undef 
{
    for ( values %{$_[0]->{has}} )
    {
        return 0 if defined $_;
    }
    return 1;
}


sub to_datetime
{
    my $self = shift;
    my %param = @_;
    $param{base} = $self->{base} if defined $self->{base} &&
                                  ! exists $param{base};
    my $result;
    if ( defined $param{base} && 
         UNIVERSAL::can( $param{base}, 'utc_rd_values' ) )
    {
        $result = $param{base}->clone;
    }
    else
    {
        $result = DateTime->today;
    }
    my @params;
    for my $key ( @FIELDS_SORTED )
    {
        my $value = $self->{has}{$key};
        next unless defined $value;
        if ( $key eq 'time_zone' )
        {
            $result->set_time_zone( $value );
            next;
        }        
        push @params, ( $key => $value );
    }
    $result->set( @params );
    return $result;
}

sub contains {
    my $self = shift;
    my $dt = shift;
    die "no datetime" unless defined $dt && 
                             UNIVERSAL::can( $dt, 'utc_rd_values' );

    if ( $self->has_time_zone ) 
    {
        $dt = $dt->clone;
        $dt->set_time_zone( $self->time_zone );
    }

    my ($key, $value);
    while (($key, $value) = each %{$self->{has}} ) {
        next unless defined $value;
        if ( $key eq 'time_zone' ||
             $key eq 'locale' )
        {
            # time_zone and locale are ignored.
            next;
        }        
        return 0 unless $dt->$key() == $value;
    }
    return 1;
}

# _fix_time_zone
# internal method used by next, previous
#
sub _fix_time_zone {
    my ($self, $base, $code) = @_;
    $base = $self->{base} if defined $self->{base} &&
                                  ! defined $base;
    die "no base datetime" unless defined $base && 
                                  UNIVERSAL::can( $base, 'utc_rd_values' );
    my $base_tz = $base->time_zone;
    my $result = $base->clone;
    $result->set_time_zone( $self->time_zone )
        if $self->has_time_zone;
    $result = $code->($self, $result);
    return undef 
        unless defined $result;
    $result->set_time_zone( $self->time_zone )
        if $self->has_time_zone;
    $result->set_time_zone( $base_tz );
    return $result;
}

sub next
{
    # returns 'next or equal'
    my $self = shift;
    my $base = shift;

    return $self->_fix_time_zone( $base, 
        sub {
            my ($self, $result) = @_;
            REDO: for (1..10) {
                # warn "next: self ".$self->datetime." base ".$result->datetime;

                my @fields = @FIELDS;
                my ( $field, $overflow, $bigger_field );
                while ( @fields ) 
                {
                    ( $field, undef ) = ( shift @fields, shift @fields );
                    if ( defined $self->$field() )
                    {
                        $overflow = ( $self->$field() < $result->$field() );
                        return undef if $overflow && $field eq $FIELDS[0];

                        if ( $self->$field() != $result->$field() )
                        {
                            eval { $result->set( $field => $self->$field() ) }; 
                            if ( $@ ) 
                            {
                                $result->set( @fields );
                                eval { $result->set( $field => $self->$field() ) };
                                if ( $@ )
                                {
                                    $overflow = 1;
                                }
                            }

                            if ( $overflow ) 
                            {
                                $result->add( $bigger_field . 's' => 1 );
                                next REDO; 
                            }
                            else
                            {
                                $result->set( @fields );
                            }
                        }
                    }
                    $bigger_field = $field;
                }
                return $result;
            }
            return undef;
        } );
}

sub previous
{
    # returns 'previous or equal'
    my $self = shift;
    my $base = shift;

    return $self->_fix_time_zone( $base, 
        sub {
            my ($self, $result) = @_;
            # warn "# previous: self ".$self->datetime." base ".$result->datetime." ".$result->time_zone->name;

            my ( $field, $value, $overflow, $bigger_field );

            REDO: for (1..10) {
                my @fields = @FIELDS;
                while ( @fields ) 
                {
                    ( $field, $value ) = ( shift @fields, shift @fields );
                    if ( defined $self->$field() )
                    {
                        $overflow = ( $self->$field() > $result->$field() );
                        return undef if $overflow && $field eq $FIELDS[0];

                        if ( $self->$field() != $result->$field() )
                        {
                            if ( $overflow )
                            {
                                $result->set( $field => $value, @fields );
                                $result->subtract( nanoseconds => 1 );
                                next REDO;
                            }
                            my $diff = $result->$field() - $self->$field() ;
                            $diff--;
                            $result->subtract( $field  . 's' => $diff );
                            $result->set( @fields );
                            $result->subtract( nanoseconds => 1 );
                            if ( $result->$field() != $self->$field() )
                            {
                                $result->set( @fields );
                                $result->subtract( nanoseconds => 1 );
                            } 
                        }
                    }
                    $bigger_field = $field;
                }
                return $result;
            }
            return undef;
        } );
}

sub closest
{
    # returns 'closest datetime'

    my $self = shift;
    my $base = shift;
    $base = $self->{base} if defined $self->{base} &&
                                  ! defined $base;
    die "no base datetime" unless defined $base &&
                                  UNIVERSAL::can( $base, 'utc_rd_values' );

    my $dt1 = $self->previous( $base );
    my $dt2 = $self->next( $base );

    return $dt1 unless defined $dt2;
    return $dt2 unless defined $dt1;

    my $delta = $base - $dt1;
    return $dt1 if ( $dt2 - $delta ) >= $base;
    return $dt2;
}

sub start
{
    my $self = shift;
    return undef unless $self->has_year;
    my $dt = $self->to_datetime;
    $dt->subtract( years => 1 );
    return $self->next( $dt );
}

sub end
{
    my $self = shift;
    return undef unless $self->has_year;
    my $dt = $self->to_datetime;
    $dt->add( years => 1 );
    my $end = $self->previous( $dt );
    $end->add( nanoseconds => 1 ) unless $self->has_nanosecond;
    return $end;
}

sub to_span
{
    my $self = shift;
    my $start = $self->start;
    my $end = $self->end;

    return DateTime::Set->empty_set->complement->span
        if ! $start && ! $end;

    my @start;
    @start = ( 'start', $start ) if $start;

    my @end;
    if ( $end )
    {
        if ( $self->has_nanosecond )
        {
            @end = ( 'end', $end ); 
        }
        else
        {
            @end = ( 'before', $end ); 
        }
    }

    return DateTime::Span->from_datetimes( @start, @end );
}

sub to_recurrence
{
    my $self = shift;
    my %param;

    my $freq = '';
    my $year;
    for ( qw( second minute hour day month year ) )
    {
        my $by = $_ . 's';  # months, hours
        if ( exists $self->{has}{$_} && defined $self->{has}{$_} )
        {
            if ( $_ eq 'year' ) 
            {
                $year = $self->$_();
                next;
            }
            $param{$by} = [ $self->$_() ];
            next;
        }
        $freq = $_ unless $freq;
        # TODO: use a hash
        $param{$by} = [ 1 .. 12 ] if $_ eq 'month';
        $param{$by} = [ 1 .. 31 ] if $_ eq 'day';
        $param{$by} = [ 0 .. 23 ] if $_ eq 'hour';
        $param{$by} = [ 0 .. 59 ] if $_ eq 'minute';
        $param{$by} = [ 0 .. 59 ] if $_ eq 'second';
    }
    if ( $freq eq '' )
    {
        # it is a single date
        my $dt = DateTime->new( %{$self->{has}} );
        return DateTime::Set->from_datetimes( dates => [ $dt ] );
    }

    # for ( keys %param ) { print STDERR " param $_ = @{$param{$_}} \n"; }

    my $r = DateTime::Event::Recurrence->yearly( %param );
    if ( defined $year ) {
        my $span = DateTime::Span->from_datetimes( 
                       start => DateTime->new( year => $year ),
                       before => DateTime->new( year => $year + 1 ) );
        $r = $r->intersection( $span );
    }
    return $r;
}

sub to_spanset
{
    my $self = shift;
    my @reset;
    for ( qw( second minute hour day month year ) )
    {
        if ( $self->has( $_ ) )
        {
            my %fields = @FIELDS;
            @reset = map { $_ => $fields{$_} } @reset;
            my $dti = $self->clone;
            $dti->set( @reset ) if @reset;

            return DateTime::SpanSet->from_set_and_duration (
                set => $dti->to_recurrence,
                $_ . 's' => 1,
            );
        }
        push @reset, $_;
    }
    return $self->to_span;
}

sub STORABLE_freeze
{
    my ( $self, $cloning ) = @_;
    return if $cloning;

    my @data;
    for my $key ( @FIELDS_SORTED )
    {
        next unless defined $self->{has}{$key};

        if ( $key eq 'locale' ) 
        { 
            push @data,  "locale:" . $self->{has}{locale}->id; 
        }
        elsif ( $key eq 'time_zone' ) 
        { 
            push @data, "tz:" . $self->{has}{time_zone}->name; 
        }
        else 
        { 
            push @data, "$key:" . $self->{has}{$key}; 
        }
    }
    return join( '|', @data ), [$self->base];
}

sub STORABLE_thaw
{
    my ( $self, $cloning, $data, $base ) = @_;
    my %data = map { split /:/ } split /\|/, $data;
    my $locale = delete $data{locale};
    my $tz =     delete $data{tz};
    $self->{has} = \%data;
    $self->set_time_zone( $tz );
    $self->set( locale => $locale );
    $self->{base} = $base->[0];
    return $self;
}

1;

__END__

=head1 NAME

DateTime::Incomplete - An incomplete datetime, like January 5

=head1 SYNOPSIS

  my $dti = DateTime::Incomplete->new( year => 2003 );
  # 2003-xx-xx
  $dti->set( month => 12 );
  # 2003-12-xx
  $dt = $dti->to_datetime( base => DateTime->now );
  # 2003-12-19T16:54:33


=head1 DESCRIPTION

DateTime::Incomplete is a class for representing partial dates and
times.

These are actually encountered relatively frequently.  For example, a
birthday is commonly given as a month and day, without a year.

=head1 ERROR HANDLING

Constructor and mutator methods (such as C<new> and C<set>) will die
if there is an attempt to set the datetime to an invalid value.

Invalid values are detected by setting the appropriate fields of a
"base" datetime object. See the C<set_base> method.

Accessor methods (such as C<day()>) will return either a value or
C<undef>, but will never die.

=head1 THE "BASE" DATETIME

A C<DateTime::Incomplete> object can have a "base" C<DateTime.pm>
object.  This object is used as a default datetime in the
C<to_datetime()> method, and it also used to validate inputs to the
C<set()> method.

The base object must use the year/month/day system.  Most calendars
use this system including Gregorian (C<DateTime>) and Julian.  Note
that this module has not been well tested with base objects from
classes other than C<DateTime.pm> class.

By default, newly created C<DateTime::Incomplete> objects have no
base.

=head1 DATETIME-LIKE METHODS

Most methods provided by this class are designed to emulate the
behavior of C<DateTime.pm> whenever possible.

=over

=item * new()

Creates a new incomplete date:

  my $dti = DateTime::Incomplete->new( year => 2003 );
  # 2003-xx-xx

This class method accepts parameters for each date and time component:
"year", "month", "day", "hour", "minute", "second", "nanosecond".
Additionally, it accepts "time_zone", "locale", and "base" parameters.

Any parameters not given default to C<undef>.

Calling the C<new()> method without parameters creates a completely
undefined datetime:

  my $dti = DateTime::Incomplete->new();

=item * from_day_of_year( ... )

This constructor takes the same arguments as can be given to the
C<new()> method, except that it does not accept a "month" or "day"
argument.  Instead, it requires both "year" and "day_of_year".  The
day of year must be between 1 and 366, and 366 is only allowed for
leap years.

It creates a C<DateTime::Incomplete> object with all date fields
defined, but with the time fields (hour, minute, etc.) set to undef.

=item * from_object( object => $object, ... )

This class method can be used to construct a new
C<DateTime::Incomplete> object from any object that implements the
C<utc_rd_values()> method.  All C<DateTime::Calendar> modules must
implement this method in order to provide cross-calendar
compatibility.  This method accepts a "locale" parameter.

If the object passed to this method has a C<time_zone()> method, that
is used to set the time zone.  Otherwise UTC is used.

It creates a C<DateTime::Incomplete> object with all fields defined.

=item * from_epoch( ... )

This class method can be used to construct a new
C<DateTime::Incomplete> object from an epoch time instead of
components.  Just as with the C<new()> method, it accepts "time_zone"
and "locale" parameters.

If the epoch value is not an integer, the part after the decimal will
be converted to nanoseconds.  This is done in order to be compatible
with C<Time::HiRes>.

It creates a C<DateTime::Incomplete> object with all fields defined.

=item * now( ... )

This class method is equivalent to C<< DateTime->now >>.

It creates a new C<DateTime::Incomplete> object with all fields
defined.

=item * today( ... )

This class method is equivalent to C<now()>, but it leaves hour,
minute, second and nanosecond undefined.

=item * clone

Creates a new object with the same information as the object this
method is called on.

=back

=head2 "Get" Methods

=over 4

=item * year

=item * month

=item * day

=item * hour

=item * minute

=item * second

=item * nanosecond

=item * time_zone

=item * locale

These methods returns the field value for the object, or C<undef>.

These values can also be accessed using the same alias methods
available in C<DateTime.pm>, such as C<mon()>, C<mday()>, etc.

=item * has_year

=item * has_month

=item * has_day

=item * has_hour

=item * has_minute

=item * has_second

=item * has_nanosecond

=item * has_time_zone

=item * has_locale

=item * has_date

=item * has_time

Returns a boolean value indicating whether the corresponding component is
defined.

C<has_date> tests for year, month, and day.

C<has_time> tests for hour, minute, and second.

=item * has

    $has_date = $dti->has( 'year', 'month', 'day' );

Returns a boolean value indicating whether all fields in the argument list are defined.

=item * defined_fields

    @fields = $dti->defined_fields;   # list of field names

Returns a list containing the names of the fields that are defined.

The list order is: year, month, day, hour, minute, second, nanosecond,
time_zone, locale.

=item * datetime, ymd, date, hms, time, iso8601, mdy, dmy

These are equivalent to DateTime stringification methods with the same
name, except that the undefined fields are replaced by 'xx' or 'xxxx'
as appropriate.

=item * epoch

=item * hires_epoch

=item * is_dst

=item * utc_rd_values

=item * utc_rd_as_seconds

    my $epoch = $dti->epoch( base => $dt );

These methods are equivalent to the C<DateTime> methods with the same
name.

They all accept a "base" argument to use in order to calculate the
method's return values.

If no "base" argument is given, then C<today> is used.

=item * is_finite, is_infinite

Incomplete dates are always "finite".

=item * strftime( $format, ... )

This method implements functionality similar to the C<strftime()>
method in C.  However, if given multiple format strings, then it will
return multiple scalars, one for each format string.

See the "strftime Specifiers" section in the C<DateTime.pm>
documentation for a list of all possible format specifiers.

Undefined fields are replaced by 'xx' or 'xxxx' as appropriate.

The specification C<%s> (epoch) is calculated using C<today> as the base date,
unless the object has a base datetime set.

=back

=head3 Computed Values

All other accessors, such as C<day_of_week()>, or C<week_year()> are
computed from the base values for a datetime.  When these methods are
called, they return the requested information if there is enough data
to compute them, otherwise they return C<undef>

=head3 Unimplemented Methods

The following C<DateTime.pm> methods are not implemented in
C<DateTime::Incomplete>, though some of them may be implemented in
future versions:

=over 4

=item * add_duration

=item * add

=item * subtract_duration

=item * subtract

=item * subtract_datetime

=item * subtract_datetime_absolute

=item * delta_md

=item * delta_days

=item * delta_ms

=item * compare

=item * compare_ignore_floating

=item * DefaultLanguage

=back

=head2 "Set" Methods

=over 4

=item * set

Use this to set or undefine a datetime field:

  $dti->set( month => 12 );
  $dti->set( day => 24 );
  $dti->set( day => undef );

This method takes the same arguments as the C<set()> method in
C<DateTime.pm>, but it can accept C<undef> for any value.

=item * set_time_zone

This method accepts either a time zone object or a string that can be
passed as the "name" parameter to C<< DateTime::TimeZone->new() >>.

Unlike with C<DateTime.pm>, if the new time zone's offset is different
from the previous time zone, no local time adjustment is made.

You can remove time zone information by calling this method with the
value C<undef>.

=item * truncate( to => ... )

This method allows you to reset some of the local time components in
the object to their "zero" values.  The "to" parameter is used to
specify which values to truncate, and it may be one of "year",
"month", "day", "hour", "minute", or "second".  For example, if
"month" is specified, then the local day becomes 1, and the hour,
minute, and second all become 0.

Note that the "to" parameter B<cannot be "week">.

=back

=head1 "DATETIME::INCOMPLETE" METHODS

C<DateTime::Incomplete> objects also have a number of methods unique
to this class.

=over 4

=item * base

Returns the base datetime value, or C<undef> if the object has none.

=item * has_base

Returns a boolean value indicating whether or not the object has a
base datetime set.

=item * is_undef

Returns true if the datetime is completely undefined.

=item * can_be_datetime

Returns true if the datetime has enough information to be converted to
a proper DateTime object.

The year field must be valid, followed by a sequence of valid fields.

Examples:

  Can be datetime:
  2003-xx-xxTxx:xx:xx
  2003-10-xxTxx:xx:xx
  2003-10-13Txx:xx:xx

  Can not be datetime:
  2003-10-13Txx:xx:30
  xxxx-10-13Txx:xx:30

=cut

#=item * become_datetime
#
#Returns a C<DateTime> object.
#
#Returns C<undef> if the year value is not set.
#
#This method may C<die> if the parameters are not valid 
#in the call to  C<DateTime->new>. 

=item * set_base

Sets the base datetime object for the C<DateTime::Incomplete> object.

The default value for "base" is C<undef>, which means no validation is
made on input.

=item * to_datetime

This method takes an optional "base" parameter and returns a
"complete" datetime.

  $dt = $dti->to_datetime( base => DateTime->now );

  $dti->set_base( DateTime->now );
  $dt = $dti->to_datetime;

The resulting datetime can be either before of after the given base
datetime. No adjustments are made, besides setting the missing fields.

This method will use C<today> if the object has no base datetime set and none
is given as an argument.

This method may die if it results in a datetime that doesn't
actually exist, such as February 30, for example.

The fields in the resulting datetime are set in this order: locale,
time_zone, nanosecond, second, minute, hour, day, month, year.

=item * to_recurrence

This method generates the set of all possible datetimes that fit into
an incomplete datetime definition.

  $dti = DateTime::Incomplete->new( month => 12, day => 24 );
  $dtset1 = $dti->to_recurrence;
  # Christmas recurrence, with _seconds_ resolution

  $dti->truncate( to => 'day' );
  $dtset2 = $dti->to_recurrence;
  # Christmas recurrence, with days resolution (hour/min/sec = 00:00:00)

Those recurrences are C<DateTime::Set> objects:

  $dt_next_xmas = $dti->to_recurrence->next( DateTime->today );

Incomplete dates that have the year defined will generate finite sets.
This kind of set can take a lot of resources (RAM and CPU).  The
following incomplete datetime would generate the set of I<all seconds>
in 2003:

  2003-xx-xxTxx:xx:xx

Recurrences are generated with up to 1 second resolution.  The
C<nanosecond> value is ignored.

=item * to_spanset

This method generates the set of all possible spans that fit into
an incomplete datetime definition.

  $dti = DateTime::Incomplete->new( month => 12, day => 24 );
  $dtset1 = $dti->to_spanset;
  # Christmas recurrence, from xxxx-12-24T00:00:00 
  #                         to xxxx-12-25T00:00:00

=item * start

=item * end

=item * to_span

These methods view an incomplete datetime as a "time span".

For example, the incomplete datetime C<2003-xx-xxTxx:xx:xx> starts
in C<2003-01-01T00:00:00> and ends in C<2004-01-01T00:00:00>.

The C<to_span> method returns a C<DateTime::Span> object.

An incomplete datetime without an year spans "forever". 
Start and end datetimes are C<undef>.

=item * contains

Returns a true value if the incomplete datetime range I<contains> a
given datetime value.

For example:

  2003-xx-xx contains 2003-12-24
  2003-xx-xx does not contain 1999-12-14

=item * previous / next / closest

  $dt2 = $dti->next( $dt );

The C<next()> returns the first complete date I<after or equal> to the
given datetime.

The C<previous()> returns the first complete date I<before or equal>
to the given datetime.

The C<closest()> returns the closest complete date (previous or next)
to the given datetime.

All of these methods return C<undef> if there is no matching complete
datetime.

If no datetime is given, these methods use the "base" datetime.

Note: The definition of C<previous()> and C<next()> is different from
the methods of the same name in the C<DateTime::Set> class.

The datetimes are generated with 1 nanosecond precision. The last
"time" value of a given day is 23:59:59.999999999 (for non leapsecond
days).

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

=head1 AUTHORS

Flavio S. Glock <fglock[at]cpan.org>

With
Ben Bennett <fiji[at]ayup.limey.net>,
Claus Farber <claus[at]xn--frber-gra.muc.de>,
Dave Rolsky <autarch[at]urth.org>,
Eugene Van Der Pijll <pijll[at]gmx.net>,
Rick Measham <rick[at]isite.net.au>,
and the DateTime team.

=head1 COPYRIGHT

Copyright (c) 2003 Flavio S. Glock.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

