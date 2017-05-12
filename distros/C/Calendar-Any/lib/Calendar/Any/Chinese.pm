package Calendar::Any::Chinese;
{
  $Calendar::Any::Chinese::VERSION = '0.5';
}
use base 'Calendar::Any';
use Carp;
use Calendar::Any::Gregorian;
use Calendar::Any::Util::Lunar;

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    if ( @_ ) {
        my %arg;
        if ( $_[0] =~ /-\D/ ) {
            %arg = @_;
        } else {
            if ( $#_ > 0 ) {
                $arg{$_} = shift for qw(-cycle -year -month -day);
            } else {
                return $self->from_absolute(@_);
            }
        }
        foreach ( qw(-cycle -year -month -day) ) {
            $self->{substr($_, 1)} = $arg{$_} if exists $arg{$_};
        }
        $self->absolute_date();
    }
    return $self;
}

sub from_absolute {
    my $self = shift;
    my $absdate = shift;
    $self->{absolute} = $absdate;
    my $date = Calendar::Any::Gregorian->new($absdate);
    $self->{gdate} = $date;
    my $cyear = $date->year+2695;
    my @list = (@{_year($date->year-1)},
                @{_year($date->year)},
                @{_year($date->year+1)});
    foreach ( 0..$#list ) {
        if ( $list[$_]->[0] == 1 ) {
            $cyear++;
        }
        if ( $list[$_+1]->[1] > $absdate ) {
            $date = $list[$_];
            last;
        }
    }
    $self->{cycle} = int(($cyear-1)/60);
    $self->{year} = _mod($cyear, 60);
    $self->{month} = $date->[0];
    $self->{day} = $absdate - $date->[1] + 1;
    return $self;
}

sub absolute_date {
    my $self = shift;
    if (exists $self->{absolute} ) {
        return $self->{absolute};
    }
    my ($cycle, $year, $month, $day) = ($self->{cycle}, $self->{year}, $self->{month}, $self->{day});
    my $gyear = 60*($cycle-1)+$year-1-2636;
    my $monthday = _assoc_month($month, [_memq_month(1, _year($gyear)), @{_year($gyear+1)}]);
    $self->{absolute} = $day-1+$monthday->[1];
    $self->assert_date();
    return $self->{absolute};
}

sub cycle { shift->{cycle}; }

sub is_leap_year {
    my $self = shift;
    my $list = _year_month_list($self->cycle, $self->year);
    return $#{$list} == 12;
}

sub gyear { shift->gdate->year; }

sub gmonth { shift->gdate->month; }

sub gday { shift->gdate->day; }

sub gdate {
    my $self = shift;
    if ( !exists $self->{gdate} ) {
        $self->{gdate} = Calendar::Any::Gregorian->new($self->absolute_date);
    }
    return $self->{gdate};
}

sub last_day_of_month {
    my $self = shift;
    my $date = Calendar::Any::Util::Lunar::new_moon_date
        ( $self->day==1 ? $self->absolute_date+1 : $self,
          timezone(Calendar::Any::Gregorian->new($self->absolute_date)->year));
    return int($date-1-$self->absolute_date + $self->day);
}

sub year_month_list {
    my $self = shift;
    return _year_month_list($self->cycle, $self->year);
}

sub timezone {
    my $year = shift;
    return ((defined $year && $year >= 1928) ? 480 : 465 + 40.0/60.0 );
}

sub next_jieqi_date {
    Calendar::Any::Util::Solar::next_longitude_date($_[0], 15, $_[1]);
}

sub assert_date {
    my $self = shift;
    if ( $self->year < 1 || $self->year > 60 ) {
        confess('Not a valid year: should not from 1 to 60 for ' . ref $self);
    }
    if ( $self->month < 1 || $self->month > 12 ) {
        confess(sprintf('Not a valid month %d: should from 1 to 12 for %s', $self->month, ref $self));
    }
    if ( $self->day < 1 || $self->day > $self->last_day_of_month() ) {
        confess(sprintf('Not a valid day %d: should from 1 to %d in %d, %d for %s',
                        $self->day, $self->last_day_of_month, $self->month, $self->year, ref $self));
    }
}

#==========================================================
# Format calendar
#==========================================================
our @celestial_stem = qw(甲 乙 丙 丁 戊 已 庚 辛 壬 癸);
our @terrestrial_branch = qw(子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥);
our @weekday_name = qw(日 一 二 三 四 五 六);
our @month_name =
    qw(正月 二月 三月 四月 五月 六月 七月 八月 九月 十月 十一月 腊月);
our @day_name = qw
  (初一 初二 初三 初四 初五 初六 初七 初八 初九 初十
   十一 十二 十三 十四 十五 十六 十七 十八 十九 二十
   廿一 廿二 廿三 廿四 廿五 廿六 廿七 廿八 廿九 三十
   卅一);
our @zodiac_name = qw(鼠 牛 虎 兔 龙 蛇 马 羊 猴 鸡 狗 猪);
our @jieqi_name = qw
  (小寒 大寒 立春 雨水 惊蛰 春分
   清明 谷雨 立夏 小满 芒种 夏至
   小暑 大暑 立秋 处暑 白露 秋分
   寒露 霜降 立冬 小雪 大雪 冬至);

sub day_name {
    return $day_name[shift->day-1];
}

sub month_name {
    my $self = shift;
    my $month = $self->month;
    if ( _is_int($month)  ) {
        $month_name[$month-1];
    } else {
        return "闰".$month_name[$month-1];
    }
}

sub weekday_name {
    return "星期".$weekday_name[shift->weekday];
}

sub sexagesimal_name {
    my $self = shift;
    my $year = $self->year-1;
    return $celestial_stem[$year%10] . $terrestrial_branch[$year%12];
}

sub zodiac_name {
    my $self = shift;
    my $year = $self->year-1;
    return $zodiac_name[$year%12];
}

sub format_Y { shift->gyear }
sub format_S { shift->sexagesimal_name }
sub format_D { shift->day_name }
sub format_Z { shift->zodiac_name }
sub format_m { sprintf("%02d", shift->gmonth) }
sub format_d { sprintf("%02d", shift->gday) }
our $default_format = "%Y年%m月%d日 %W %S%Z年%M%D";

#==========================================================
# Private functions
#==========================================================
#==========================================================
# Input  : chinese year cycle, year
# Output : the array of month in the chinese year
# Desc   :
#==========================================================
sub _year_month_list {
    my ($cycle, $year) = @_;
    my $date = __PACKAGE__->new($cycle, $year, 1, 1);
    $year = $date->gyear;
    my $list1 = _year($year);
    my $list2 = _year($year+1);
    my @list = _memq_month(1, $list1);
    foreach ( @$list2 ) {
        last if $_->[0]==1;
        push @list, $_;
    }
    return \@list;
}

#==========================================================
# Input  : x, y
# Output : x modulo y, range from 1-y
# Desc   : like operator %, but instead of 0, return the exclusive y
#==========================================================
sub _mod {
    $_[0] % $_[1] || $_[1];
}

sub _is_int {
    $_[0]-int($_[0])==0;
}

#==========================================================
# Input  : month, an array of month list
# Output : the month list from month
# Desc   : eg, _memq_month(2, [[12, 726464], [1, 726494], [2, 726523], [3, 726553], ...])
#          return [[2, 726523], [3, 726553], ...]
#==========================================================
sub _memq_month {
    my ($month, $list) = @_;
    my $i = 0;
    for ( ; $i<=$#$list; $i++ ) {
        last if ($list->[$i][0] == $month);
    }
    return @{$list}[$i..$#$list];
}

#==========================================================
# Input  : month, an array of month list
# Output : the month in the list
# Desc   : eg, _assoc_month(2, [[12, 726464], [1, 726494], [2, 726523], [3, 726553], ...])
#          return [2, 726523]
#==========================================================
sub _assoc_month {
    my ($month, $list) = @_;
    foreach ( @$list ) {
        return $_ if $_->[0] == $month;
    }
}

#==========================================================
# Input  : Gregorian year
# Output : the chinese month list of the year
# Desc   : The month list always range from winter solstice day in year-1
#          to winter in solstice day. Usually, the month list is start
#          chinese month 12 in last year, but possible start from 11.5.
#          The month with .5 indicate that is a leap month. 
#==========================================================
my %year_cache = (
'2000' => [
    [12, 730126],[1, 730155],[2, 730185],[3, 730215],[4, 730244],[5, 730273],
    [6, 730303],[7, 730332],[8, 730361],[9, 730391],[10, 730420],[11, 730450]
  ],
'2001' => [
    [12, 730480],[1, 730509],[2, 730539],[3, 730569],[4, 730598],[4.5, 730628],
    [5, 730657],[6, 730687],[7, 730716],[8, 730745],[9, 730775],[10, 730804],
    [11, 730834]
  ],
'2002' => [
    [12, 730863],[1, 730893],[2, 730923],[3, 730953],[4, 730982],[5, 731012],
    [6, 731041],[7, 731071],[8, 731100],[9, 731129],[10, 731159],[11, 731188]
  ],
'2003' => [
    [12, 731218],[1, 731247],[2, 731277],[3, 731307],[4, 731336],[5, 731366],
    [6, 731396],[7, 731425],[8, 731455],[9, 731484],[10, 731513],[11, 731543]
  ],
'2004' => [
    [12, 731572],[1, 731602],[2, 731631],[2.5, 731661],[3, 731690],[4, 731720],
    [5, 731750],[6, 731779],[7, 731809],[8, 731838],[9, 731868],[10, 731897],
    [11, 731927]
  ],
'2005' => [
    [12, 731956],[1, 731986],[2, 732015],[3, 732045],[4, 732074],[5, 732104],
    [6, 732133],[7, 732163],[8, 732193],[9, 732222],[10, 732252],[11, 732281]
  ],
'2006' => [
    [12, 732311],[1, 732340],[2, 732370],[3, 732399],[4, 732429],[5, 732458],
    [6, 732488],[7, 732517],[7.5, 732547],[8, 732576],[9, 732606],[10, 732636],
    [11, 732665]
  ],
'2007' => [
    [12, 732695],[1, 732725],[2, 732754],[3, 732783],[4, 732813],[5, 732842],
    [6, 732871],[7, 732901],[8, 732930],[9, 732960],[10, 732990],[11, 733020]
  ],
'2008' => [
    [12, 733049],[1, 733079],[2, 733109],[3, 733138],[4, 733167],[5, 733197],
    [6, 733226],[7, 733255],[8, 733285],[9, 733314],[10, 733344],[11, 733374]
  ],
'2009' => [
    [12, 733403],[1, 733433],[2, 733463],[3, 733493],[4, 733522],[5, 733551],
    [5.5, 733581],[6, 733610],[7, 733639],[8, 733669],[9, 733698],[10, 733728],
    [11, 733757]
  ],
'2010' => [
    [12, 733787],[1, 733817],[2, 733847],[3, 733876],[4, 733906],[5, 733935],
    [6, 733965],[7, 733994],[8, 734023],[9, 734053],[10, 734082],[11, 734112]
  ],
'2011' => [
    [12, 734141],[1, 734171],[2, 734201],[3, 734230],[4, 734260],[5, 734290],
    [6, 734319],[7, 734349],[8, 734378],[9, 734407],[10, 734437],[11, 734466]
  ],
'2012' => [
    [12, 734496],[1, 734525],[2, 734555],[3, 734584],[4, 734614],[4.5, 734644],
    [5, 734673],[6, 734703],[7, 734732],[8, 734762],[9, 734791],[10, 734821],
    [11, 734850]
  ],
'2013' => [
    [12, 734880],[1, 734909],[2, 734939],[3, 734968],[4, 734998],[5, 735027],
    [6, 735057],[7, 735087],[8, 735116],[9, 735146],[10, 735175],[11, 735205]
  ],
'2014' => [
    [12, 735234],[1, 735264],[2, 735293],[3, 735323],[4, 735352],[5, 735382],
    [6, 735411],[7, 735441],[8, 735470],[9, 735500],[9.5, 735530],[10, 735559],
    [11, 735589]
  ],
'2015' => [
    [12, 735618],[1, 735648],[2, 735677],[3, 735707],[4, 735736],[5, 735765],
    [6, 735795],[7, 735824],[8, 735854],[9, 735884],[10, 735914],[11, 735943]
  ],
'2016' => [
    [12, 735973],[1, 736002],[2, 736032],[3, 736061],[4, 736091],[5, 736120],
    [6, 736149],[7, 736179],[8, 736208],[9, 736238],[10, 736268],[11, 736297]
  ],
'2017' => [
    [12, 736327],[1, 736357],[2, 736386],[3, 736416],[4, 736445],[5, 736475],
    [6, 736504],[6.5, 736533],[7, 736563],[8, 736592],[9, 736622],[10, 736651],
    [11, 736681]
  ],
'2018' => [
    [12, 736711],[1, 736741],[2, 736770],[3, 736800],[4, 736829],[5, 736859],
    [6, 736888],[7, 736917],[8, 736947],[9, 736976],[10, 737006],[11, 737035]
  ],
'2019' => [
    [12, 737065],[1, 737095],[2, 737125],[3, 737154],[4, 737184],[5, 737213],
    [6, 737243],[7, 737272],[8, 737301],[9, 737331],[10, 737360],[11, 737389]
  ],
'2020' => [
    [12, 737419],[1, 737449],[2, 737478],[3, 737508],[4, 737538],[4.5, 737568],
    [5, 737597],[6, 737627],[7, 737656],[8, 737685],[9, 737715],[10, 737744],
    [11, 737774]
  ],
);

sub _year {
    my $y = shift;
    if ( !exists $year_cache{$y} ) {
        $year_cache{$y} = _compute_chinese_year($y);
    }
    return $year_cache{$y};
}

sub _compute_chinese_year {
    my $y = shift;
    my $oldtz = $Calendar::Any::Util::Solar::timezone;
    $Calendar::Any::Util::Solar::timezone = timezone($y);
    my $next_solstice = _zodiac_sign(Calendar::Any::Gregorian->new(12, 15, $y));
    my $months = _month_list(_zodiac_sign(Calendar::Any::Gregorian->new(12, 15, $y-1))+1,
                             $next_solstice);
    my $list;
    if ( scalar(@$months) == 12 ) {
        $list = [[12, $months->[0]], map { [ $_, $months->[$_] ]} 1..11];
    } else {
        my $next_sign = _zodiac_sign($months->[0]);
        if ( $months->[0]>$next_sign || $next_sign >= $months->[1] ) {
            $list = [[11.5, $months->[0]], [12, $months->[1]],
                     map { [ $_, $months->[$_+1] ] } 1..11];
        } else {
            my @list = ([12, $months->[0]]);
            if ( _zodiac_sign($months->[1]) >= _zodiac_sign($months->[2]) ) {
                push @list, [12.5, $months->[1]],
                    map { [ $_, $months->[$_+1] ] } 1..11;
            } else {
                push @list, [1, $months->[1]];
                my $i = 2;
                while ( $months->[$i+1] > _zodiac_sign($months->[$i]) ) {
                    push @list, [$i, $months->[$i]];
                    $i++;
                }
                push @list, [$i-0.5, $months->[$i]];
                foreach ( $i..11 ) {
                    push @list, [$_, $months->[$_+1]];
                }
            }
            $list = \@list;
        }
    }
    $Calendar::Any::Util::Solar::timezone = $oldtz;
    return $list;
}

sub _zodiac_sign {
    int(Calendar::Any::Util::Solar::next_longitude_date(shift, 30));
}

#==========================================================
# Input  : start, end, timezone
# Output : the array of new moon date between start and end
# Desc   : start and end should be Calendar object or absolute date
#==========================================================
sub _month_list {
    my ($start, $end) = @_;
    my @list;
    while ( $start <= $end ) {
        $start = int(Calendar::Any::Util::Lunar::new_moon_date($start));
        push @list, $start;
        $start++;
    }
    pop @list if $list[-1]>$end;
    return \@list;
}

1;

__END__

=head1 NAME

Calendar::Any::Chinese - Perl extension for Chinese calendar

=head1 VERSION

version 0.5

=head1 SYNOPSIS

   use Calendar::Any::Chinese;
   my $date = Calendar::Any::Chinese->new(78, 22, 12, 2);

   # or construct from Gregorian:
   my $date = Calendar::Any::Gregorian->new(1, 1, 2006)->to_Chinese();

=head1 DESCRIPTION

From "FREQUENTLY ASKED QUESTIONS ABOUT CALENDARS"(C<http://www.tondering.dk/claus/calendar.html>)

=over

The Chinese calendar - like the Hebrew - is a combined solar/lunar
calendar in that it strives to have its years coincide with the
tropical year and its months coincide with the synodic months. It is
not surprising that a few similarities exist between the Chinese and
the Hebrew calendar:

   * An ordinary year has 12 months, a leap year has 13 months.
   * An ordinary year has 353, 354, or 355 days, a leap year has 383,
     384, or 385 days.

When determining what a Chinese year looks like, one must make a
number of astronomical calculations:

First, determine the dates for the new moons. Here, a new moon is the
completely "black" moon (that is, when the moon is in conjunction with
the sun), not the first visible crescent used in the Islamic and
Hebrew calendars. The date of a new moon is the first day of a new
month.

Secondly, determine the dates when the sun's longitude is a multiple
of 30 degrees. (The sun's longitude is 0 at Vernal Equinox, 90 at
Summer Solstice, 180 at Autumnal Equinox, and 270 at Winter Solstice.)
These dates are called the "Principal Terms" and are used to determine
the number of each month:

Principal Term 1 occurs when the sun's longitude is 330 degrees.
Principal Term 2 occurs when the sun's longitude is 0 degrees.
Principal Term 3 occurs when the sun's longitude is 30 degrees.
etc.
Principal Term 11 occurs when the sun's longitude is 270 degrees.
Principal Term 12 occurs when the sun's longitude is 300 degrees.

Each month carries the number of the Principal Term that occurs in
that month.

In rare cases, a month may contain two Principal Terms; in this case
the months numbers may have to be shifted. Principal Term 11 (Winter
Solstice) must always fall in the 11th month.

All the astronomical calculations are carried out for the meridian 120
degrees east of Greenwich. This roughly corresponds to the east coast
of China.

Some variations in these rules are seen in various Chinese
communities.

=back

=head1 METHOD

=over 4

=item  cycle

The number of the Chinese sexagesimal cycle

=item  is_leap_year

True if the chinese year of the date has leap month.

=item  gyear

The number of year in Gregorian calendar

=item  gmonth

The number of month in Gregorian calendar

=item  gday

The number of day in Gregorian calendar

=item  gdate

The Gregorian calendar date. 

=item  last_day_of_month

The last day of the chinese month.

=item  year_month_list

The month list of the chinese year. For example:

    use Calendar;
    $date = Calendar->new_from_China()->today();
    $date->year_month_list;

The return value may like:

 [[1, 732340], [2, 732370], [3, 732399], [4, 732429], [5, 732458],
  [6, 732488], [7, 732517], [7.5, 732547], [8, 732576], [9, 732606],
  [10, 732636], [11, 732665], [12, 732695]]

The element is construct from month and absolute date. So the first
element is the date of chinese new year.

=head1 FUNCTIONS

=over

=item  timezone

Return chinese timezone. This is an expression in `year' since it
changed at 1928-01-01 00:00:00 from UT+7:45:40 to UT+8. Default is for
Beijing.

=item  next_jieqi_date

Calculate next jieqi from the date.

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 by ywb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
