package App::JobLog::TimeGrammar;
$App::JobLog::TimeGrammar::VERSION = '1.042';
# ABSTRACT: parse natural (English) language time expressions


use Exporter 'import';
our @EXPORT = qw(
  parse
  daytime
);

use Modern::Perl;
use DateTime;
use Class::Autouse qw(
  App::JobLog::Log
);
use Carp 'croak';
use autouse 'App::JobLog::Config' => qw(
  log
  sunday_begins_week
  pay_period_length
  start_pay_period
  DIRECTORY
);
use autouse 'App::JobLog::Time' => qw(
  now
  today
  tz
);
no if $] >= 5.018, warnings => "experimental::smartmatch";

# some variables we need visible inside the date parsing regex
# %matches holds a complete parsing
# %buffer, as its name suggests, is a temporary buffer
# $d1 and $d2 are the starting and ending dates
our ( %matches, %buffer, $d1, $d2 );

# buffers for numeric month, day, or year
our ( $b1, $b2 );

# holds time of day information
our $time_buffer;

# static maps for translating month and day names to numbers
my ( %month_abbr, %day_abbr );

# the master date parsing regex
my $re = qr{
    \A \s*+ (?: (?&ever) | (?&span) ) \s*+ \Z

    (?(DEFINE)

     (?<ever> (?: all | always | ever | (?:(?:the \s++)? (?: entire | whole ) \s++ )? log ) (?{ $matches{ever} = 1 }) )
     
     (?<span>
      ((?&date)) (?{ $d1 = $^N; stow($d1) })
      (?: (?&span_divider) ((?&date)) (?{ $d2 = $^N; stow($d2) }) )?
     )

     (?<span_divider> \s*+ (?: -++ | \b(?: through | thru | to | till?+ | until )\b ) \s*+)

     (?<at> at | @ )

     (?<at_time> 
       (?{ $time_buffer = undef })
       (?: (?: \s++ | \s*+ (?&at) \s*+ ) (?&time))? 
     )

     (?<at_time_on> (?:(?&at) \s++)? (?&time) \s++ on \s++ )

     (?<date>
      (?{ (%buffer, $b1, $b2, $time_buffer) = ()})
      (?: (?&numeric) | (?&verbal) )
      (?{ $buffer{time} = $time_buffer if $time_buffer })
     )
     
     (?<time>
      (?{ $time_buffer = undef })
      (
       \d{1,2}
       (?:
        : \d{2}
        (?:
         : \d{2}
        )?
       )? 
       (?: \s*+ (?&time_suffix))?
      )
      (?{ $time_buffer = $^N })
     )

     (?<time_suffix> [ap] (?:m|\.m\.))

     (?<numeric> 
      (?:
       (?&year)
       |
       (?&ym)
       |
       (?&at_time_on) (?&numeric_no_time)
       |
       (?&numeric_no_time) (?&at_time))
      (?{ $buffer{type} = 'numeric' })
     )
     
     (?<year> (?{ %buffer = () }) (\d{4}) (?{ $buffer{year} = $^N }) ) 
     
     (?<ym> (?&year) (?&divider) (\d{1,2}) (?{ @buffer{qw(month unit)} = ($^N, 'months') }) )

     (?<numeric_no_time> (?{ %buffer = () }) (?&us) | (?&iso) | (?&md) | (?&dom) )

     (?<us>
      (\d{1,2}) (?{ $b1 = $^N })
      ((?&divider))
      (\d{1,2}) (?{ $b2 = $^N })
      \g{-2}
      (\d{4})
      (?{
       $buffer{year}  = $^N;
       $buffer{month} = $b1;
       $buffer{day}   = $b2;
      })
     )

     (?<iso>
      (\d{4}) (?{ $b1 = $^N })
      ((?&divider))
      (\d{1,2}) (?{ $b2 = $^N })
      \g{-2}
      (\d{1,2})
      (?{
       $buffer{year}  = $b1;
       $buffer{month} = $b2;
       $buffer{day}   = $^N;
      })
     )

     (?<md>
      (\d{1,2}) (?{ $b1 = $^N })
      (?&divider)
      (\d{1,2})
      (?{
       $buffer{month} = $b1;
       $buffer{day}   = $^N;
      })
     )

     (?<dom>
      (\d{1,2})
      (?{ $buffer{day} = $^N })
     )

     (?<verbal>
      (?: (?&my) | (?&named_period) | (?&relative_period) | (?&month_day) | (?&full) ) 
      (?{ $buffer{type} = 'verbal' })
     )

     (?<named_period> (?&modifiable_day) | (?&modifiable_month) | (?&modifiable_period) )

     (?<modifiable_day> (?&at_time_on) (?&modifiable_day_no_time) | (?&modifiable_day_no_time) (?&at_time))

     (?<modifiable_day_no_time>
      ((?:(?&modifier) \s++ )?) (?{ $b1 = $^N })
      ((?&weekday))
      (?{
       $buffer{modifier} = $b1 if $b1;
       $buffer{day}      = $^N; 
      })
     )

     (?<modifiable_month>
      ((?:(?&month_modifier) \s++ )?) (?{ $b1 = $^N })
      ((?&month))
      (?{
       $buffer{modifier} = $b1 if $b1;
       $buffer{month}    = $^N; 
      })
     )

     (?<modifiable_period>
       (?{ $b1 = undef })
       (?:((?&period_modifier)) \s*+  (?{ $b1 = $^N }))?
       ((?&period))
       (?{
	$buffer{modifier} = $b1 if $b1;
	$buffer{period}   = $^N;
       })
     )

     (?<pay> pay | pp | pay \s*+ period )

     (?<relative_period> 
       (?:(?&at) \s*+)? (?&time) \s++ (?&relative_period_no_time)
       |
       (?&relative_period_no_time) (?&at_time)
       |
       (?&now)
     )
     
     (?<now> now (?{ $buffer{day} = 'today' }))

     (?<relative_period_no_time> ( yesterday | today | tomorrow ) (?{ $buffer{day} = $^N }))

     (?<month_day> (?&at_time_on) (?&month_day_no_time) | (?&month_day_no_time) (?&at_time))

     (?<month_day_no_time> (?&month_first) | (?&day_first) )

     (?<month_first>
      ((?&month)) (?{ $b1 = $^N })
      \s++
      (\d{1,2})
      (?{
       $buffer{month} = $b1;
       $buffer{day}   = $^N;
      })
     )
     
     (?<my> ((?&month)) ,? \s*+ (?&year) (?{ @buffer{qw(month unit)} = ($^N, 'months') }) )

     (?<day_first>
      (\d{1,2}) (?{ $b1 = $^N })
      \s++
      ((?&month))
      (?{
       $buffer{month} = $^N;
       $buffer{day}   = $b1;
      })
     )

     (?<full> (?&at_time_on) (?&full_no_time) | (?&full_no_time) (?&at_time))

     (?<full_no_time> (?&dm_full) | (?&md_full) )

     (?<dm_full>
      (\d{1,2}) (?{ $b1 = $^N })
      \s++
      ((?&month)) (?{ $b2 = $^N })
      ,? \s++
      (\d{4})
      (?{
       $buffer{year}  = $^N;
       $buffer{month} = $b2;
       $buffer{day}   = $b1;
      })
     )

     (?<md_full>
      ((?&month)) (?{ $b2 = $^N })
      \s++
      (\d{1,2}) (?{ $b1 = $^N })
      , \s++
      (\d{4})
      (?{
       $buffer{year}  = $^N;
       $buffer{month} = $b2;
       $buffer{day}   = $b1;
      })
     )

     (?<weekday> (?&full_weekday) | (?&short_weekday) )

     (?<full_weekday> sunday | monday | tuesday | wednesday | thursday | friday | saturday )

     (?<short_weekday> sun | mon | tue | wed | thu | fri | sat )

     (?<month> (?&full_month) | (?&short_month) )

     (?<full_month> january | february | march | april | may | june | july | august | september | october | november | december )

     (?<short_month> jan | feb | mar | apr | may | jun | jul | aug | sep | oct | nov | dec )

     (?<modifier> last | this | next )

     (?<period_modifier> (?&modifier) | (?&termini) (?: \s++ of (?: \s++ the )? )? )
     
     (?<period> week | month | year | (?&pay) )

     (?<month_modifier> (?&modifier) | (?&termini) (?: \s++ of )? )

     (?<termini> (?: the \s++ )? (?: (?&beginning) | end ) )

     (?<beginning> beg(?:in(?:ning)?)?)

     (?<divider> [-/.])

    )
}xi;

# stows everything matched so far in %matches
sub stow {
    my %h = %buffer;
    $matches{ $_[0] } = \%h;
    %buffer = ();
}


sub daytime {
    my $time = shift;

    #parse
    $time =~ /(?<hour>\d++)
                  (?:
                   : (?<minute>\d++)
                   (?:
                    : (?<second>\d++)
                   )?
                  )?
                  (?: \s*+ (?<suffix>[ap]) (\.?)m\g{-1})?
                 /ix;
    my ( $hour, $minute, $second, $suffix ) =
      ( $+{hour}, $+{minute} || 0, $+{second} || 0, lc( $+{suffix} || 'x' ) );
    $hour += 12 if $suffix eq 'p' && $hour < 12;
    $suffix = 'p' if $hour > 11;
    $hour = 0 if $hour == 12 && $suffix eq 'a';
    croak
      "impossible time: $time" #<--- syntax error at (eval 4158) line 23, near "croak "impossible time: $time""

      if $hour > 23
          || $minute > 59
          || $second > 59
          || $suffix eq 'a' && $hour > 12;
    $hour = 0 if $suffix eq 'a' && $hour == 12;
    return (
        hour   => $hour,
        minute => $minute,
        second => $second,
        suffix => $suffix
    );
}


sub parse {
    my $phrase = shift;
    local ( %matches, %buffer, $d1, $d2, $b1, $b2, $time_buffer );
    if ( $phrase =~ $re ) {
        if ( $matches{ever} ) {

            # we want the entire timespan of the log
            my ($se) = App::JobLog::Log->new->first_event;
            if ($se) {
                return $se->start, now, 0;
            }
            else {
                return now->subtract( seconds => 1 ), now, 0;
            }
        }

        my $h1   = $matches{$d1};
        my $unit = delete $h1->{unit};
        normalize($h1);
        if ($unit) {

            # $h1 is necessarily fixed and there is no time associated
            $h1 = fix_date( $h1, 1 );
            my $h2 = $h1->clone->add( $unit => 1 )->subtract( seconds => 1 );
            return $h1, $h2, 1;
        }
        else {
            my %t1 = extract_time( $h1, 1 );
            my ( $h2, $count, %t2 );
            if ( $d2 && $matches{$d2} ) {
                $h2 = $matches{$d2};
                normalize($h2);
                %t2    = extract_time($h2);
                $count = 2;
            }
            else {
                $h2    = {%$h1};
                %t2    = ( hour => 23, minute => 59, second => 59 );
                $count = 1;
            }
            infer_modifier( $h1, $h2 );
            my ( $s1, $s2 ) = ( $t1{suffix}, $t2{suffix} );
            delete $t1{suffix}, delete $t2{suffix};
            if ( is_fixed($h1) ) {
                ( $h1, $h2 ) = fixed_start( $h1, $h2, $count == 2 );
            }
            elsif ( is_fixed($h2) ) {
                ( $h1, $h2 ) = fixed_end( $h1, $h2 );
            }
            else {
                ( $h1, $h2 ) = before_now( $h1, $h2, $count == 2 );
            }
            croak "dates in \"$phrase\" are out of order"
              unless DateTime->compare( $h1, $h2 ) <= 0;
            $h1->set(%t1);
            $h2->set(%t2);
            if ( $h1 > $h2 ) {
                if (   $h1->year == $h2->year
                    && $h1->month == $h2->month
                    && $h1->day == $h2->day
                    && $h2->hour < 12
                    && $s2 eq 'x' )
                {

            # we inferred the 12 hour period of the second endpoint incorrectly;
            # it was in the evening rather than morning
                    $h2->add( hours => 12 );
                }
                else {
                    croak "dates in \"$phrase\" are out of order";
                }
            }
            return $h1, $h2, $count == 2;
        }
    }
    croak "cannot parse \"$phrase\" as a date expression";
}

# if the sole expression is a unit identifier, infer the modifier 'this'
sub infer_modifier {
    my ( $h1, $h2 ) = @_;
    if ( keys %$h1 == 2 && keys %$h2 == 2 && $h1->{period} && $h2->{period} ) {
        $h1->{modifier} = $h2->{modifier} = 'this';
    }
}

# pulls time expression -- 11:00 am, e.g. -- out of hash and converts it
# to a series of units
sub extract_time {
    my ( $h, $is_start ) = @_;
    my $time = $h->{time};
    if ( defined $time ) {
        delete $h->{time};

        return daytime($time);
    }
    else {

        #return default values
        return $is_start
          ? ( hour => 0, minute => 0, second => 0, suffix => 'a' )
          : ( hour => 23, minute => 59, second => 59, suffix => 'p' );
    }
}

# produces interpretation of date expression consistent with a fixed end date
sub fixed_end {
    my ( $h1, $h2 ) = @_;
    $h2 = fix_date($h2);
    if ( is_fixed($h1) ) {
        $h1 = fix_date( $h1, 1 );
    }
    else {
        my ( $unit, $amt ) = time_unit($h1);
        $h1 = decontextualized_date( $h1, 1 );
        if ( ref $h1 eq 'DateTime' ) {
            while ( DateTime->compare( $h1, $h2 ) > 0 ) {
                $h1->subtract( $unit => $amt );
            }
        }
        else {

            # we just have a floating weekday
            $h1 = adjust_weekday( $h1, $h2 );
        }
    }
    return ( $h1, $h2 );
}

# picks a day of the week before a given date
sub adjust_weekday {
    my ( $ref, $date ) = @_;
    my $delta = $ref->{day_of_week}
      || die 'should always be day_of_week key at this point';
    my $d = $date->clone;
    $delta = $date->day_of_week - $delta;
    $delta += 7 if $delta <= 0;
    $d->subtract( days => $delta );
    return $d;
}

# determines the finest grained unit of time by which a given date can be modified
sub time_unit {
    my $h = shift;
    if ( $h->{type} eq 'numeric' ) {
        return 'years' => 1 if exists $h->{month};
        return 'months' => 1;
    }
    else {
        if ( my $period = $h->{period} ) {
            for ($period) {
                when ('mon') { return 'months' => 1 }
                when ('wee') { return 'weeks'  => 1 }
                when ('pay') { return 'days'   => pay_period_length() }
            }
        }
        else {
            return 'years' => 1 if exists $h->{month};
            return 'weeks' => 1 if exists $h->{day};
            return 'months' => 1;
        }
    }
}

# produces interpretation of date expression consistent with a fixed start date
sub fixed_start {
    my ( $h1, $h2, $two_endpoints ) = @_;
    $h1 = fix_date( $h1, 1 );
    unless ( $two_endpoints || $h2->{type} ne 'numeric' ) {
        return $h1, $h1->clone if defined $h2->{day};
        return $h1, $h1->clone->add( years => 1 )->subtract( days => 1 );
    }
    if ( is_fixed($h2) ) {
        $h2 = fix_date($h2);
    }
    else {
        my ( $unit, $amt ) = time_unit($h2);
        $h2 = decontextualized_date($h2);
        $h2 = adjust_weekday( $h2, $h1 ) unless ref $h2 eq 'DateTime';
        $h2->subtract( $unit => $amt ) while $h2 > $h1;
        $h2->add( $unit => $amt );
    }
    return ( $h1, $h2 );
}

# date relative to now not yet adjusted relative to its position in the span or
# another fixed date
sub decontextualized_date {
    my ( $h, $is_start ) = @_;
    return decontextualized_numeric_date( $h, $is_start )
      if $h->{type} eq 'numeric';
    for ( $h->{modifier} ) {
        when ('end')       { $is_start = 0 }
        when ('beginning') { $is_start = 1 }
    }
    if ( my $period = $h->{period} ) {
        my $date = today;
        for ($period) {
            when ('mon') {
                $date->truncate( to => 'month' );
                $date->add( months => 1 ) unless $is_start;
            }
            when ('wee') {
                $date->truncate( to => 'week' );
                $date->subtract( days => 1 ) if sunday_begins_week;
                $date->add( weeks => 1 ) unless $is_start;
            }
            when ('pay') {
                my $days =
                  $date->delta_days(start_pay_period)->in_units('days');
                $days %= pay_period_length;
                $date->subtract( days => $days );
                $date->add( days => pay_period_length ) unless $is_start;
            }
            default {
                croak 'DEBUG'
            }
        }
        $date->subtract( days => 1 ) unless $is_start;
        return $date;
    }
    else {
        if ( exists $h->{day} && $h->{day} !~ /^\d++$/ ) {
            init_day_abbr();
            $h->{day_of_week} = $day_abbr{ $h->{day} };
            delete $h->{day};
            return $h;
        }
        if ( exists $h->{month} ) {
            init_month_abbr();
            $h->{month} = $month_abbr{ $h->{month} };
        }
        return decontextualized_numeric_date( $h, $is_start );
    }
}

sub decontextualized_numeric_date {
    my ( $h, $is_start ) = @_;
    my $date = today;
    delete $h->{type};
    delete $h->{modifier};
    $h->{year}  //= $date->year;
    $h->{month} //= $date->month;
    my $day_unspecified = !exists $h->{day};
    $date = DateTime->new( time_zone => tz(), %$h, day => $h->{day} // 1 );

    if ( !( exists $h->{day} || $is_start ) ) {
        $date->add( months => 1 );
        $date->subtract( days => 1 );
    }
    return $date;
}

sub fix_date {
    my ( $d, $is_start ) = @_;
    if ( $d->{type} eq 'verbal' ) {
        if ( $d->{year} ) {
            init_month_abbr();
            $d->{month} = $month_abbr{ $d->{month} };
            delete $d->{type};
            return DateTime->new( time_zone => tz(), %$d );
        }
        elsif ( my $day = $d->{day} ) {
            my $date = today;
            return $date if $day eq 'tod';
            if ( $day eq 'yes' ) {
                $date->subtract( days => 1 );
                return $date;
            }
            elsif ( $day eq 'tom' ) {
                $date->add( days => 1 );
                return $date;
            }
            init_day_abbr();
            my $day_num    = $day_abbr{$day};
            my $todays_num = $date->day_of_week;
            if ( $d->{modifier} eq 'this' ) {
                return $date if $day_num == $todays_num;
                my $delta =
                    $day_num > $todays_num
                  ? $day_num - $todays_num
                  : 7 - $todays_num + $day_num;
                $date->add( days => $delta );
                return $date;
            }
            else {
                my $delta = 7;
                if ( $day_num < $todays_num ) {
                    $delta = $todays_num - $day_num;
                }
                elsif ( $day_num > $todays_num ) {
                    $delta = 7 - $day_num + $todays_num;
                }
                $date->subtract( days => $delta );
                $date->add( days => 14 ) if $d->{modifier} eq 'next';
                return $date;
            }
        }

        if ( my $period = $d->{period} ) {
            my $date = today;
            if ( $d->{modifier} eq 'this' ) {
                for ($period) {
                    when ('mon') {
                        $date->truncate( to => 'month' );
                        $date->add( months => 1 ) unless $is_start;
                    }
                    when ('wee') {
                        my $is_sunday = $date->day_of_week == 7;
                        $date->truncate( to => 'week' );
                        if (sunday_begins_week) {
                            $date->subtract( days => $is_sunday ? -6 : 1 );
                        }
                        $date->add( weeks => 1 ) unless $is_start;
                    }
                    when ('yea') {
                        $date->truncate( to => 'year' );
                        $date->add( years => 1 ) unless $is_start;
                    }
                    when ('pay') {
                        my $days =
                          $date->delta_days(start_pay_period)->in_units('days');
                        $days %= pay_period_length;
                        $date->subtract( days => $days );
                        $date->add( days => pay_period_length )
                          unless $is_start;
                    }
                }
                $date->subtract( days => 1 ) unless $is_start;
            }
            else {
                for ($period) {
                    when ('mon') {
                        $date->truncate( to => 'month' );
                        if ($is_start) {
                            $date->subtract( months => 1 );
                        }
                        else {
                            $date->subtract( days => 1 );
                        }
                        $date->add( months => 2 ) if $d->{modifier} eq 'next';
                    }
                    when ('wee') {
                        my $is_sunday = $date->day_of_week == 7;
                        $date->truncate( to => 'week' );
                        if (sunday_begins_week) {
                            $date->subtract( days => $is_sunday ? -6 : 1 );
                        }
                        if ($is_start) {
                            $date->subtract( weeks => 1 );
                        }
                        else {
                            $date->subtract( days => 1 );
                        }
                        $date->add( days => 14 ) if $d->{modifier} eq 'next';
                    }
                    when ('yea') {
                        $date->truncate( to => 'year' );
                        if ($is_start) {
                            $date->subtract( years => 1 );
                        }
                        else {
                            $date->subtract( days => 1 );
                        }
                        $date->add( years => 2 ) if $d->{modifier} eq 'next';
                    }
                    when ('pay') {
                        my $days =
                          $date->delta_days(start_pay_period)->in_units('days');
                        $days %= pay_period_length;
                        $date->subtract( days => $days );
                        if ($is_start) {
                            $date->subtract( days => pay_period_length );
                        }
                        else {
                            $date->subtract( days => 1 );
                        }
                        $date->add( days => 2 * pay_period_length )
                          if $d->{modifier} eq 'next';
                    }
                }
            }
            return $date;
        }

        init_month_abbr();
        my $date = today;
        $date->truncate( to => 'month' );
        my $month_num  = $month_abbr{ $d->{month} };
        my $todays_num = $date->month;
        if ( $d->{modifier} eq 'this' ) {
            my $delta = 0;
            if ( $todays_num > $month_num ) {
                $delta = 12 - $todays_num + $month_num;
            }
            elsif ( $todays_num < $month_num ) {
                $delta = $month_num - $todays_num;
            }
            $delta++ unless $is_start;
            $date->add( months => $delta );
        }
        else {
            my $delta = 12;
            if ( $todays_num > $month_num ) {
                $delta = $todays_num - $month_num;
            }
            elsif ( $todays_num < $month_num ) {
                $delta -= $month_num - $todays_num;
            }
            $delta-- unless $is_start;
            $date->subtract( months => $delta );
        }
        $date->subtract( days => 1 ) unless $is_start;
        return $date;
    }

    # numeric date
    delete $d->{type};
    return DateTime->new( time_zone => tz(), %$d );
}

# lazy initialization of verbal -> numeric month map
sub init_month_abbr {
    unless (%month_abbr) {
        my @months = qw(jan feb mar apr may jun jul aug sep oct nov dec);
        init_hash( \%month_abbr, \@months );
    }
}

# lazy initialization of verbal -> numeric day of week map
sub init_day_abbr {
    unless (%day_abbr) {
        my @days = qw(mon tue wed thu fri sat sun);
        init_hash( \%day_abbr, \@days );
    }
}

# generic verbal -> numeric map generator
sub init_hash {
    my ( $h, $units ) = @_;
    while (@$units) {
        my $i = @$units;
        my $u = pop @$units;
        $h->{$u} = $i;
    }
}

# produces interpretation of date expression such that neither date ends after
# the present
sub before_now {
    my ( $h1, $h2, $two_endpoints ) = @_;
    infer_missing( $h1, $h2 ) if $two_endpoints;
    my $now = today;
    my ( $u1, $amt1, $u2, $amt2 ) = ( time_unit($h1), time_unit($h2) );
    ( $h1, $h2 ) =
      ( decontextualized_date( $h1, 1 ), decontextualized_date($h2) );
    $h2 = adjust_weekday( $h2, $now ) unless ref $h2 eq 'DateTime';
    $h1 = adjust_weekday( $h1, $now ) unless ref $h1 eq 'DateTime';
    while ( $now < $h2 ) {
        $h2->subtract( $u2 => $amt2 );
    }
    while ( $h2 < $h1 ) {
        $h1->subtract( $u1 => $amt1 );
    }

    if ($two_endpoints) {

        # move the two dates as close together as possible
        while ( $h1 < $h2 ) {
            $h2->subtract( $u2 => $amt2 );
        }
        $h2->add( $u2 => $amt2 );
    }
    return $h1, $h2;
}

# fill in missing fields in two date hashes, each using the other as context
# this is a bit of a hack, but a natural hack
sub infer_missing {
    my ( $h1, $h2 ) = @_;
    if ( $h1->{type} eq $h2->{type} ) {
        while ( my ( $k, $v ) = each %$h1 ) {
            $h2->{$k} //= $v;
        }
        while ( my ( $k, $v ) = each %$h2 ) {
            $h1->{$k} //= $v;
        }
    }
    elsif ( $h2->{type} eq 'numeric' ) {
        if ( $h1->{month} && !$h2->{month} ) {
            init_month_abbr();
            $h2->{month} = $month_abbr{ $h1->{month} };
        }
    }
    else {

        # I don't think we have any problems in this case
    }
}

# normalizes string values
sub normalize {
    my $h = shift;
    delete $h->{debug};
    if ( $h->{type} eq 'verbal' ) {
        for my $key (qw(day month period)) {
            if ( my $value = $h->{$key} ) {
                next if $value =~ /\d/;
                $value = lc $value;
                if ( $value =~ /^p/ ) {
                    croak 'pay period not defined'
                      unless defined start_pay_period;
                    $h->{$key} = 'pay';
                }
                else {
                    $h->{$key} = substr $value, 0, 3;
                }
            }
        }
        for ( $h->{modifier} || '' ) {
            when (/beg/) { $h->{modifier} = 'beginning' }
            when (/end/) { $h->{modifier} = 'end' }
            when (/las/) { $h->{modifier} = 'last' }
            when (/thi/) { $h->{modifier} = 'this' }
            when (/nex/) { $h->{modifier} = 'next' }
        }
    }
}

# whether the particular date expression refers to a fixed
# rather than relative date
sub is_fixed {
    my $h = shift;
    return 1
      if exists $h->{year};
    if ( $h->{type} eq 'verbal' ) {
        if ( exists $h->{modifier} ) {
            return 1 if $h->{modifier} =~ /this|last|next/;
        }
        if ( exists $h->{day} ) {
            return 1 if $h->{day} =~ /yes|tod|tom/;
        }
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::TimeGrammar - parse natural (English) language time expressions

=head1 VERSION

version 1.042

=head1 SYNOPSIS

  #!/usr/bin/perl
  
  use Modern::Perl;
  use DateTime;
  use App::JobLog::Time qw(tz);
  use App::JobLog::TimeGrammar qw(parse);
  
  # for demonstration purposes we modify "today"
  $App::JobLog::Time::today =
    DateTime->new( year => 2011, month => 2, day => 17, time_zone => tz );

  for my $phrase ( 'Monday until the end of the week', 'Tuesday at 9:00 p.m.' ) {
      my ( $start, $end, $endpoints ) = parse($phrase);
      say $phrase;
      say "$start - $end; both endpoints specified? "
        . ( $endpoints ? 'yes' : 'no' );
  }

produces

  Monday until the end of the week
  2011-02-14T00:00:00 - 2011-02-20T23:59:59; both endpoints specified? yes
  Tuesday at 9:00 p.m.
  2011-02-08T21:00:00 - 2011-02-15T23:59:59; both endpoints specified? no

=head1 DESCRIPTION

C<App::JobLog::TimeGrammar> converts natural language time expressions into pairs of
C<DateTime> objects representing intervals. This requires disambiguating ambiguous
terms such as 'yesterday', whose interpretation varies from day to day, and 'Friday', whose
interpretation must be fixed by some frame of reference. The heuristic used by this code
is to look first for a fixed date, either a fully specified date such as 2011/2/17 or
one fixed relative to the current moment such as 'now'. If such a date is present in the time
expression it determines the context for the other date, if it is present. Otherwise
it is assumed that the closest appropriate pair of dates immediately before the current
moment are intended.

Given a pair consisting of fixed and an ambiguous date, we assume the ambiguous date has the
sense such that it is ordered correctly relative to the fixed date and the interval between
them is minimized.

If the time expression provides no time of day, such as 8:00, it is assumed that the first moment
intended is the first second of the first day and the last moment is the last second of the second
day. If no second date is provided the endpoint of the interval will be the last moment of the single
date specified. If a larger time period such as week, month, or year is specified, e.g., 'last week', the
first moment is the first second in the period and the last moment is the last second.

If you wish to parse a single date, not an interval, you can ignore the second date, though you should
check the third value returned by C<parse>, whether an interval was parsed.

C<parse> will croak if it cannot parse the expression given.

=head2 Time Grammar

The following is a semi-formal BNF grammar of time understood by C<App::JobLog::TimeGrammar>. In this
formalization C<s> represents whitespace, C<d> represents a digit, and C<\\n> represents a back reference
to the nth item in parenthesis in the given rule. After the first three rules the rules are alphabetized
to facilitate finding them.

              <expression> = s* ( <ever> | <span> ) s*
                    <ever> = "all" | "always" | "ever" | [ [ "the" s ] ( "entire" | "whole" ) s ] "log"
                    <span> = <date> [ <span_divider> <date> ]
 
                      <at> = "at" | "@"
                 <at_time> = [ ( s | s* <at> s* ) <time> ]
              <at_time_on> = [ <at> s ] <time> s "on" s
               <beginning> = "beg" [ "in" [ "ning" ] ]
                    <date> = <numeric> | <verbal>
               <day_first> = d{1,2} s <month>
                 <divider> = "-" | "/" | "."
                 <dm_full> = d{1,2} s <month> [ "," ] s d{4}
                     <dom> = d{1,2}
                    <full> = <at_time_on> <full_no_time> | <full_no_time> <at_time>
              <full_month> = "january" | "february" | "march" | "april" | "may" | "june" | "july" | "august" | "september" | "october" | "november" | "december" 
            <full_no_time> = <dm_full> | <md_full>
            <full_weekday> = "sunday" | "monday" | "tuesday" | "wednesday" | "thursday" | "friday" | "saturday"
                     <iso> = d{4} ( <divider> ) d{1,2} \\1 d{1,2}
                      <md> = d{1,2} <divider> d{1,2}
                 <md_full> = <month> s d{1,2} "," s d{4}
          <modifiable_day> = <at_time_on> <modifiable_day_no_time> | <modifiable_day_no_time> <at_time>
  <modifiable_day_no_time> = [ <modifier> s ] <weekday>
        <modifiable_month> = [ <month_modifier> s ] <month>
       <modifiable_period> = [ <period_modifier> s ] <period>
                <modifier> = "last" | "this" | "next"
                   <month> = <full_month> | <short_month> 
               <month_day> = <at_time_on> <month_day_no_time> | <month_day_no_time> <at_time>
       <month_day_no_time> = <month_first> | <day_first>
             <month_first> = <month> s d{1,2}
          <month_modifier> = <modifier> | <termini> [ s "of" ]
                      <my> = <month> [","] s <year>
            <named_period> = <modifiable_day> | <modifiable_month> | <modifiable_period> 
                     <now> = "now"
                 <numeric> = <year> | <ym> |<at_time_on> <numeric_no_time> | <numeric_no_time> <at_time>
         <numeric_no_time> = <us> | <iso> | <md> | <dom>
                     <pay> = "pay" | "pp" | "pay" s* "period"
                  <period> = "week" | "month" | "year" | <pay>
         <period_modifier> = <modifier> | <termini> [ s "of" [ s "the" ] ] 
         <relative_period> = [ <at> s* ] <time> s <relative_period_no_time> | <relative_period_no_time> <at_time> | <now>
 <relative_period_no_time> = "yesterday" | "today" | "tomorrow"
             <short_month> = "jan" | "feb" | "mar" | "apr" | "may" | "jun" | "jul" | "aug" | "sep" | "oct" | "nov" | "dec"
           <short_weekday> = "sun" | "mon" | "tue" | "wed" | "thu" | "fri" | "sat" 
            <span_divider> = s* ( "-"+ | ( "through" | "thru" | "to" | "til" [ "l" ] | "until" ) ) s*
                 <termini> = [ "the" s ] ( <beginning> | "end" )
                    <time> = d{1,2} [ ":" d{2} [ ":" d{2} ] ] [ s* <time_suffix> ]
             <time_suffix> = ( "a" | "p" ) ( "m" | ".m." )
                      <us> = d{1,2} ( <divider> ) d{1,2} \\1 d{4}
                  <verbal> = <my> | <named_period> | <relative_period> | <month_day> | <full>  
                 <weekday> = <full_weekday> | <short_weekday>
                    <year> = d{4}
                      <ym> = <year> <divider> d{1,2}

In general C<App::JobLog::TimeGrammar> will understand most time expressions you are likely to want to use.

=head1 METHODS

=head2 daytime

Parses a time expression such as "11:00" or "8:15:40 pm". Returns a map from
C<hour>, C<minute>, C<second>, and C<suffix> to the appropriate value, where
'x' represents an ambiguous suffix.

=head2 parse

This function (it isn't actually a method) is the essential function of this module.
It takes a time expression and returns a pair of C<DateTime> objects representing the
endpoints of the corresponding interval and whether it was given a pair of dates.

If you are parsing an expression defining a point rather than an interval you should be
safe ignoring the second endpoing, but you should check the count to make sure the expression
didn't provide a second endpoint.

This code croaks when it cannot parse the expression, so exception handling is recommended.

=head1 SEE ALSO

L<App::JobLog::Command::parse>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
