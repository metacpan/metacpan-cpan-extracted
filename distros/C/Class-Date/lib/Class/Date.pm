package Class::Date;
# $Id: Date.pm,v 8dbcc6b6035d 2008/11/23 00:41:11 dlux $

use 5.006;

use strict;
use vars qw(
  @EXPORT_OK %EXPORT_TAGS @ISA
  $DATE_FORMAT $DST_ADJUST $MONTH_BORDER_ADJUST $RANGE_CHECK
  @NEW_FROM_SCALAR @ERROR_MESSAGES $WARNINGS 
  $DEFAULT_TIMEZONE $LOCAL_TIMEZONE $GMT_TIMEZONE
  $NOTZ_TIMEZONE $RESTORE_TZ
);
use Carp;

use Exporter;
use DynaLoader;
use Time::Local;
use Class::Date::Const;
use Scalar::Util qw(blessed);

use Class::Date::Rel;
use Class::Date::Invalid;

BEGIN { 
    $WARNINGS = 1 if !defined $WARNINGS;
    if ($] > 5.006) {
        *timelocal = *Time::Local::timelocal_nocheck;
        *timegm = *Time::Local::timegm_nocheck;
    } else {
        *timelocal = *Time::Local::timelocal;
        *timegm = *Time::Local::timegm;
    }

    @ISA=qw(DynaLoader Exporter);
    %EXPORT_TAGS = ( errors => $Class::Date::Const::EXPORT_TAGS{errors});
    @EXPORT_OK = (qw( date localdate gmdate now @ERROR_MESSAGES), 
        @{$EXPORT_TAGS{errors}});

    our $VERSION = '1.1.15';
    eval { Class::Date->bootstrap($VERSION); };
    if ($@) {
        warn "Cannot find the XS part of Class::Date, \n".
            "   using strftime, tzset and tzname from POSIX module.\n"
                if $WARNINGS;
        require POSIX;
        *strftime_xs = *POSIX::strftime;
        *tzset_xs = *POSIX::tzset;
        *tzname_xs = *POSIX::tzname;
    }
}

$GMT_TIMEZONE = 'GMT';
$DST_ADJUST = 1;
$MONTH_BORDER_ADJUST = 0;
$RANGE_CHECK = 0;
$RESTORE_TZ = 1;
$DATE_FORMAT="%Y-%m-%d %H:%M:%S";

sub _set_tz { my ($tz) = @_;
    my $lasttz = $ENV{TZ};
    if (!defined $tz || $tz eq $NOTZ_TIMEZONE) {
        # warn "_set_tz: deleting TZ\n";
        delete $ENV{TZ};
        Env::C::unsetenv('TZ') if exists $INC{"Env/C.pm"};
    } else {
        # warn "_set_tz: setting TZ to $tz\n";
        $ENV{TZ} = $tz;
        Env::C::setenv('TZ', $tz) if exists $INC{"Env/C.pm"};
    }
    tzset_xs();
    return $lasttz;
}

sub _set_temp_tz { my ($tz, $sub) = @_;
    my $lasttz = _set_tz($tz);
    my $retval = eval { $sub->(); };
    _set_tz($lasttz) if $RESTORE_TZ;
    die $@ if $@;
    return $retval;
}

tzset_xs();
$LOCAL_TIMEZONE = $DEFAULT_TIMEZONE = local_timezone();
{
    my $last_tz = _set_tz(undef);
    $NOTZ_TIMEZONE = local_timezone();
    _set_tz($last_tz);
}
# warn "LOCAL: $LOCAL_TIMEZONE, NOTZ: $NOTZ_TIMEZONE\n";

# this method is used to determine what is the package name of the relative
# time class. It is used at the operators. You only need to redefine it if
# you want to derive both Class::Date and Class::Date::Rel.
# Look at the Class::Date::Rel::ClassDate also.
use constant ClassDateRel => "Class::Date::Rel";
use constant ClassDateInvalid => "Class::Date::Invalid";

use overload 
  '""'     => "string",
  '-'      => "subtract",
  '+'      => "add",
  '<=>'    => "compare",
  'cmp'    => "compare",
  fallback => 1;

sub date ($;$) { my ($date,$tz)=@_;
  return __PACKAGE__ -> new($date,$tz);
}

sub now () { date(time); }

sub localdate ($) { date($_[0] || time, $LOCAL_TIMEZONE) }

sub gmdate    ($) { date($_[0] || time, $GMT_TIMEZONE) }

sub import {
  my $package=shift;
  my @exported;
  foreach my $symbol (@_) {
    if ($symbol eq '-DateParse') {
      if (!$Class::Date::DateParse++) {
        if ( eval { require Date::Parse } ) {
            push @NEW_FROM_SCALAR,\&new_from_scalar_date_parse;
        } else {
            warn "Date::Parse is not available, although it is requested by Class::Date\n" 
                if $WARNINGS;
        }
      }
    } elsif ($symbol eq '-EnvC') {
      if (!$Class::Date::EnvC++) {
        if ( !eval { require Env::C } ) {
          warn "Env::C is not available, although it is requested by Class::Date\n"
            if $WARNINGS;
        }
      }
    } else {
      push @exported,$symbol;
    }
  };
  $package->export_to_level(1,$package,@exported);
}

sub new { my ($proto,$time,$tz)=@_;
  my $class = ref($proto) || $proto;
  
  # if the prototype is an object, not a class, then the timezone will be
  # the same
  $tz = $proto->[c_tz] 
    if defined($time) && !defined $tz && blessed($proto) && $proto->isa( __PACKAGE__ );

  # Default timezone is used if the timezone cannot be determined otherwise
  $tz = $DEFAULT_TIMEZONE if !defined $tz;

  return $proto->new_invalid(E_UNDEFINED,"") if !defined $time;
  if (blessed($time) && $time->isa( __PACKAGE__ ) ) {
    return $class->new_copy($time,$tz);
  } elsif (blessed($time) && $time->isa('Class::Date::Rel')) {
    return $class->new_from_scalar($time,$tz);
  } elsif (ref($time) eq 'ARRAY') {
    return $class->new_from_array($time,$tz);
  } elsif (ref($time) eq 'SCALAR') {
    return $class->new_from_scalar($$time,$tz);
  } elsif (ref($time) eq 'HASH') {
    return $class->new_from_hash($time,$tz);
  } else {
    return $class->new_from_scalar($time,$tz);
  }
}

sub new_copy { my ($s,$input,$tz)=@_;
  my $new_object=[ @$input ];
  # we don't mind $isgmt!
  return bless($new_object, ref($s) || $s);
}

sub new_from_array { my ($s,$time,$tz) = @_;
  my ($y,$m,$d,$hh,$mm,$ss,$dst) = @$time;
  my $obj= [
    ($y||2000)-1900, ($m||1)-1, $d||1,
    $hh||0         , $mm||0   , $ss||0
  ];
  $obj->[c_tz]=$tz;
  bless $obj, ref($s) || $s;
  $obj->_recalc_from_struct;
  return $obj;
}

sub new_from_hash { my ($s,$time,$tz) = @_;
  $s->new_from_array(_array_from_hash($time),$tz);
}

sub _array_from_hash { my ($val)=@_;
  [
    $val->{year} || ($val->{_year} ? $val->{_year} + 1900 : 0 ), 
    $val->{mon} || $val->{month} || ( $val->{_mon} ? $val->{_mon} + 1 : 0 ), 
    $val->{day}   || $val->{mday} || $val->{day_of_month},
    $val->{hour},
    exists $val->{min} ? $val->{min} : $val->{minute},
    exists $val->{sec} ? $val->{sec} : $val->{second},
  ];
}

sub new_from_scalar { my ($s,$time,$tz)=@_;
  for (my $i=0;$i<@NEW_FROM_SCALAR;$i++) {
    my $ret=$NEW_FROM_SCALAR[$i]->($s,$time,$tz);
    return $ret if defined $ret;
  }
  return $s->new_invalid(E_UNPARSABLE,$time);
}

sub new_from_scalar_internal { my ($s,$time,$tz) = @_;
  return undef if !$time;

  if ($time eq 'now') {
    # now string
    my $obj=bless [], ref($s) || $s;
    $obj->[c_epoch]=time;
    $obj->[c_tz]=$tz;
    $obj->_recalc_from_epoch;
    return $obj;
  } elsif ($time =~ /^\s*(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\d*\s*$/) { 
    # mysql timestamp
    my ($y,$m,$d,$hh,$mm,$ss)=($1,$2,$3,$4,$5,$6);
    return $s->new_from_array([$y,$m,$d,$hh,$mm,$ss],$tz);
  } elsif ($time =~ /^\s*( \-? \d+ (\.\d+ )? )\s*$/x) {
    # epoch secs
    my $obj=bless [], ref($s) || $s;
    $obj->[c_epoch]=$1;
    $obj->[c_tz]=$tz;
    $obj->_recalc_from_epoch;
    return $obj;
  } elsif ($time =~ m{ ^\s* ( \d{0,4} ) - ( \d\d? ) - ( \d\d? ) 
     ( (?: T|\s+ ) ( \d\d? ) : ( \d\d? ) ( : ( \d\d?  ) (\.\d+)?)? )? }x) {
    my ($y,$m,$d,$hh,$mm,$ss)=($1,$2,$3,$5,$6,$8);
    # ISO(-like) date
    return $s->new_from_array([$y,$m,$d,$hh,$mm,$ss],$tz);
  } else {
    return undef;
  }
}

push @NEW_FROM_SCALAR,\&new_from_scalar_internal;

sub new_from_scalar_date_parse { my ($s,$date,$tz)=@_;
    my $lt;
    my ($ss, $mm, $hh, $day, $month, $year, $zone) =
        Date::Parse::strptime($date);
    $zone = $tz if !defined $zone;
    if ($zone eq $GMT_TIMEZONE) {
        _set_temp_tz($zone, sub {
            $ss     = ($lt ||= [ gmtime ])->[0]  if !defined $ss;
            $mm     = ($lt ||= [ gmtime ])->[1]  if !defined $mm;
            $hh     = ($lt ||= [ gmtime ])->[2]  if !defined $hh;
            $day    = ($lt ||= [ gmtime ])->[3] if !defined $day;
            $month  = ($lt ||= [ gmtime ])->[4] if !defined $month;
            $year   = ($lt ||= [ gmtime ])->[5] if !defined $year;
        });
    } else {
        _set_temp_tz($zone, sub {
            $ss     = ($lt ||= [ localtime ])->[0]  if !defined $ss;
            $mm     = ($lt ||= [ localtime ])->[1]  if !defined $mm;
            $hh     = ($lt ||= [ localtime ])->[2]  if !defined $hh;
            $day    = ($lt ||= [ localtime ])->[3] if !defined $day;
            $month  = ($lt ||= [ localtime ])->[4] if !defined $month;
            $year   = ($lt ||= [ localtime ])->[5] if !defined $year;
        });
    }
    return $s->new_from_array( [$year+1900, $month+1, $day, 
        $hh, $mm, $ss], $zone);
}

sub _check_sum { my ($s) = @_;
  my $sum=0; $sum += $_ || 0 foreach @{$s}[c_year .. c_sec];
  return $sum;
}

sub _recalc_from_struct { 
    my $s = shift;
    $s->[c_isdst] = -1;
    $s->[c_wday]  = 0;
    $s->[c_yday]  = 0;
    $s->[c_epoch] = 0; # these are required to suppress warinngs;
    eval {
        local $SIG{__WARN__} = sub { };
        my $timecalc = $s->[c_tz] eq $GMT_TIMEZONE ?
            \&timegm : \&timelocal;
        _set_temp_tz($s->[c_tz],
            sub {
                $s->[c_epoch] = $timecalc->(
                    @{$s}[c_sec,c_min,c_hour,c_day,c_mon], 
                    $s->[c_year] + 1900);
            }
        );
    };
    return $s->_set_invalid(E_INVALID,$@) if $@;
    my $sum = $s->_check_sum;
    $s->_recalc_from_epoch;
    @$s[c_error,c_errmsg] = (($s->_check_sum != $sum ? E_RANGE : 0), "");
    return $s->_set_invalid(E_RANGE,"") if $RANGE_CHECK && $s->[c_error];
    return 1;
}

sub _recalc_from_epoch { my ($s) = @_;
    _set_temp_tz($s->[c_tz],
        sub {
            @{$s}[c_year..c_isdst] = 
                ($s->[c_tz] eq $GMT_TIMEZONE ?
                    gmtime($s->[c_epoch]) : localtime($s->[c_epoch]))
                    [5,4,3,2,1,0,6,7,8];
        }
    )
}

my $SETHASH = {
    year   => sub { shift->[c_year] = shift() - 1900 },
    _year  => sub { shift->[c_year] = shift },
    month  => sub { shift->[c_mon] = shift() - 1 },
    _month => sub { shift->[c_mon] = shift },
    day    => sub { shift->[c_day] = shift },
    hour   => sub { shift->[c_hour] = shift },
    min    => sub { shift->[c_min] = shift },
    sec    => sub { shift->[c_sec] = shift },
    tz     => sub { shift->[c_tz] = shift },
};
$SETHASH->{mon}    = $SETHASH->{month};
$SETHASH->{_mon}   = $SETHASH->{_month};
$SETHASH->{mday}   = $SETHASH->{day_of_month} = $SETHASH->{day};
$SETHASH->{minute} = $SETHASH->{min};
$SETHASH->{second} = $SETHASH->{sec};

sub clone {
    my $s = shift;
    my $new_date = $s->new_copy($s);
    while (@_) {
        my $key = shift;
        my $value = shift;
        $SETHASH->{$key}->($value,$new_date);
    };
    $new_date->_recalc_from_struct;
    return $new_date;
}

*set = *clone; # compatibility

sub year     { shift->[c_year]  +1900 }
sub _year    { shift->[c_year]  }
sub yr       { shift->[c_year]  % 100 }
sub mon      { shift->[c_mon]   +1 }
*month       = *mon;
sub _mon     { shift->[c_mon]   }
*_month      = *_mon;
sub day      { shift->[c_day]   }
*day_of_month= *mday = *day;
sub hour     { shift->[c_hour]  }
sub min      { shift->[c_min]   }
*minute      = *min;
sub sec      { shift->[c_sec]   }
*second      = *sec;
sub wday     { shift->[c_wday]  + 1 }
sub _wday    { shift->[c_wday]  }
*day_of_week = *_wday;
sub yday     { shift->[c_yday]  }
*day_of_year = *yday;
sub isdst    { shift->[c_isdst] }
*daylight_savings = \&isdst;
sub epoch    { shift->[c_epoch] }
*as_sec      = *epoch; # for compatibility
sub tz       { shift->[c_tz] }
sub tzdst    { shift->strftime("%Z") }

sub monname  { shift->strftime('%B') }
*monthname   = *monname;
sub wdayname { shift->strftime('%A') }
*day_of_weekname= *wdayname;

sub error { shift->[c_error] }
sub errmsg { my ($s) = @_;
    sprintf $ERROR_MESSAGES[ $s->[c_error] ]."\n", $s->[c_errmsg] 
}
*errstr = *errmsg;

sub new_invalid { my ($proto,$error,$errmsg) = @_;
    bless([],ref($proto) || $proto)->_set_invalid($error,$errmsg);
}

sub _set_invalid { my ($s,$error,$errmsg) = @_;
    bless($s,$s->ClassDateInvalid);
    @$s = ();
    @$s[ci_error, ci_errmsg] = ($error,$errmsg);
    return $s;
}

sub ampm { my ($s) = @_;
    return $s->[c_hour] < 12 ? "AM" : "PM"; 
}

sub meridiam { my ($s) = @_;
    my $hour = $s->[c_hour] % 12;
    if( $hour == 0 ) { $hour = 12; }
    sprintf('%02d:%02d %s', $hour, $s->[c_min], $s->ampm);
}

sub hms { sprintf('%02d:%02d:%02d', @{ shift() }[c_hour,c_min,c_sec]) }

sub ymd { my ($s)=@_;
  sprintf('%04d/%02d/%02d', $s->year, $s->mon, $s->[c_day])
}

sub mdy { my ($s)=@_;
  sprintf('%02d/%02d/%04d', $s->mon, $s->[c_day], $s->year)
}

sub dmy { my ($s)=@_;
  sprintf('%02d/%02d/%04d', $s->[c_day], $s->mon, $s->year)
}

sub array { my ($s)=@_;
  my @return=@{$s}[c_year .. c_sec];
  $return[c_year]+=1900;
  $return[c_mon]+=1;
  @return;
}

sub aref { return [ shift()->array ] }
*as_array = *aref;

sub struct {
  return ( @{ shift() }
    [c_sec,c_min,c_hour,c_day,c_mon,c_year,c_wday,c_yday,c_isdst] )
}

sub sref { return [ shift()->struct ] }

sub href { my ($s)=@_;
  my @struct=$s->struct;
  my $h={};
  foreach my $key (qw(sec min hour day _month _year wday yday isdst)) {
    $h->{$key}=shift @struct;
  }
  $h->{epoch} = $s->[c_epoch];
  $h->{year} = 1900 + $h->{_year};
  $h->{month} = $h->{_month} + 1;
  $h->{minute} = $h->{min};
  return $h;
}

*as_hash=*href;

sub hash { return %{ shift->href } }

# Thanks to Tony Olekshy <olekshy@cs.ualberta.ca> for this algorithm
# ripped from Time::Object by Matt Sergeant
sub tzoffset { my ($s)=@_;
    my $epoch = $s->[c_epoch];
    my $j = sub { # Tweaked Julian day number algorithm.
        my ($s,$n,$h,$d,$m,$y) = @_; $m += 1; $y += 1900;
        # Standard Julian day number algorithm without constant.
        my $y1 = $m > 2 ? $y : $y - 1;
        my $m1 = $m > 2 ? $m + 1 : $m + 13;
        my $day = int(365.25 * $y1) + int(30.6001 * $m1) + $d;
        # Modify to include hours/mins/secs in floating portion.
        return $day + ($h + ($n + $s / 60) / 60) / 24;
    };
    # Compute floating offset in hours.
    my $delta = _set_temp_tz($s->[c_tz],
        sub {
            24 * (&$j(localtime $epoch) - &$j(gmtime $epoch));
        }
    );
    # Return value in seconds rounded to nearest minute.
    return int($delta * 60 + ($delta >= 0 ? 0.5 : -0.5)) * 60;
}

sub month_begin { my ($s) = @_;
  my $aref = $s->aref;
  $aref->[2] = 1;
  return $s->new($aref);
}

sub month_end { my ($s)=@_;
  return $s->clone(day => 1)+'1M'-'1D';
}

sub days_in_month {
  shift->month_end->mday;
}

sub is_leap_year { my ($s) = @_;
    my $new_date;
    eval {
        $new_date = $s->new([$s->year, 2, 29],$s->tz);
    } or return 0;
    return $new_date->day == 29;
}

sub strftime { my ($s,$format)=@_;
  $format ||= "%a, %d %b %Y %H:%M:%S %Z";
  my $fmt = _set_temp_tz($s->[c_tz], sub { strftime_xs($format,$s->struct) } );
  return $fmt;
}

sub string { my ($s) = @_;
  $s->strftime($DATE_FORMAT);
}

sub subtract { my ($s,$rhs)=@_;
  if (blessed($rhs) && $rhs->isa( __PACKAGE__ )) {
    my $dst_adjust = 0;
    $dst_adjust = 60*60*( $s->[c_isdst]-$rhs->[c_isdst] ) if $DST_ADJUST;
    return $s->ClassDateRel->new($s->[c_epoch]-$rhs->[c_epoch]+$dst_adjust);
  } elsif (blessed($rhs) && $rhs->isa("Class::Date::Rel")) {
    return $s->add(-$rhs);
  } elsif ($rhs) {
    return $s->add($s->ClassDateRel->new($rhs)->neg);
  } else {
    return $s;
  }
}

sub add { my ($s,$rhs)=@_;
  local $RANGE_CHECK;
  $rhs=$s->ClassDateRel->new($rhs) unless blessed($rhs) && $rhs->isa('Class::Date::Rel');
	
  return $s unless blessed($rhs) && $rhs->isa('Class::Date::Rel');

  # adding seconds
  my $retval= $rhs->[cs_sec] ? 
    $s->new_from_scalar($s->[c_epoch]+$rhs->[cs_sec],$s->[c_tz]) :
    $s->new_copy($s);

  # adjust DST if necessary
  if ( $DST_ADJUST && (my $dstdiff=$retval->[c_isdst]-$s->[c_isdst]))  {
    $retval->[c_epoch] -= $dstdiff*60*60;
    $retval->_recalc_from_epoch;
  }
  
  # adding months
  if ($rhs->[cs_mon]) {
    $retval->[c_mon]+=$rhs->[cs_mon];
    my $year_diff= $retval->[c_mon]>0 ? # instead of POSIX::floor
      int ($retval->[c_mon]/12) :
      int (($retval->[c_mon]-11)/12);
    $retval->[c_mon]  -= 12*$year_diff;
    my $expected_month = $retval->[c_mon];
    $retval->[c_year] += $year_diff;
    $retval->_recalc_from_struct;

    # adjust month border if necessary
    if ($MONTH_BORDER_ADJUST && $retval && $expected_month != $retval->[c_mon]) {
      $retval->[c_epoch] -= $retval->[c_day]*60*60*24;
      $retval->_recalc_from_epoch;
    }
  }
  
  # sigh! We have finished!
  return $retval;
}

sub trunc { my ($s)=@_;
  return $s->new_from_array([$s->year,$s->month,$s->day,0,0,0],$s->[c_tz]);
}

*truncate = *trunc;

sub get_epochs {
  my ($lhs,$rhs,$reverse)=@_;
  unless (blessed($rhs) && $rhs->isa( __PACKAGE__ )) {
    $rhs = $lhs->new($rhs);
  }
  my $repoch= $rhs ? $rhs->epoch : 0;
  return $repoch, $lhs->epoch if $reverse;
  return $lhs->epoch, $repoch;
}

sub compare {
  my ($lhs, $rhs) = get_epochs(@_);
  return $lhs <=> $rhs;
}

sub local_timezone {
    return (tzname_xs())[0];
}

sub to_tz { my ($s, $tz) = @_;
    return $s->new($s->epoch, $tz);
}
1;

