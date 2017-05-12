#
# Copyright (c) 2001,2002 Flavio Soibelmann Glock. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Date::Tie;
use strict;
use Tie::Hash;
use Exporter;
use POSIX;  # floor()
use Time::Local qw( timegm );
use vars    qw( @ISA %Frac %Max %Min %Mult $Infinity $VERSION $Resolution );
@ISA =      qw( Tie::StdHash ); 
$VERSION =  '0.20';
$Infinity = 999_999_999_999;

%Frac = (   frac_hour =>    60 * 60,      frac_minute => 60, 
            frac_second =>  1,            frac_epoch =>  1 );

%Mult = (   day =>      24 * 60 * 60,  hour =>    60 * 60,      minute => 60, 
            second =>   1,             epoch =>   1,
            monthday => 24 * 60 * 60,  weekday => 24 * 60 * 60, yearday => 24 * 60 * 60, 
            week => 7 * 24 * 60 * 60,  tzhour =>  60 * 60,      tzminute => 60 );

%Max  = (   year =>     $Infinity,     yearday =>  365,         month =>    12,  
            monthday => 28,            day =>      28,          week =>     52, 
            weekday =>  7,             hour =>     23,          minute =>   59,  
            second =>   59,            weekyear => $Infinity,   epoch =>    $Infinity );

%Min  = (   year =>     -$Infinity,    yearday =>  1,           month =>    1, 
            monthday => 1,             day =>      1,           week =>     1,  
            weekday =>  1,             hour =>     0,           minute =>   0, 
            second =>   0,             weekyear => -$Infinity,  epoch =>    -$Infinity  );

sub STORE { 
    my ($self, $key, $value) = @_; 
    my ($delta);
    $key = 'day' if $key eq 'monthday';
    $value =~ tr/\,/\./;  # translate comma to dot
    $value += 0;

    my $i_value = POSIX::floor($value);    # get integer part

    if ($value =~ /e/i) {
        # SCIENTIFIC NOTATION!
        ($value) = sprintf("%0.20f", $value) =~ /(.*?)0*$/;  # without trailing zeroes
    }

    # TODO: make 3 separate 'if's
    if (($i_value != $value) or ($key eq 'frac') or (exists $Frac{$key})) {
        # has fractional part

        my ($frac) = $value =~ /\.(.*)/;  # get fractional part as an 'integer'
        $frac = 0 unless defined $frac;       # or get zero 

        if ($key eq 'frac') {
            if (($value < 0) or ($value >= 1)) {
                # fractional overflow
                $self->STORE('second', $self->FETCH('second') + $i_value);
                # make sure frac is a positive number
                my $len_frac = length($frac);
                $frac = ('1' . '0' x $len_frac ) - $frac if ($value < 0) and ($frac != 0);
                $frac = '0' x ($len_frac - length($frac)) . $frac;
            }
            $self->{frac} = '.' . $frac;
            return;
        }
        if (exists $Frac{$key}) {

            my ($not_frac_key) = $key =~ /frac_(.*)/;
            $self->STORE($not_frac_key, $i_value);
            my $mult = $Frac{$key};

            # make sure frac is a positive number
            my $len_frac = length($frac);
            $frac = ('1' . '0' x $len_frac ) - $frac if ($value < 0) and ($frac != 0);
            $frac = '0' x ($len_frac - length($frac)) . $frac;
            $frac = '.' . $frac;

            # round last digit if the number is a fraction of '3': 1/3 1/9 ...
            # 9 digits is enough for nano-second resolution...
            if (length($frac) > 9) {
                my ($last_frac, $last_mult) = ($frac, $mult);

                foreach(0..3) {

                    if ( $_ == 3 ) {
                        # give-up rounding --- go back to original values ???
                        ($frac, $mult) = ($last_frac, $last_mult);
                        last;
                    }

                    #   000.$
                    if ($frac =~ /000.$/) {
                        $frac =~ s/.$//;
                        last;
                    }
                    elsif ($frac =~ /999.$/) {
                        my ($zeroes, $digit) = $frac =~ /\.(.*)(.)$/;
                        $digit = '0.' . '0' x (length($zeroes)-1) . sprintf("%02d", 10 - $digit);
                        $frac += $digit;
                        last;
                    }
                    else {
                        $frac *= 3;
                        $mult /= 3;
                    }

                } # foreach
            } # round 1/3 1/9 ...

            # zero units below this
            if ($not_frac_key eq 'hour') {
                $self->STORE('minute', 0);
                $self->STORE('second', 0);
            }
            if ($not_frac_key eq 'minute') {
                $self->STORE('second', 0);
            }
            $self->STORE('frac', $mult * $frac);

            return;
        }

        # error - this unit does not allow a fractional part
        $key =~ s/frac_//;
        $value = POSIX::floor($value + 0.5);    # round to integer

    }   # end: has fractional part

    if ($key eq 'tz') {
        # note: this must be "int", not "floor" !!
        STORE($self, 'tzminute', $value - 40 * int($value / 100));   #  60 - 100 !
        return;
    }
    if (($key eq 'tzhour') or ($key eq 'tzminute')) {
        $self->{tz100} = 0 unless exists $self->{tz100};  
        if ($key eq 'tzhour') {
            $delta = $value * 3600 - $self->{tz100};
        }
        else {
            $delta = $value * 60   - $self->{tz100};
        }
        $self->{tz100} += $delta;

        $self->STORE('epoch', FETCH($self, 'epoch') + $delta);
        return;
    }

    if ($key eq 'utc_epoch') {
        %{$self} = ( utc_epoch => $value, epoch => $value + ($self->{tz100} || 0), 
                     tz100 => $self->{tz100}, frac => $self->{frac} );
        return;
    }

    if ($key eq 'epoch') {
        $self->{epoch} = $value;
        # remove all other keys (now invalid)
        %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100}, frac => $self->{frac} );    
        return;
    }
    if ($key eq 'month') {
        return if (exists $self->{month}) and ($self->{month} == $value);
        $self->FETCH('day') unless exists $self->{day};  # save 'day' before deleting epoch!

        delete $self->{epoch};     
        delete $self->{utc_epoch};
        delete $self->{weekday};     
        delete $self->{yearday};     
        delete $self->{week};     
        delete $self->{weekyear};     

        if (($value >= $Min{$key}) and ($value <= $Max{$key})) {
            $self->{$key} = $value;
        }
        else {
            $value -= 1;
            $self->{year} += POSIX::floor( $value / 12);
            $self->{month} = 1 + $value % 12;
        }

        if ($self->{day} >= 29) {
            my ($tmp_month) = $self->FETCH('month');
            # check for day overflow
            $self->STORE('day',$self->{day});
            $self->FETCH('month');
            if ($tmp_month != $self->{month}) {
                $self->STORE('day', 0);
            }
        }

        return;
    }
    if ($key eq 'year') {
        return if (exists $self->{year}) and ($self->{year} == $value);
        $self->FETCH('day') unless exists $self->{day};  # save 'day' before deleting epoch!

        delete $self->{epoch};     
        delete $self->{utc_epoch};
        delete $self->{weekday};     
        delete $self->{yearday};     
        delete $self->{week};     
        delete $self->{weekyear};     

        $self->{year} = $value;

        if ($self->{day} >= 29) {
            my ($tmp_month) = $self->FETCH('month');
            # check for day overflow
            $self->STORE('day',$self->{day});
            $self->FETCH('month');
            if ($tmp_month != $self->{month}) {
                $self->STORE('day', 0);
            }
        }

        return;
    }
    if ($key eq 'weekyear') {
        my $week =     exists $self->{week} ?     $self->{week} :     FETCH($self, 'week');
        my $weekyear = exists $self->{weekyear} ? $self->{weekyear} : FETCH($self, 'weekyear');
        FETCH($self, 'epoch') unless exists $self->{epoch};
        $self->{epoch} += 52 * $Mult{week} * ($value - $weekyear);
        %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100}, frac => $self->{frac} );    
        my $week2 =    FETCH($self, 'week');
        while ($week2 != $week) {
            STORE($self, 'week', $week2 + ($value <=> $weekyear) );
            $week2 =   FETCH($self, 'week');
        }
        return;
    }
    # all other keys

    unless ( exists $self->{$key} ) {
        FETCH($self, $key);
    }
    $delta = $value - $self->{$key};

    if (($value >= $Min{$key}) and ($value <= $Max{$key}) and 
        ($key ne 'weekday') and ($key ne 'yearday') and ($key ne 'week')) {
        if (exists $self->{epoch}) {
            $self->{epoch} += $delta * $Mult{$key};
            delete $self->{utc_epoch};
        }
        $self->{$key}  =  $value;
        # update dependencies
        if ($key eq 'day') {
            delete $self->{weekday};     
            delete $self->{yearday};
            delete $self->{weekyear};
            delete $self->{week};     
        }
        return;
    }
    # handle overflow
    # init epoch key
    unless ( exists $self->{epoch} ) {
        FETCH($self, 'epoch');
    }
    $self->{epoch} += $delta * $Mult{$key};
    # remove all other keys (now invalid)
    %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100}, frac => $self->{frac} );    
    return;
}

sub FETCH { 
    my ($self, $key) = @_; 
    my ($value);
    $key = 'day' if $key eq 'monthday';

    if ($key eq 'frac') {
        return $self->{frac};
    }
    if (exists $Frac{$key}) {
        my ($not_frac_key) = $key =~ /frac_(.*)/;
        $value = $self->FETCH($not_frac_key);
        return $value . $self->{frac} if ($Frac{$key} == 1);  # no rounding
        # units below this
        if ($not_frac_key eq 'hour') {
            $value += $self->FETCH('minute') / 60.0;
            $value += $self->FETCH('second') / 3600.0;
        }
        if ($not_frac_key eq 'minute') {
            $value += $self->FETCH('second') / 60.0;
        }
        $value += $self->FETCH('frac') / $Frac{$key};
        $value = '0' . $value if ($value >= 0) and ($value < 10);  # format output
        $value = $value . '.0' unless ($value =~ /\./);            # format output
        return $value;
    }
    if ($key eq 'tz') {
        my ($h, $m) = (FETCH($self, 'tzhour'), FETCH($self, 'tzminute'));
        my $s = $self->{tz100} < 0 ? '-' : '+';
        return $s . substr($h,1,2) . sprintf("%02d", abs($m));
    }
    if ($key eq 'tzhour') {
        my $s = $self->{tz100} < 0 ? '-' : '+';
        # note: this must be "int", not "floor" !!
        $value = int($self->{tz100} / 3600);
        return $s . sprintf("%02d", abs($value));
    }
    if ($key eq 'tzminute') {
        my $s = $self->{tz100} < 0 ? '-' : '+';
        # note: this must be "int", not "floor" !!
        $value = int( ( $self->{tz100} - 3600 * int($self->{tz100} / 3600) ) / 60 );
        return $s . sprintf("%02d", abs($value));
    }

    unless (exists($self->{$key}) ) {
        # create key if possible
        if (( $key eq 'epoch') or not exists $self->{epoch} ) {
            my ($year, $month, $day, $hour, $minute, $second);
            $day =    exists $self->{day} ?    $self->{day}    : 1;
            $month =  exists $self->{month} ?  $self->{month} - 1   : 0;
            $year =   exists $self->{year} ?   $self->{year} - 1900 : 0;
            $hour =   exists $self->{hour} ?   $self->{hour}   : 0;
            $minute = exists $self->{minute} ? $self->{minute} : 0;
            $second = exists $self->{second} ? $self->{second} : 0;

            # TODO: test for month overflow (error when using perl 5.8.0)
            #    Day '31' out of range 1..30 at lib/Date/Tie.pm line 383
            eval { $self->{epoch} = timegm( $second, $minute, $hour, $day, $month, $year ); };
            # warn $@ if $@;
            while ($@ =~ /Day \'\d+\' out of range/ ) {
                $day = $self->{day}--;
                eval { $self->{epoch} = timegm( $second, $minute, $hour, $day, $month, $year ); };
                # warn $@ if $@;
            }
            return $self->{epoch} if $key eq 'epoch';  # ???
        }
        (   $self->{second},  $self->{minute},   $self->{hour},
            $self->{day},     $self->{month},    $self->{year},
            $self->{weekday}, $self->{yearday} ) = gmtime($self->{epoch});
        $self->{year} += 1900;
        $self->{month}++;
        $self->{weekday} = 7 unless $self->{weekday};
        $self->{yearday}++;
        $self->{utc_epoch} = $self->{epoch} - ( $self->{tz100} || 0 );

        if ( $key eq 'week' || $key eq 'weekyear' ) {
            $self->{week} = POSIX::floor( ($self->{yearday} - $self->{weekday} + 10) / 7 );
            if ($self->{yearday} > 361) {
                # find out next year's jan-04 weekday
                tie my %tmp, 'Date::Tie', year => ($self->{year} + 1), month => '01', day => '04';
                # jan-04 weekday: 1  2  3  4  5  6  7
                my @wk1 = qw( 29 32 32 32 32 31 30 29 );
                my $last_day = $wk1[$tmp{weekday}];
                $self->{week} = 1 if ($self->{day} >= $last_day);
            }
            if ( $self->{week} == 0 ) {
                my @t = gmtime( timegm( 0,0,0, 31,11,($self->{year} - 1) ) );
                $self->{week} = POSIX::floor( ($t[7] - $t[6] + 11) / 7 );
            }

            $self->{weekyear} = $self->{year};
            $self->{weekyear}++ if ($self->{week} < 2)  and ($self->{month} > 10);
            $self->{weekyear}-- if ($self->{week} > 50) and ($self->{month} < 2);
        }
    } # create keys

    $value = $self->{$key};
    return $value if $key eq 'weekday';
    return $value if $key eq 'utc_epoch';
    return sprintf("%02d", $value) if $key ne 'yearday';
    return sprintf("%03d", $value);
}

sub TIEHASH  { 
    my $self = bless {}, shift;
    my ($tmp1, $tmp2);
    $self->{frac} = '.0'; 
    $self->{tz100} = 0;
    ( $self->{second},  $self->{minute}, $self->{hour},
      $self->{day},     $self->{month},  $self->{year},
      $self->{weekday}, $self->{yearday} ) = gmtime();
    $self->{year} += 1900;
    $self->{month}++;
    $self->{weekday} = 7 unless $self->{weekday};
    $self->{yearday}++;
    while ($#_ > -1) {
        ($tmp1, $tmp2) = (shift, shift);
        STORE ($self, $tmp1, $tmp2);
    }
    return $self;
}

sub new {
    my $class = shift;
    my @parent;
    @parent = %$class if ref $class;
    push @parent, @_;
    my $self = bless {}, ref $class || $class;
    tie %$self, 'Date::Tie', @parent;
    return $self;
}

# FIRSTKEY added to support recommended assignment order: set timezone, then epoch and fractional seconds
#   tie my %b, 'Date::Tie', tz => $d{tz}, epoch => $d{epoch}, frac => $d{frac};

sub FIRSTKEY {
    my ($self) = @_;
    return 'tz';
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    return 'epoch' if $lastkey eq 'tz';
    return 'frac'  if $lastkey eq 'epoch';
    return undef;
}

# This is for debugging only !
# sub iso { my $self = shift; return $self->{year} . '-' . $self->{month} . '-' . $self->{day} . " $self->{weekyear}-W$self->{week}-$self->{weekday}"; }
# sub debug { return; my $self = shift; return join(':',%{$self}); }

1;

__END__

=head1 NAME

Date::Tie - ISO dates made easy

=head1 SYNOPSIS

    use Date::Tie;

    tie my %date, 'Date::Tie', year => 2001, month => 11, day => 9;
    $date{year}++;
    $date{month} += 12;    # 2003-11-09

    # you can also use OO syntax
    my $date = Date::Tie->new( year => 2001, month => 11, day => 9 );
    $date->{year}++;
    $date->{month} += 12;  # 2003-11-09

    $date{weekday} = 0;    # sunday at the start of this week
    $date{weekday} = 7;    # sunday at the end of this week
    $date{weekday} = 14;   # sunday next week 

    $date{tz} = '-0300';   # change timezone
    $date{tzhour}++;       # increment timezone

    # "next month's last day"
    $date{month}+=2;
    $date{day} = 0;        # this is actually a "-1" since days start in "1"

    # copy a date with timezone
    tie my %newdate, 'Date::Tie', tz => $date{tz}, epoch => $date{epoch};
    or
    tie my %newdate, 'Date::Tie', %date;

=head1 DESCRIPTION

Date::Tie is an attempt to simplify date operations syntax.

It works with calendar dates (year-month-day), 
ordinal dates (year-day), week dates (year-week-day),
times (hour:minute:second), decimal fractions (decimal hours,
decimal minutes and decimal seconds), and time-zones. 

Whenever a Date::Tie hash key receives a new value, it will change 
the other keys following the ISO date rules. 
For example: 

     print $a{hour}, ":", $a{minute};     #  '00:59'
     $a{minute}++;
     print $a{hour}, ":", $a{minute};     #  '01:00'

=head1 DEFAULT VALUE

The default value of a new hash is the current value of I<gmtime()>, 
with timezone C<+0000> and with fractional seconds set to zero.

=head1 HASH KEYS

Date::Tie manages a hash containing the keys: 

I<year>, I<month>, I<day>, I<hour>, I<minute>, I<second>,
I<yearday>, I<week>, I<weekday>, I<weekyear>, 
I<epoch>, I<utc_epoch>,
I<tz>, I<tzhour>, I<tzminute>,
I<frac_hour>, I<frac_minute>, I<frac_second>, I<frac_epoch>,
I<frac>. 

All keys can be read and written to.

=over 4

=item I<year>, I<month>, I<day> or I<monthday>, I<hour>, I<minute>, I<second>

These keys are just what they say. 

You can use B<I<monthday>> instead of I<day> if you want to make it clear
it is not a I<yearday> (ordinal calendar) or a I<weekday> (week calendar). 

=item I<yearday>, I<week>, I<weekday>, I<weekyear>

B<I<yearday>> is the day number in the year.

B<I<weekday>> is the day number in the week. I<weekday> C<1> is monday.

B<I<week>> is the week number in the year.

B<I<weekyear>> is the year number, when referring to a week of a year.
It is often I<not equal> to I<year>. 
Changing I<weekyear> will leave you with the same week and weekday, 
while changing I<year> will leave you with the same month and monthday.

=item I<epoch>

B<I<epoch>> is an internal notation and is not a part of the ISO8601
standard. 

This value is system-dependent, and it might overflow
for dates outside the years 1970-2038. 

B<I<epoch>> is the local epoch. That is, time 
C<20020101T000000+0300> is the same epoch as 
C<20020101T000000+0600>.

=item I<utc_epoch>

The system epoch in UTC time, that is, in timezone C<+0000>.

See also the C<epoch> key.

=item I<tz>, I<tzhour>, I<tzminute>

B<I<tz>> is the timezone as hundreds, like in C<-0030>. 
It is I<not always> the same as the expression
S<C<$date{tzhour} . $date{tzminute}>>, which in this case would be C<-00-30>.

Changing timezone (any of I<tz>, I<tzhour>, or I<tzminute>) changes I<epoch>.

=item I<frac_hour>, I<frac_minute>, I<frac_second>, I<frac_epoch>

These keys are used for fractional decimal notation:

    $d{hour}   = 13;
    $d{minute} = 30;                 # 0.5 hour
    $d{second} = 00;       
    print $d{frac_hour};             # '13.5'

    $d{frac_minute} = 17.3;
    print "$d{minute}:$d{second}";   # '17:18'
    $d{frac_minute} -= 0.2;
    print "$d{minute}:$d{second}";   # '17:06'

    $d{epoch} = 1234567;
    $d{frac}  = 0.7654321;
    print $d{frac_epoch};            # '1234567.7654321'

=item I<frac>

Fractional seconds. A value bigger or equal to I<0> and less than I<1 second>.

    $d{frac} =   0.5;
    print $d{frac};              # '.5'

    $d{frac} =   0;
    print $d{frac};              # '.0'

Setting I<frac> does not change I<second> or I<epoch>, unless it overflows:

    $d{second} = 6;
    print $d{second};            # '06'
    $d{frac} =   1.5;
    print $d{second};            # '07'    - frac overflow
    print $d{frac};              # '.5'

To obtain the fractional second or epoch: 

    print "$d{second}$d{frac}";  # '07.5'  - concatenation
    print $d{second} + $d{frac}; # '7.5'   - addition
    print $d{epoch} + $d{frac};  # '45673455.5'   - fractional epoch

See also: I<frac_epoch> and I<frac_second>.

=back

=head1 BASIC ISO8601 

I<Day of year> starts with C<001>. 

I<Day of week> starts with C<1> and is a monday.

I<Week> starts with C<01> and is the first week of the
year that has a thursday. 
Week C<01> often begins in the previous year.

=head1 CAVEATS

Since C<Date::Tie> is based on C<gmtime()> and C<timegm()>, 
it is expected to work only on years between 1970 and 2038
(this is system-dependent).

Reading time zone C<-0030> with S<C<$date{tzhour} . $date{tzminute}>> gives C<-00-30>. 
Use I<tz> to get C<-0030>.

The order of setting hash elements is important, since changing the timezone will
change the hour.

These are some ways to make a copy of C<%d>:

    # copy all fields
    #     hash %d MUST be tied do Date::Tie, if you are using timezones
    tie my %b, 'Date::Tie', %d;

    # set timezone, then epoch, ignoring fractional seconds
    tie my %b, 'Date::Tie', tz => $d{tz}, epoch => $d{epoch};

    # set timezone, then epoch and fractional seconds
    tie my %b, 'Date::Tie', tz => $d{tz}, epoch => $d{epoch}, frac => $d{frac};

    # set timezone, then fractional epoch
    tie my %b, 'Date::Tie', tz => $d{tz}, frac_epoch => $d{frac_epoch};

In OO style you can use C<new> to make a copy:

    # make a copy of object
    my $b = $d->new;

    # make a copy of object, then set the copy to next month
    ($b = $d->new)->{month}++;

    # make a copy of object, then set the copy to month 3
    $b = $d->new(month => 3);

If you change I<month>, then I<day> will be adjusted to fit that month:

    $date = (month=>10, day=>31);
    $date{month}++;     #  month=>11, day=>30

If you need to know whether a hash is tied to Date::Tie use perl function I<tied()>

=head1 SEE ALSO

I<DateTime> and C<http://datetime.perl.org>

I<Date::Calc>, I<Date::Manip>, I<Class::Date>, and many other good date and time modules!

Date::Tie depends on I<Tie::Hash>, I<Time::Local> and I<POSIX>.

I<dmoz> section on ISO8601 at 
C<http://dmoz.org/Science/Reference/Standards/Individual_Standards/ISO_8601/>

I<Markus Kuhn> wrote a summary of ISO8601 
International Standard Date and Time Notation,
that can be found at
C<http://www.cl.cam.ac.uk/~mgk25/iso-time.html>

=head1 AUTHOR

Flávio Soibelmann Glock (fglock@gmail.com)

=head1 CREDITS

Original idea based on a mail by dLux.

Eduardo M. Cavalcanti, 
Henrique Pantarotto 
and Jean
contributed bugfixes.

Dan Wright created the C<utc_epoch> key.

=cut

