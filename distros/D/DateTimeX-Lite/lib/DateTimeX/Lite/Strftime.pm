package DateTimeX::Lite;

{
    my %strftime_patterns =
        ( 'a' => sub { $_[0]->day_abbr },
          'A' => sub { $_[0]->day_name },
          'b' => sub { $_[0]->month_abbr },
          'B' => sub { $_[0]->month_name },
          'c' => sub { $_[0]->format_cldr( $_[0]->{locale}->datetime_format_default() ) },
          'C' => sub { int( $_[0]->year / 100 ) },
          'd' => sub { sprintf( '%02d', $_[0]->day ) },
          'D' => sub { $_[0]->strftime( '%m/%d/%y' ) },
          'e' => sub { sprintf( '%2d', $_[0]->day ) },
          'F' => sub { $_[0]->ymd('-') },
          'g' => sub { substr( $_[0]->week_year, -2 ) },
          'G' => sub { $_[0]->week_year },
          'H' => sub { sprintf( '%02d', $_[0]->hour ) },
          'I' => sub { sprintf( '%02d', $_[0]->hour_12 ) },
          'j' => sub { $_[0]->day_of_year },
          'k' => sub { sprintf( '%2d', $_[0]->hour ) },
          'l' => sub { sprintf( '%2d', $_[0]->hour_12 ) },
          'm' => sub { sprintf( '%02d', $_[0]->month ) },
          'M' => sub { sprintf( '%02d', $_[0]->minute ) },
          'n' => sub { "\n" }, # should this be OS-sensitive?
          'N' => \&_format_nanosecs,
          'p' => sub { $_[0]->am_or_pm() },
          'P' => sub { lc $_[0]->am_or_pm() },
          'r' => sub { $_[0]->strftime( '%I:%M:%S %p' ) },
          'R' => sub { $_[0]->strftime( '%H:%M' ) },
          's' => sub { $_[0]->epoch },
          'S' => sub { sprintf( '%02d', $_[0]->second ) },
          't' => sub { "\t" },
          'T' => sub { $_[0]->strftime( '%H:%M:%S' ) },
          'u' => sub { $_[0]->day_of_week },
          # algorithm from Date::Format::wkyr
          'U' => sub { my $dow = $_[0]->day_of_week;
                       $dow = 0 if $dow == 7; # convert to 0-6, Sun-Sat
                       my $doy = $_[0]->day_of_year - 1;
                       return sprintf( '%02d', int( ( $doy - $dow + 13 ) / 7 - 1 ) )
                   },
          'V' => sub { sprintf( '%02d', $_[0]->week_number ) },
          'w' => sub { my $dow = $_[0]->day_of_week;
                       return $dow % 7;
                   },
          'W' => sub { my $dow = $_[0]->day_of_week;
                       my $doy = $_[0]->day_of_year - 1;
                       return sprintf( '%02d', int( ( $doy - $dow + 13 ) / 7 - 1 ) )
                   },
          'x' => sub { $_[0]->format_cldr( $_[0]->{locale}->date_format_default() ) },
          'X' => sub { $_[0]->format_cldr( $_[0]->{locale}->time_format_default() ) },
          'y' => sub { sprintf( '%02d', substr( $_[0]->year, -2 ) ) },
          'Y' => sub { return $_[0]->year },
          'z' => sub { DateTimeX::Lite::TimeZone->offset_as_string( $_[0]->offset ) },
          'Z' => sub { $_[0]->{tz}->short_name_for_datetime( $_[0] ) },
          '%' => sub { '%' },
        );

    $strftime_patterns{h} = $strftime_patterns{b};

    sub strftime
    {
        my $self = shift;
        # make a copy or caller's scalars get munged
        my @patterns = @_;

        my @r;
        foreach my $p (@patterns)
        {
            $p =~ s/
                    (?:
                      %{(\w+)}         # method name like %{day_name}
                      |
                      %([%a-zA-Z])     # single character specifier like %d
                      |
                      %(\d+)N          # special case for %N
                    )
                   /
                    ( $1
                      ? ( $self->can($1) ? $self->$1() : "\%{$1}" )
                      : $2
                      ? ( $strftime_patterns{$2} ? $strftime_patterns{$2}->($self) : "\%$2" )
                      : $3
                      ? $strftime_patterns{N}->($self, $3)
                      : ''  # this won't happen
                    )
                   /sgex;

            return $p unless wantarray;

            push @r, $p;
        }

        return @r;
    }
}

{
    # It's an array because the order in which the regexes are checked
    # is important. These patterns are similar to the ones Java uses,
    # but not quite the same. See
    # http://www.unicode.org/reports/tr35/tr35-9.html#Date_Format_Patterns.
    my @patterns =
        ( qr/GGGGG/  => sub { $_[0]->{locale}->era_narrow->[ $_[0]->_era_index() ] },
          qr/GGGG/   => 'era_name',
          qr/G{1,3}/ => 'era_abbr',

          qr/(y{3,5})/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->year() ) },
          # yy is a weird special case, where it must be exactly 2 digits
          qr/yy/       => sub { my $year = $_[0]->year();
                                $year = substr( $year, -2, 2 ) if length $year > 2;
                                $_[0]->_zero_padded_number( 'yy', $year ) },
          qr/y/        => sub { $_[0]->year() },
          qr/(u+)/     => sub { $_[0]->_zero_padded_number( $1, $_[0]->year() ) },
          qr/(Y+)/     => sub { $_[0]->_zero_padded_number( $1, $_[0]->week_year() ) },

          qr/QQQQ/  => 'quarter_name',
          qr/QQQ/   => 'quarter_abbr',
          qr/(QQ?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->quarter() ) },

          qr/MMMMM/ => sub { $_[0]->{locale}->month_format_narrow->[ $_[0]->month() - 1 ] },
          qr/MMMM/  => 'month_name',
          qr/MMM/   => 'month_abbr',
          qr/(MM?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->month() ) },

          qr/LLLLL/ => sub { $_[0]->{locale}->month_stand_alone_narrow->[ $_[0]->month() - 1] },
          qr/LLLL/  => sub { $_[0]->{locale}->month_stand_alone_wide->[ $_[0]->month() - 1 ] },
          qr/LLL/   => sub { $_[0]->{locale}->month_stand_alone_abbreviated->[ $_[0]->month() - 1] },
          qr/(LL?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->month() ) },

          qr/(ww?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->week_number() ) },
          qr/W/     => 'week_of_month',

          qr/(dd?)/    => sub { $_[0]->_zero_padded_number( $1, $_[0]->day() ) },
          qr/(D{1,3})/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->day_of_year() ) },

          qr/F/    => 'weekday_of_month',
          qr/(g+)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->mjd() ) },

          qr/EEEEE/  => sub { $_[0]->{locale}->day_format_narrow->[ $_[0]->day_of_week() - 1] },
          qr/EEEE/   => 'day_name',
          qr/E{1,3}/ => 'day_abbr',

          qr/eeeee/ => sub { $_[0]->{locale}->day_format_narrow->[ $_[0]->day_of_week() - 1] },
          qr/eeee/  => 'day_name',
          qr/eee/   => 'day_abbr',
          qr/(ee?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->local_day_of_week() ) },

          qr/ccccc/ => sub { $_[0]->{locale}->day_stand_alone_narrow->[ $_[0]->day_of_week() - 1] },
          qr/cccc/  => sub { $_[0]->{locale}->day_stand_alone_wide->[ $_[0]->day_of_week() - 1] },
          qr/ccc/   => sub { $_[0]->{locale}->day_stand_alone_abbreviated->[ $_[0]->day_of_week() - 1] },
          qr/(cc?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->local_day_of_week() ) },

          qr/a/ => 'am_or_pm',

          qr/(hh?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->hour_12() ) },
          qr/(HH?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->hour() ) },
          qr/(KK?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->hour() % 12 ) },
          qr/(kk?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->hour_1() ) },
          qr/(jj?)/ => sub { my $h = $_[0]->{locale}->prefers_24_hour_time() ? $_[0]->hour_12() : $_[0]->hour();
                             $_[0]->_zero_padded_number( $1, $h ) },

          qr/(mm?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->minute() ) },

          qr/(ss?)/ => sub { $_[0]->_zero_padded_number( $1, $_[0]->second() ) },
          # I'm not sure this is what is wanted (notably the trailing
          # and leading zeros it can produce), but once again the LDML
          # spec is not all that clear.
          qr/(S+)/  => sub { my $l = length $1;
                             my $val = sprintf( "%.${l}f", $_[0]->fractional_second() - $_[0]->second() );
                             $val =~ s/^0\.//;
                             $val || 0 },
          qr/A+/    => sub { ( $_[0]->{local_rd_secs} * 1000 ) + $_[0]->millisecond() },

          qr/zzzz/   => sub { $_[0]->time_zone_long_name() },
          qr/z{1,3}/ => sub { $_[0]->time_zone_short_name() },
          qr/ZZZZ/   => sub { $_[0]->time_zone_short_name()
                              . DateTimeX::Lite::TimeZone->offset_as_string( $_[0]->offset() ) },
          qr/Z{1,3}/ => sub { DateTimeX::Lite::TimeZone->offset_as_string( $_[0]->offset() ) },
          qr/vvvv/   => sub { $_[0]->time_zone_long_name() },
          qr/v{1,3}/ => sub { $_[0]->time_zone_short_name() },
          qr/VVVV/   => sub { $_[0]->time_zone_long_name() },
          qr/V{1,3}/ => sub { $_[0]->time_zone_short_name() },
    );

    sub _zero_padded_number
    {
        my $self = shift;
        my $size = length shift;
        my $val  = shift;

        return sprintf( "%0${size}d", $val );
    }

    sub _space_padded_string
    {
        my $self = shift;
        my $size = length shift;
        my $val  = shift;

        return sprintf( "% ${size}s", $val );
    }

    sub format_cldr
    {
        my $self = shift;
        # make a copy or caller's scalars get munged
        my @patterns = @_;

        my @r;
        foreach my $p (@patterns)
        {
            $p =~ s/\G
                    (?:
                      '((?:[^']|'')*)' # quote escaped bit of text
                                       # it needs to end with one
                                       # quote not followed by
                                       # another
                      |
                      (([a-zA-Z])\3*)     # could be a pattern
                      |
                      (.)                 # anything else
                    )
                   /
                    defined $1
                    ? $1
                    : defined $2
                    ? $self->_cldr_pattern($2)
                    : defined $4
                    ? $4
                    : undef # should never get here
                   /sgex;

            $p =~ s/\'\'/\'/g;

            return $p unless wantarray;

            push @r, $p;
        }

        return @r;
    }

    sub _cldr_pattern
    {
        my $self    = shift;
        my $pattern = shift;

        for ( my $i = 0; $i < @patterns; $i +=2 )
        {
            if ( $pattern =~ /$patterns[$i]/ )
            {
                my $sub = $patterns[ $i + 1 ];

                return $self->$sub();
            }
        }

        return $pattern;
    }
}

sub _format_nanosecs
{
    my $self = shift;
    my $precision = shift;

    my $ret = sprintf( "%09d", $self->{rd_nanosecs} );
    return $ret unless $precision;   # default = 9 digits

    # rd_nanosecs might contain a fractional separator
    my ( $int, $frac ) = split /[.,]/, $self->{rd_nanosecs};
    $ret .= $frac if $frac;

    return substr( $ret, 0, $precision );
}

1;