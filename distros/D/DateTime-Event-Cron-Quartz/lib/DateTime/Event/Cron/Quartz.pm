package DateTime::Event::Cron::Quartz;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.05';

use base qw/Class::Accessor/;

use DateTime;
use Readonly;

use Exception::Class (
    'UnknownException',
    'ParseException'                => { fields => ['line'] },
    'IllegalArgumentException'      => {},
    'UnsupportedOperationException' => {}
);

use DateTime::Event::Cron::Quartz::TreeSet;
use DateTime::Event::Cron::Quartz::ValueSet;

Readonly my $MONDAY    => 0;
Readonly my $TUESDAY   => 1;
Readonly my $WEDNESDAY => 2;
Readonly my $THURSDAY  => 3;
Readonly my $FRIDAY    => 4;
Readonly my $SATURDAY  => 5;
Readonly my $SUNDAY    => 6;

Readonly::Scalar my $SECOND       => 0;
Readonly::Scalar my $MINUTE       => 1;
Readonly::Scalar my $HOUR         => 2;
Readonly::Scalar my $DAY_OF_MONTH => 3;
Readonly::Scalar my $MONTH        => 4;
Readonly::Scalar my $DAY_OF_WEEK  => 5;
Readonly::Scalar my $YEAR         => 6;
Readonly::Scalar my $ALL_SPEC_INT => 99;
Readonly::Scalar my $NO_SPEC_INT  => 98;
Readonly::Scalar my $ALL_SPEC     => $ALL_SPEC_INT;
Readonly::Scalar my $NO_SPEC      => $NO_SPEC_INT;

Readonly::Scalar my $MONTH_MAP => {
    JAN => 1,
    FEB => 2,
    MAR => 3,
    APR => 4,
    MAY => 5,
    JUN => 6,
    JUL => 7,
    AUG => 8,
    SEP => 9,
    OCT => 10,
    NOV => 11,
    DEC => 12
};

Readonly::Scalar my $DAY_MAP => {
    MON => 1,
    TUE => 2,
    WED => 3,
    THU => 4,
    FRI => 5,
    SAT => 6,
    SUN => 7
};

__PACKAGE__->mk_accessors(
    qw/
      cron_expression
      time_zone
      seconds
      minutes
      hours
      days_of_month
      months
      days_of_week
      years

      lastday_of_week
      nthday_of_week
      lastday_of_month
      nearest_weekday
      expression_parsed
      /
);

sub new {
    my ( $class, $cron_expression ) = @_;

    if ( !defined $cron_expression ) {
        IllegalArgumentException->throw(
            error => 'cron expression cannot be undef' );
    }

    my $this = bless {}, $class;

    # initialize fields values
    $this->lastday_of_week(0);
    $this->nthday_of_week(0);
    $this->lastday_of_month(0);
    $this->nearest_weekday(0);
    $this->expression_parsed(0);

    $this->cron_expression( uc $cron_expression );

    $this->build_expression( $this->cron_expression );

    return $this;
}

sub is_satisfied_by {
    my ( $this, $date ) = @_;

    my $time_after = $this->get_time_after($date);

    return ( ( defined $time_after )
          && ( DateTime->compare( $time_after, $date ) == 0 ) );
}

sub get_next_valid_time_after {
    my ( $this, $date ) = @_;

    return $this->get_time_after($date);
}

sub get_next_invalid_time_after {
    my ( $this, $last_date ) = @_;

    my $difference = 1;

    my $new_date = undef;

    # keep getting the next included time until it's farther than one second
    # apart. At that point, lastDate is the last valid fire time. We return
    # the second immediately following it.
    while ( $difference == 1 ) {
        $new_date = $this->get_time_after($last_date);

        $difference = $new_date->subtract_datetime_absolute($last_date);

        if ( $difference == 1 ) {
            $last_date = $new_date;
        }
    }

    return $last_date->clone()->add( second => 1 );
}

sub is_valid_expression {
    my ( $this, $cron_expression ) = @_;

    my $res = eval { $this->new($cron_expression); };

    if ( my $e = Exception::Class->caught('ParseException') ) {
        return 0;
    }

    return 1;
}

#//////////////////////////////////////////////////////////////////////////
#
# Expression Parsing Functions
#
#//////////////////////////////////////////////////////////////////////////

sub build_expression {
    my ( $this, $expression ) = @_;

    my $expression_parsed = 1;

    my $ret = eval {

        if ( !defined $this->seconds ) {
            $this->seconds( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->minutes ) {
            $this->minutes( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->hours ) {
            $this->hours( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->days_of_month ) {
            $this->days_of_month( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->months ) {
            $this->months( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->days_of_week ) {
            $this->days_of_week( DateTime::Event::Cron::Quartz::TreeSet->new );
        }
        if ( !defined $this->years ) {
            $this->years( DateTime::Event::Cron::Quartz::TreeSet->new );
        }

        my $expr_on = $SECOND;

        my @exprs_tok = split /\s+/sxm, $expression;

        foreach my $expr (@exprs_tok) {

            # not interested in after expression text
            last if $expr_on > $YEAR;

            # throw an exception if L is used with other days of the month
            if (   $expr_on == $DAY_OF_MONTH
                && index( $expr, 'L' ) != -1
                && length($expr) > 1
                && index( $expr, q/,/ ) >= 0 )
            {

                ParseException->throw(
                    error =>
                        q/Support for specifying 'L' and 'LW' with other days of the month is not implemented/,
                    line => -1
                );
            }

            # throw an exception if L is used with other days of the week
            if (   $expr_on == $DAY_OF_WEEK
                && index( $expr, 'L' ) != -1
                && length($expr) > 1
                && index( $expr, q/,/ ) >= 0 )
            {

                ParseException->throw(
                    error =>
                        q/Support for specifying 'L' with other days of the week is not implemented/,
                    line => -1
                );
            }

            my @v_tok = split /,/sxm, $expr;
            foreach my $v (@v_tok) {
                $this->store_expression_vals( 0, $v, $expr_on );
            }

            $expr_on++;
        }

        if ( $expr_on <= $DAY_OF_WEEK ) {
            ParseException->throw(
                error => q/Unexpected end of expression/,
                line  => ( length $expression )
            );
        }

        if ( $expr_on <= $YEAR ) {
            $this->store_expression_vals( 0, q/*/, $YEAR );
        }

        #TreeSet
        my $dow = $this->get_set($DAY_OF_WEEK);

        #TreeSet
        my $dom = $this->get_set($DAY_OF_MONTH);

        # Copying the logic from the UnsupportedOperationException below
        my $day_of_m_spec = !$dom->contains($NO_SPEC);
        my $day_of_w_spec = !$dow->contains($NO_SPEC);

        if ( $day_of_m_spec && !$day_of_w_spec ) {

            # skip
        }
        elsif ( $day_of_w_spec && !$day_of_m_spec ) {

            # skip
        }
        else {
            ParseException->throw(
                error => q/Support for specifying both a day-of-week /
                  . q/AND a day-of-month parameter is not implemented./,
                line => 0
            );
        }
    };

    if ( my $pe = Exception::Class->caught('ParseException') ) {
        $pe->rethrow;
    }
    elsif ( my $e = Exception::Class->caught() ) {
        ParseException->throw(
            error => q/Illegal cron expression format (/ . $e->error . q/)/,
            line  => 0
        );
    }

    return;
}

sub store_expression_vals {
    my ( $this, $pos, $s, $type ) = @_;

    my $incr = 0;
    my $i = $this->skip_white_space( $pos, $s );
    if ( $i >= ( length $s ) ) {
        return $i;
    }

    my $c = ( substr $s, $i, 1 );
    if (   ( ( ord $c ) >= ( ord 'A' ) )
        && ( ( ord $c ) <= ( ord 'Z' ) )
        && ( !( $s eq 'L' ) )
        && ( !( $s eq 'LW' ) ) )
    {
        my $sub  = ( substr $s, $i, $i + 3 );
        my $sval = -1;
        my $eval = -1;
        if ( $type == $MONTH ) {
            $sval = $this->get_month_number($sub);
            if ( $sval <= 0 ) {
                ParseException->throw(
                    error => q/Invalid Month value: '/ . $sub . q/'/,
                    line  => $i
                );
            }
            if ( ( length $s ) > $i + 3 ) {
                $c = ( substr $s, $i + 3, 1 );
                if ( $c eq q/-/ ) {
                    $i += ( 3 + 1 );
                    $sub = ( substr $s, $i, $i + 3 );
                    $eval = $this->get_month_number($sub);
                    if ( $eval <= 0 ) {
                        ParseException->throw(
                            error => q/Invalid Month value: '/ . $sub . q/'/,
                            line  => $i
                        );
                    }
                }
            }
        }
        elsif ( $type == $DAY_OF_WEEK ) {
            $sval = $this->get_day_of_week_number($sub);
            if ( $sval < 0 ) {
                ParseException->throw(
                    error => q/Invalid Day-of-Week value: '/ . $sub . q/'/,
                    line  => $i
                );
            }
            if ( length $s > $i + 3 ) {
                $c = substr $s, $i + 3, 1;
                if ( $c eq q/-/ ) {
                    $i += ( 3 + 1 );
                    $sub = ( substr $s, $i, $i + 3 );
                    $eval = $this->get_day_of_week_number($sub);
                    if ( $eval < 0 ) {
                        ParseException->throw(
                            error => q/Invalid Day-of-Week value: '/ 
                              . $sub . q/'/,
                            line => $i
                        );
                    }
                }
                elsif ( $c eq q/#/ ) {
                    my $ret = eval {
                        $i += ( 3 + 1 );
                        $this->nthday_of_week( int substr $s, $i );
                        if (   $this->nthday_of_week < 1
                            || $this->nthday_of_week > 5 )
                        {
                            Exception::Class->throw();
                        }
                    };

                    if ( my $e = Exception::Class->caught() ) {
                        ParseException->throw(
                            error =>
                                q/A numeric value between 1 and 5 must follow the '#' option/,
                            line => $i
                        );
                    }
                }
                elsif ( $c == 'L' ) {
                    $this->lastday_of_week(1);
                    $i++;
                }
            }

        }
        else {
            ParseException->throw(
                error => q/Illegal characters for this position: '/ 
                  . $sub . q/'/,
                line => $i
            );
        }
        if ( $eval != -1 ) {
            $incr = 1;
        }
        $this->add_to_set( $sval, $eval, $incr, $type );
        return ( $i + 3 );
    }

    if ( $c eq '?' ) {
        $i++;
        if (   ( $i + 1 ) < length($s)
            && ( substr( $s, $i, 1 ) ne ' ' && substr( $s, $i + 1, 1 ) ne "\t" )
          )
        {
            ParseException->throw(
                error => q/Illegal character after '?': / . substr( $s, $i, 1 ),
                line  => $i
            );
        }
        if ( $type != $DAY_OF_WEEK && $type != $DAY_OF_MONTH ) {
            ParseException->throw(
                error =>
                  q/'?' can only be specfied for Day-of-Month or Day-of-Week./,
                line => $i
            );
        }
        if ( $type == $DAY_OF_WEEK && !$this->lastday_of_month ) {
            my $val = int( $this->days_of_month->last_item() );
            if ( $val == $NO_SPEC_INT ) {
                ParseException->throw(
                    error =>
                        q/'?' can only be specfied for Day-of-Month -OR- Day-of-Week./,
                    line => $i
                );
            }
        }

        $this->add_to_set( $NO_SPEC_INT, -1, 0, $type );
        return $i;
    }

    if ( $c eq '*' || $c eq '/' ) {
        if ( $c eq '*' && ( $i + 1 ) >= length($s) ) {
            $this->add_to_set( $ALL_SPEC_INT, -1, $incr, $type );
            return $i + 1;
        }
        elsif (
            $c eq '/'
            && (   ( $i + 1 ) >= length($s)
                || substr( $s, $i + 1, 1 ) eq ' '
                || substr( $s, $i + 1, 1 ) eq '\t' )
          )
        {
            ParseException->throw(
                error => q/'\/' must be followed by an integer./,
                line  => $i
            );
        }
        elsif ( $c eq '*' ) {
            $i++;
        }
        $c = substr( $s, $i, 1 );
        if ( $c eq '/' ) {    # is an increment specified?
            $i++;
            if ( $i >= length($s) ) {
                ParseException->throw(
                    error => q/Unexpected end of string./,
                    line  => $i
                );
            }

            $incr = $this->get_numeric_value( $s, $i );

            $i++;
            if ( $incr > 10 ) {
                $i++;
            }
            if ( $incr > 59 && ( $type == $SECOND || $type == $MINUTE ) ) {
                ParseException->throw(
                    error => 'Increment > 60 : ' . $incr,
                    line  => $i
                );
            }
            elsif ( $incr > 23 && ( $type == $HOUR ) ) {
                ParseException->throw(
                    error => 'Increment > 24 : ' . $incr,
                    line  => $i
                );
            }
            elsif ( $incr > 31 && ( $type == $DAY_OF_MONTH ) ) {
                ParseException->throw(
                    error => 'Increment > 31 : ' . $incr,
                    line  => $i
                );
            }
            elsif ( $incr > 7 && ( $type == $DAY_OF_WEEK ) ) {
                ParseException->throw(
                    error => 'Increment > 7 : ' . $incr,
                    line  => $i
                );
            }
            elsif ( $incr > 12 && ( $type == $MONTH ) ) {
                ParseException->throw(
                    error => 'Increment > 12 : ' . $incr,
                    line  => $i
                );
            }
        }
        else {
            $incr = 1;
        }

        $this->add_to_set( $ALL_SPEC_INT, -1, $incr, $type );
        return $i;
    }
    elsif ( $c eq 'L' ) {
        $i++;
        if ( $type == $DAY_OF_MONTH ) {
            $this->lastday_of_month(1);
        }
        if ( $type == $DAY_OF_WEEK ) {
            $this->add_to_set( 7, 7, 0, $type );
        }
        if ( $type == $DAY_OF_MONTH && length($s) > $i ) {
            $c = substr( $s, $i, 1 );
            if ( $c eq 'W' ) {
                $this->nearest_weekday(1);
                $i++;
            }
        }
        return $i;
    }
    elsif ( ord($c) >= ord('0') && ord($c) <= ord('9') ) {
        my $val = int($c);
        $i++;
        if ( $i >= length($s) ) {
            $this->add_to_set( $val, -1, -1, $type );
        }
        else {
            $c = substr( $s, $i, 1 );
            if ( ord($c) >= ord('0') && ord($c) <= ord('9') ) {

                # ValueSet ??
                my $vs = $this->get_value( $val, $s, $i );
                $val = $vs->value;
                $i   = $vs->pos;
            }
            $i = $this->check_next( $i, $s, $val, $type );
            return $i;
        }
    }
    else {
        ParseException->throw(
            error => "Unexpected character: " . $c,
            line  => $i
        );
    }

    return $i;
}

sub check_next {
    my $this = shift;

    my ( $pos, $s, $val, $type ) = @_;

    my $end = -1;
    my $i   = $pos;

    if ( $i >= length($s) ) {
        $this->add_to_set( $val, $end, -1, $type );
        return $i;
    }

    my $c = substr( $s, $pos, 1 );

    if ( $c eq 'L' ) {
        if ( $type == $DAY_OF_WEEK ) {
            $this->lastday_of_week(1);
        }
        else {
            ParseException->throw(
                "'L' option is not valid here. (pos=" . $i . ")", $i );
        }

        # TreeSet
        my $set = $this->get_set($type);
        $set->add( int($val) );
        $i++;
        return $i;
    }

    if ( $c eq 'W' ) {
        if ( $type == $DAY_OF_MONTH ) {
            $this->nearest_weekday(1);
        }
        else {
            ParseException->throw(
                "'W' option is not valid here. (pos=" . $i . ")", $i );
        }

        # TreeSet
        my $set = $this->get_set($type);
        $set->add( int($val) );
        $i++;
        return $i;
    }

    if ( $c eq '#' ) {
        if ( $type != $DAY_OF_WEEK ) {
            ParseException->throw(
                error => "'#' option is not valid here. (pos=" . $i . ")",
                line  => $i
            );
        }
        $i++;
        eval {
            $this->nthday_of_week( int( substr( $s, $i ) ) );
            if ( $this->nthday_of_week < 1 || $this->nthday_of_week > 5 ) {
                Exception::Class->throw();
            }
        };

        if ( my $e = Exception::Class->caught() ) {
            ParseException->throw(
                error =>
                  "A numeric value between 1 and 5 must follow the '#' option",
                line => $i
            );
        }

        # TreeSet
        my $set = $this->get_set($type);
        $set->add( int($val) );
        $i++;
        return $i;
    }

    if ( $c eq '-' ) {
        $i++;
        $c = substr( $s, $i, 1 );
        my $v = int($c);
        $end = $v;
        $i++;
        if ( $i >= length($s) ) {
            $this->add_to_set( $val, $end, 1, $type );
            return $i;
        }
        $c = substr( $s, $i, 1 );
        if ( $c >= '0' && $c <= '9' ) {

            # ValueSet
            my $vs = $this->get_value( $v, $s, $i );
            my $v1 = $vs->value;
            $end = $v1;
            $i   = $vs->pos;
        }
        if ( $i < length($s) && ( ( $c = substr( $s, $i, 1 ) ) eq '/' ) ) {
            $i++;
            $c = substr( $s, $i, 1 );
            my $v2 = int($c);
            $i++;
            if ( $i >= length($s) ) {
                $this->add_to_set( $val, $end, $v2, $type );
                return $i;
            }
            $c = substr( $s, $i, 1 );
            if ( $c >= '0' && $c <= '9' ) {

                # ValueSet
                my $vs = $this->get_value( $v2, $s, $i );
                my $v3 = $vs->value;
                $this->add_to_set( $val, $end, $v3, $type );
                $i = $vs->pos;
                return $i;
            }
            else {
                $this->add_to_set( $val, $end, $v2, $type );
                return $i;
            }
        }
        else {
            $this->add_to_set( $val, $end, 1, $type );
            return $i;
        }
    }

    if ( $c eq '/' ) {
        $i++;
        $c = substr( $s, $i, 1 );
        my $v2 = int($c);
        $i++;
        if ( $i >= length($s) ) {
            $this->add_to_set( $val, $end, $v2, $type );
            return $i;
        }
        $c = substr( $s, $i, 1 );
        if ( $c >= '0' && $c <= '9' ) {

            # ValueSet
            my $vs = $this->get_value( $v2, $s, $i );
            my $v3 = $vs->value;
            $this->add_to_set( $val, $end, $v3, $type );
            $i = $vs->pos;
            return $i;
        }
        else {
            ParseException->throw(
                error => "Unexpected character '" . $c . "' after '/'", line => $i );
        }
    }

    $this->add_to_set( $val, $end, 0, $type );
    $i++;
    return $i;
}

sub get_cron_expression {
    my $this = shift;

    return $this->cron_expression;
}

sub skip_white_space {
    my $this = shift;

    my ( $i, $s ) = @_;

    for (
        ;
        $i < length($s)
        && ( substr( $s, $i, 1 ) eq ' ' || substr( $s, $i, 1 ) eq '\t' ) ;
        $i++
      )
    {
        ;
    }

    return $i;
}

sub find_next_white_space {
    my $this = shift;

    my ( $i, $s ) = @_;

    for (
        ;
        $i < length($s)
        && ( substr( $s, $i, 1 ) ne ' ' || substr( $s, $i, 1 ) ne '\t' ) ;
        $i++
      )
    {
        ;
    }

    return $i;
}

sub add_to_set {
    my $this = shift;

    my ( $val, $end, $incr, $type ) = @_;

    #TreeSet
    my $set = $this->get_set($type);

    if ( $type == $SECOND || $type == $MINUTE ) {
        if (   ( $val < 0 || $val > 59 || $end > 59 )
            && ( $val != $ALL_SPEC_INT ) )
        {
            ParseException->throw(
                error => "Minute and Second values must be between 0 and 59",
                line  => -1
            );
        }
    }
    elsif ( $type == $HOUR ) {
        if (   ( $val < 0 || $val > 23 || $end > 23 )
            && ( $val != $ALL_SPEC_INT ) )
        {
            ParseException->throw(
                error => "Hour values must be between 0 and 23",
                line  => -1
            );
        }
    }
    elsif ( $type == $DAY_OF_MONTH ) {
        if (   ( $val < 1 || $val > 31 || $end > 31 )
            && ( $val != $ALL_SPEC_INT )
            && ( $val != $NO_SPEC_INT ) )
        {
            ParseException->throw(
                error => "Day of month values must be between 1 and 31",
                line  => -1
            );
        }
    }
    elsif ( $type == $MONTH ) {
        if (   ( $val < 1 || $val > 12 || $end > 12 )
            && ( $val != $ALL_SPEC_INT ) )
        {
            ParseException->throw(
                error => "Month values must be between 1 and 12",
                line  => -1
            );
        }
    }
    elsif ( $type == $DAY_OF_WEEK ) {
        if (   ( $val == 0 || $val > 7 || $end > 7 )
            && ( $val != $ALL_SPEC_INT )
            && ( $val != $NO_SPEC_INT ) )
        {
            ParseException->throw(
                error => "Day-of-Week values must be between 1 and 7",
                line  => -1
            );
        }
    }

    if ( ( $incr == 0 || $incr == -1 ) && $val != $ALL_SPEC_INT ) {
        {
            if ( $val != -1 ) {
                $set->add($val);
            }
            else {
                $set->add($NO_SPEC);
            }
        }

        return;
    }

    my $start_at = $val;
    my $stop_at  = $end;

    if ( $val == $ALL_SPEC_INT && $incr <= 0 ) {
        $incr = 1;
        $set->add($ALL_SPEC);    # put in a marker, but also fill values
    }

    if ( $type == $SECOND || $type == $MINUTE ) {
        if ( $stop_at == -1 ) {
            $stop_at = 59;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 0;
        }
    }
    elsif ( $type == $HOUR ) {
        if ( $stop_at == -1 ) {
            $stop_at = 23;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 0;
        }
    }
    elsif ( $type == $DAY_OF_MONTH ) {
        if ( $stop_at == -1 ) {
            $stop_at = 31;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 1;
        }
    }
    elsif ( $type == $MONTH ) {
        if ( $stop_at == -1 ) {
            $stop_at = 12;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 1;
        }
    }
    elsif ( $type == $DAY_OF_WEEK ) {
        if ( $stop_at == -1 ) {
            $stop_at = 7;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 1;
        }
    }
    elsif ( $type == $YEAR ) {
        if ( $stop_at == -1 ) {
            $stop_at = 2099;
        }
        if ( $start_at == -1 || $start_at == $ALL_SPEC_INT ) {
            $start_at = 1970;
        }
    }

   # if the end of the range is before the start, then we need to overflow into
   # the next day, month etc. This is done by adding the maximum amount for that
   # type, and using modulus max to determine the value being added.
    my $max = -1;
    if ( $stop_at < $start_at ) {
        if ( $type == $SECOND ) {
            $max = 60;
        }
        elsif ( $type == $MINUTE ) {
            $max = 60;
        }
        elsif ( $type == $HOUR ) {
            $max = 24;
        }
        elsif ( $type == $MONTH ) {
            $max = 12;
        }
        elsif ( $type == $DAY_OF_WEEK ) {
            $max = 7;
        }
        elsif ( $type == $DAY_OF_MONTH ) {
            $max = 31;
        }
        elsif ( $type == $YEAR ) {
            IllegalArgumentException->throw(
                error => "Start year must be less than stop year" );
        }
        else {
            IllegalArgumentException->throw(
                error => "Unexpected type encountered" );
        }

        $stop_at += $max;
    }

    for ( my $i = $start_at ; $i <= $stop_at ; $i += $incr ) {
        if ( $max == -1 ) {

            # ie: there's no max to overflow over
            $set->add( int($i) );
        }
        else {

            # take the modulus to get the real value
            my $i2 = $i % $max;

           # 1-indexed ranges should not include 0, and should include their max
            if (
                $i2 == 0
                && (   $type == $MONTH
                    || $type == $DAY_OF_WEEK
                    || $type == $DAY_OF_MONTH )
              )
            {
                $i2 = $max;
            }

            $set->add( int($i2) );
        }
    }
}

sub get_set {
    my $this = shift;

    my $type = shift;

    if ( $type == $SECOND ) {
        return $this->seconds;
    }
    elsif ( $type == $MINUTE ) {
        return $this->minutes;
    }
    elsif ( $type == $HOUR ) {
        return $this->hours;
    }
    elsif ( $type == $MONTH ) {
        return $this->months;
    }
    elsif ( $type == $DAY_OF_MONTH ) {
        return $this->days_of_month;
    }
    elsif ( $type == $DAY_OF_WEEK ) {
        return $this->days_of_week;
    }
    elsif ( $type == $YEAR ) {
        return $this->years;
    }
    else {
        return undef;
    }
}

sub get_value {
    my $this = shift;

    my ( $v, $s, $i ) = @_;

    my $c = substr( $s, $i, 1 );
    my $s1 = "$v";

    while ( ord($c) >= ord('0') && ord($c) <= ord('9') ) {
        $s1 .= $c;
        $i++;
        if ( $i >= length($s) ) {
            last;
        }
        $c = substr( $s, $i, 1 );
    }

    # ValueSet
    my $val = DateTime::Event::Cron::Quartz::ValueSet->new;

    $val->pos( ( $i < length($s) ) ? $i : $i + 1 );
    $val->value( int($s1) );
    return $val;
}

sub get_numeric_value {
    my $this = shift;

    my ( $s, $i ) = @_;

    my $end_of_val = $this->find_next_white_space( $i, $s );
    my $val = substr( $s, $i, $end_of_val );

    if ( !( $val =~ /^\d+$/ ) ) {
        ParseException->throw(
            error => "value is not numeric: " . $val,
            line  => $i
        );
    }

    return int($val);
}

sub get_month_number {
    my $this = shift;

    my $s = shift;

    my $integer = $MONTH_MAP->{$s};

    if ( !defined $integer ) {
        return -1;
    }

    return $integer;
}

sub get_day_of_week_number {
    my $this = shift;

    my $s = shift;

    my $integer = $DAY_MAP->{$s};

    if ( !defined $integer ) {
        return -1;
    }

    return $integer;
}

#//////////////////////////////////////////////////////////////////////////
#
# Computation Functions
#
#//////////////////////////////////////////////////////////////////////////

sub get_time_after {
    my $this = shift;

    my $after_time = shift->clone;

    # move ahead one second, since we're computing the time *after* the
    # given time
    $after_time->add( seconds => 1 );

    # operable calendar
    my $cl = $after_time->clone;

    my $got_one = 0;

    # loop until we've computed the next time, or we've past the endTime
    ITER: while ( !$got_one ) {

        #if (endTime != null && cl.getTime().after(endTime)) return null;
        if ( ( $cl->year ) > 2999 ) {    # prevent endless loop...
            return undef;
        }


        # get second.................................................
        {
            # sorted set
            # SortedSet
            my $st = undef;
            my $t  = 0;
    
            my $sec = $cl->second;
            my $min = $cl->minute;
    
            $st = $this->seconds->tail_set($sec);
    
            if ( defined $st && $st->size() != 0 ) {
                $sec = int( $st->first_item() );
            }
            else {
                $sec = int( $this->seconds->first_item() );
                $cl->add(minutes => 1);
            }
            $cl->set( second => $sec );
        }

        # get minute.................................................
        {
            my $min = $cl->minute;
            my $hr = $cl->hour;
            my $t = -1;

            my $st = $this->minutes->tail_set($min);
            if ( defined $st && $st->size() != 0 ) {
                $t   = $min;
                $min = int( $st->first_item );
            }
            else {
                # next hour
                $min = int( $this->minutes->first_item() );
                $hr++;
            }

            if ( $min != $t ) {
                $cl->set( second => 0, minute => $min );
                $this->set_calendar_hour( $cl, $hr );
                next ITER;
            }

            $cl->set( minute => $min );
        }

        # get hour...................................................
        {
            my $hr = $cl->hour;
            my $day = $cl->day;
            my $t = -1;
    
            my $st = $this->hours->tail_set( int($hr) );
            if ( defined $st && $st->size() != 0 ) {
                $t  = $hr;
                $hr = int( $st->first_item() );
            }
            else {
                $hr = int( $this->hours->first_item() );
                $day++;
            }

            if ( $hr != $t ) {

                $cl->add( days => $day - $cl->day );
                $cl->set( second => 0, minute => 0 );
    
                $this->set_calendar_hour( $cl, $hr );
                next ITER;
            }
    
            $cl->set( hour => $hr );
        }

        # get day...................................................
        {
            my $day = $cl->day;
            my $mon = $cl->month;
            my $t = -1;
            my $tmon = $mon;

            my $day_of_m_spec = !$this->days_of_month->contains($NO_SPEC);
            my $day_of_w_spec = !$this->days_of_week->contains($NO_SPEC);

            my $min = $cl->min;
            my $sec = $cl->sec;
            my $hr = $cl->hour;

            if ( $day_of_m_spec && !$day_of_w_spec )
            {
                # get day by day of month rule
                my $st = $this->days_of_month->tail_set( int($day) );
                if ( $this->lastday_of_month ) {
                    if ( !$this->nearest_weekday ) {
                        $t = $day;
                        $day = $this->getlastday_of_month( $mon, $cl->year );
                    }
                    else {
                        $t = $day;
                        $day = $this->getlastday_of_month( $mon, $cl->year );
    
                        my $tcal = DateTime->new(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => $day,
                            month  => $mon,
                            year   => $cl->year
                        );
    
                        my $ldom = $this->getlastday_of_month( $mon, $cl->year );
                        my $dow = $tcal->day_of_week_0;
    
                        if ( $dow == $SATURDAY && $day == 1 ) {
                            $day += 2;
                        }
                        elsif ( $dow == $SATURDAY ) {
                            $day -= 1;
                        }
                        elsif ( $dow == $SUNDAY && $day == $ldom ) {
                            $day -= 2;
                        }
                        elsif ( $dow == $SUNDAY ) {
                            $day += 1;
                        }
    
                        $tcal->set(
                            second => $sec,
                            minute => $min,
                            hour   => $hr,
                            day    => $day,
                            month  => $mon
                        );
    
                        # tcal before afterTime
                        if ( DateTime->compare( $tcal, $after_time ) < 0 ) {
                            $day = 1;
                            $mon++;
                        }
                    }
                }
                elsif ( $this->nearest_weekday ) {
                    $t   = $day;
                    $day = int( $this->days_of_month->first_item() );
    
                    my $tcal = DateTime->new(
                        second => 0,
                        minute => 0,
                        hour   => 0,
                        day    => $day,
                        month  => $mon,
                        year   => $cl->year
                    );

                    my $ldom = $this->getlastday_of_month( $mon, $cl->year );
                    my $dow = $tcal->day_of_week_0;

                    if ( $dow == $SATURDAY && $day == 1 ) {
                        $day += 2;
                    }
                    elsif ( $dow == $SATURDAY ) {
                        $day -= 1;
                    }
                    elsif ( $dow == $SUNDAY && $day == $ldom ) {
                        $day -= 2;
                    }
                    elsif ( $dow == $SUNDAY ) {
                        $day += 1;
                    }

                    $tcal->set(
                        second => $sec,
                        minute => $min,
                        hour   => $hr,
                        day    => $day,
                        month  => $mon
                    );
    
                    # tcal before afterTime
                    if ( DateTime->compare( $tcal, $after_time ) < 0 ) {
                        $day = int( $this->days_of_month->first_item() );
                        $mon++;
                    }
                }
                elsif ( defined $st && $st->size() != 0 ) {
                    $t   = $day;
                    $day = int( $st->first_item );

                    # make sure we don't over-run a short month, such as february
                    my $last_day = $this->getlastday_of_month( $mon, $cl->year );
                    if ( $day > $last_day ) {
                        $day = int( $this->days_of_month->first_item() );
                        $mon++;
                    }
                }
                else {
                    $day = int( $this->days_of_month->first_item() );
                    $mon++;
                }

                if ( $day != $t || $mon != $tmon ) {
                    $cl->set(
                        second => 0,
                        minute => 0,
                        hour   => 0
                    );

                    if ($mon > 12) {
                        $cl->set(month => 12, day => 1);
                        $cl->add(months => $mon - 12);
                    } else {
                        $cl->set(month => $mon, day => $day);
                    }

                    next ITER;
                }
            }
            elsif ( $day_of_w_spec && !$day_of_m_spec )
            {
                # get day by day of week rule

                if ( $this->lastday_of_week )
                {         # are we looking for the last XXX day of
                          # the month?

                    my $dow = int( $this->days_of_week->first_item() ); # desired d-o-w
                    my $c_dow       = $cl->day_of_week();    # current d-o-w
                    my $days_to_add = 0;
                    if ( $c_dow < $dow ) {
                        $days_to_add = $dow - $c_dow;
                    }
                    if ( $c_dow > $dow ) {
                        $days_to_add = $dow + ( 7 - $c_dow );
                    }
    
                    my $l_day = $this->getlastday_of_month( $mon, $cl->year );
    
                    if ( $day + $days_to_add > $l_day ) {  # did we already miss the
                                                           # last one?
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => 1,
                            month  => $mon + 1
                        );
                        next ITER;
                    }
    
                    # find date of last occurance of this day in this month...
                    while ( ( $day + $days_to_add + 7 ) <= $l_day ) {
                        $days_to_add += 7;
                    }
    
                    $day += $days_to_add;
    
                    if ( $days_to_add > 0 ) {
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => $day,
                            month  => $mon
                        );
                        next ITER;
                    }
    
                }
                elsif ( $this->nthday_of_week != 0 ) {
    
                    # are we looking for the Nth XXX day in the month?
                    my $dow = int( $this->days_of_week->first_item() );    # desired
                                                                           # d-o-w
                    my $c_dow       = $cl->day_of_week();    # current d-o-w
                    my $days_to_add = 0;
                    if ( $c_dow < $dow ) {
                        $days_to_add = $dow - $c_dow;
                    }
                    elsif ( $c_dow > $dow ) {
                        $days_to_add = $dow + ( 7 - $c_dow );
                    }
    
                    my $day_shifted = 0;
                    if ( $days_to_add > 0 ) {
                        $day_shifted = 1;
                    }
    
                    $day += $days_to_add;
                    my $week_of_month = int( $day / 7 );
                    if ( $day % 7 > 0 ) {
                        $week_of_month++;
                    }
    
                    $days_to_add = ( $this->nthday_of_week - $week_of_month ) * 7;
                    $day += $days_to_add;
                    if (   $days_to_add < 0
                        || $day > $this->getlastday_of_month( $mon, $cl->year ) )
                    {
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => 1,
                            month  => $mon
                        );

                        $cl->add(months => 1);
                        next ITER;
                    }
                    elsif ( $days_to_add > 0 || $day_shifted ) {
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => $day,
                            month  => $mon
                        );
                        next ITER;
                    }
                }
                else {
                    my $c_dow = $cl->day_of_week;    # current d-o-w
                    my $dow = int( $this->days_of_week->first_item() );    # desired
                                                                           # d-o-w
                    my $st = $this->days_of_week->tail_set( int($c_dow) );
                    if ( defined $st && $st->size() > 0 ) {
                        $dow = int( $st->first_item() );
                    }
    
                    my $days_to_add = 0;
                    if ( $c_dow < $dow ) {
                        $days_to_add = $dow - $c_dow;
                    }
                    if ( $c_dow > $dow ) {
                        $days_to_add = $dow + ( 7 - $c_dow );
                    }
    
                    my $l_day = $this->getlastday_of_month( $mon, $cl->year );
    
                    if ( $day + $days_to_add > $l_day ) {  # will we pass the end of
                                                           # the month?
                        # switch to the next month
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            day    => 1
                        );
    
                        $cl->add(months => 1);
    
                        next ITER;
                    }
                    elsif ( $days_to_add > 0 ) {    # are we swithing days?
                        # just add some more days
                        $cl->set(
                            second => 0,
                            minute => 0,
                            hour   => 0,
                            month  => $mon
                        );
    
                        $cl->add(days => $days_to_add);
    
                        next ITER;
                    }
                }
            }
            else {            # dayOfWSpec && !dayOfMSpec
                UnsupportedOperationException->throw(
                    error => q/Support for specifying both /
                      . q/a day-of-week AND a day-of-month parameter is not implemented./
                );
    
                # TODO:
            }

            $cl->set( day => $day );
        }

        # get month...................................................
        {
            my $mon = $cl->month;
            my $year = $cl->year;
            my $t = -1;
    
            # test for expressions that never generate a valid fire date,
            # but keep looping...
            if ( $year > 2099 ) {
                return undef;
            }
    
            my $st = $this->months->tail_set( int($mon) );
            if ( defined $st && $st->size() != 0 ) {
                $t   = $mon;
                $mon = ( int $st->first_item() );
            }
            else {
                $mon = ( int $this->months->first_item() );
                $year++;
            }
            if ( $mon != $t ) {
                $cl->set(
                    second => 0,
                    minute => 0,
                    hour   => 0,
                    day    => 1,
                    month  => $mon
                );
    
                $cl->set( year => $year );
                next ITER;
            }
            $cl->set( month => $mon );
        }

        # get year...................................................
        {
            my $year = $cl->year;
            my $t = -1;

            my $st = $this->years->tail_set( int($year) );
            if ( defined $st && $st->size() != 0 ) {
                $t    = $year;
                $year = int( $st->first_item() );
            }
            else {
                return undef;    # ran out of years...
            }
    
            if ( $year != $t ) {
                $cl->set(
                    second => 0,
                    minute => 0,
                    hour   => 0,
                    day    => 1,
                    month  => 1
                );
                $cl->set( year => $year );
                next ITER;
            }
    
            $cl->set( year => $year );
        }

        $got_one = 1;
    }    # while( !done )

    return $cl;
}

#* Advance the calendar to the particular hour paying particular attention
#* to daylight saving problems.
#*
#* @param cal
#* @param hour

sub set_calendar_hour {
    my $this = shift;

    my ( $cal, $hour ) = @_;

    my $delta = 0;

    if ( $hour == 24 ) {
        $delta = 1;
        $hour--;
    }

    $cal->set( hour => $hour );

    if ( $delta > 0 ) {
        $cal->add( hours => $delta );
    }
}

#=pod
# * NOT YET IMPLEMENTED: Returns the time before the given time
# * that the <code>CronExpression</code> matches.
#=cut

sub get_time_before {
    my $this = shift;

    my $end_time = shift;

    # TODO: implement QUARTZ-423
    return;
}

#=pod
# * NOT YET IMPLEMENTED: Returns the final time that the
# * <code>CronExpression</code> will match.
#=cut

sub get_final_fire_time {

    # TODO: implement QUARTZ-423
    return;
}

sub is_leap_year {
    my $this = shift;

    return DateTime->new( year => shift )->is_leap_year;
}

sub getlastday_of_month {
    my $this = shift;

    my ( $month_num, $year ) = @_;

    return DateTime->last_day_of_month( month => $month_num, year => $year )
      ->day;
}

1;

__END__


=head1 NAME

DateTime::Event::Cron::Quartz - OpensSymphony Quartz cron expression processor


=head1 SYNOPSIS

    use DateTime::Event::Cron::Quartz;

    # object construction
    my $event = DateTime::Event::Cron::Quartz->new('0 0 12 * * ?');

    # get the next event occurrence

    my $next_date = $event->get_next_valid_time_after(DateTime->now);

    print $next_date->datetime;

    # check if it was a correct cron expression provided

    my $is_valid = $event->is_valid_expression('0 0 12 * * ?');

=head1 DESCRIPTION

Documentation is taken
from tutorial L<http://www.opensymphony.com/quartz/wikidocs/CronTriggers%20Tutorial.html>
and api javadoc
L<http://www.opensymphony.com/quartz/api/org/quartz/CronExpression.html>

=head2 Format

A cron expression is a string comprised of 6 or 7 fields separated by white space.
Fields can contain any of the allowed values, along with various combinations
of the allowed special characters for that field. The fields are as follows:

    Field Name    Mandatory?  Allowed Values  Allowed Special Characters
    Seconds         YES       0-59              , - * /
    Minutes         YES       0-59              , - * /
    Hours           YES       0-23              , - * /
    Day of month    YES       1-31              , - * ? / L W
    Month           YES       1-12 or JAN-DEC   , - * /
    Day of week     YES       1-7 or MON-SUN    , - * ? / L #
    Year            NO        empty, 1970-2099  , - * /

So cron expressions can be as simple as this: * * * * ? *
or more complex, like this: 0 0/5 14,18,3-39,52 ? JAN,MAR,SEP MON-FRI 2002-2010

=head2 Special characters

    *  * ("all values") - used to select all values within a field.
        For example, "*" in the minute field means "every minute".
    * ? ("no specific value") - useful when you need to specify something
        in one of the two fields in which the character is allowed,
        but not the other. For example, if I want my trigger to fire on a
        particular day of the month (say, the 10th), but don't care what day
        of the week that happens to be, I would put "10" in the
        day-of-month field, and "?" in the day-of-week field.
        See the examples below for clarification.
    * - - used to specify ranges. For example, "10-12" in the hour field
        means "the hours 10, 11 and 12".
    * , - used to specify additional values. For example, "MON,WED,FRI"
        in the day-of-week field means "the days Monday, Wednesday, and Friday".
    * / - used to specify increments. For example, "0/15" in the seconds
        field means "the seconds 0, 15, 30, and 45". And "5/15" in the seconds
        field means "the seconds 5, 20, 35, and 50". You can also
        specify '/' after the '' character - in this case '' is equivalent to
        having '0' before the '/'. '1/3' in the day-of-month field means
        "fire every 3 days starting on the first day of the month".
    * L ("last") - has different meaning in each of the two fields in which it
        is allowed. For example, the value "L" in the day-of-month field means
        "the last day of the month" - day 31 for January, day 28 for February
        on non-leap years. If used in the day-of-week field by itself, it
        simply means "7" or "SAT". But if used in the day-of-week field after
        another value, it means "the last xxx day of the month" -
        for example "6L" means "the last friday of the month".
        When using the 'L' option, it is important not to specify lists, or
        ranges of values, as you'll get confusing results.
    * W ("weekday") - used to specify the weekday (Monday-Friday) nearest the
        given day. As an example, if you were to specify "15W" as the value for
        the day-of-month field, the meaning is: "the nearest weekday to the 15th
        of the month". So if the 15th is a Saturday, the trigger will fire on
        Friday the 14th. If the 15th is a Sunday, the trigger will fire
        on Monday the 16th. If the 15th is a Tuesday, then it will fire on
        Tuesday the 15th. However if you specify "1W" as the value for
        day-of-month, and the 1st is a Saturday, the trigger will fire on
        Monday the 3rd, as it will not 'jump' over the boundary of a
        month's days. The 'W' character can only be specified when the
        day-of-month is a single day, not a range or list of days.
      The 'L' and 'W' characters can also be combined in the day-of-month field
        to yield 'LW', which translates to "last weekday of the month".
    * # - used to specify "the nth" XXX day of the month.
        For example, the value of "6#3" in the day-of-week field means
        "the third Friday of the month"
        (day 6 = Friday and "#3" = the 3rd one in the month).
        Other examples: "2#1" = the first Monday of the month and
        "4#5" = the fifth Wednesday of the month. Note that if you specify "#5"
        and there is not 5 of the given day-of-week in the month,
        then no firing will occur that month.
      The legal characters and the names of months and days of the week are not
      case sensitive. MON is the same as mon.

=head2 Examples

    Expression                  Meaning
    0 0 12 * * ?                Fire at 12pm (noon) every day
    0 15 10 ? * *               Fire at 10:15am every day
    0 15 10 * * ?               Fire at 10:15am every day
    0 15 10 * * ? *             Fire at 10:15am every day
    0 15 10 * * ? 2005          Fire at 10:15am every day during the year 2005
    0 * 14 * * ?                Fire every minute starting at 2pm and
                                ending at 2:59pm, every day
    0 0/5 14 * * ?              Fire every 5 minutes starting at 2pm and
                                ending at 2:55pm, every day
    0 0/5 14,18 * * ?           Fire every 5 minutes starting at 2pm and ending
                                at 2:55pm, AND fire every 5 minutes starting
                                at 6pm and ending at 6:55pm, every day
    0 0-5 14 * * ?              Fire every minute starting at 2pm and
                                ending at 2:05pm, every day
    0 10,44 14 ? 3 WED          Fire at 2:10pm and at 2:44pm every Wednesday
                                in the month of March.
    0 15 10 ? * MON-FRI         Fire at 10:15am every Monday, Tuesday,
                                Wednesday, Thursday and Friday
    0 15 10 15 * ?              Fire at 10:15am on the 15th day of every month
    0 15 10 L * ?               Fire at 10:15am on the last day of every month
    0 15 10 ? * 5L              Fire at 10:15am on the last Friday of every month
    0 15 10 ? * 5L              Fire at 10:15am on the last Friday of every month
    0 15 10 ? * 5L 2002-2005    Fire at 10:15am on every last friday of every
                                month during the years 2002, 2003, 2004 and 2005
    0 15 10 ? * 5#3             Fire at 10:15am on the third Friday of every month
    0 0 12 1/5 * ?              Fire at 12pm (noon) every 5 days every month,
                                starting on the first day of the month.
    0 11 11 11 11 ?             Fire every November 11th at 11:11am.

Pay attention to the effects of '?' and '*' in the day-of-week
and day-of-month fields!


=head1 SUBROUTINES/METHODS

=over

=item new($cron_expression)

Returns a DateTime::Event::Cron::Quartz object which parses and builds unix-like cron expressions.
If it was an error during expression parsing ParseException is thrown.

=item get_next_valid_time_after($after_datetime)

Returns the next date/time after the given date/time which satisfies the cron expression.

=item is_valid_expression($cron_expression)

Indicates whether the specified cron expression can be parsed
into a valid cron expression.


=back


=head1 BUGS AND LIMITATIONS

* This module is not compatible with unix crontab format. If you are going
to use it for unix crontab processing you should make following changes to it:
add seconds field and set one of day-of-week or day-of-month fields to
unspecified ('?' character)

* Support for specifying both a day-of-week and a day-of-month value is not
complete (you must currently use the '?' character in one of these fields).

* Be careful when setting fire times between mid-night and
1:00 AM - "daylight savings" can cause a skip or a repeat depending on
whether the time moves back or jumps forward.


=head1 AUTHOR

Vadim Loginov <vadim.loginov@gmail.com>


=head1 COPYRIGHT AND LICENSE

Based on the source code and documentation of OpenSymphony
L<http://www.opensymphony.com/team.jsp> Quartz 1.4.2 project licensed
under the Apache License, Version 2.0

Copyright (c) 2009 Vadim Loginov.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 VERSION

0.05

=head1 SEE ALSO

DateTime(3),
L<http://www.opensymphony.com/quartz/api/org/quartz/CronExpression.html>
