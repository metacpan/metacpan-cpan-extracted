package Calendar::Japanese::Holiday;

use 5.008001;
use strict;
use warnings;

use utf8;
use Time::Local;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(getHolidays isHoliday);

our $VERSION = '0.07';


our $FurikaeStr = '振替';

my @StaticHoliday = (
# 山の日を8/11に戻す
		     {'start' => 2022, 'end' => 2999,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日',
					23 => '天皇誕生日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 8  => {11 => '山の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 2021年は山の日が8/8に移動
		     {'start' => 2021, 'end' => 2021,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日',
					23 => '天皇誕生日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 8  => { 8 => '山の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 2020年は山の日が8/10に移動
		     {'start' => 2020, 'end' => 2020,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日',
					23 => '天皇誕生日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 8  => {10 => '山の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 天皇誕生日削除(2019年のみ)
		     {'start' => 2019, 'end' => 2019,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 8  => {11 => '山の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 山の日を追加
		     {'start' => 2016, 'end' => 2018,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 8  => {11 => '山の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				 12 => {23 => '天皇誕生日'},
				},
		     },
# 4/29 みどりの日 => 昭和の日 変更
# みどりの日は5/4に移行
		     {'start' => 2007, 'end' => 2015,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => '昭和の日'},
				 5  => { 3 => '憲法記念日',
					 4 => 'みどりの日',
					 5 => 'こどもの日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				 12 => {23 => '天皇誕生日'},
				},
		     },
# 海の日,敬老の日がHappy Mondayに
		     {'start' => 2003, 'end' => 2006,
		       'days' => {1  => { 1 => '元日'},
				  2  => {11 => '建国記念の日'},
				  4  => {29 => 'みどりの日'},
				  5  => { 3 => '憲法記念日',
					  5 => 'こどもの日'},
				  11 => { 3 => '文化の日',
					 23 => '勤労感謝の日'},
				  12 => {23 => '天皇誕生日'},
				 },
		     },
# 成人の日,体育の日がHappy Mondayに
		     {'start' => 2000, 'end' => 2002,
		      'days' => {1  => { 1 => '元日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => 'みどりの日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 7  => {20 => '海の日'},
				 9  => {15 => '敬老の日'},
				 11 => { 3 => '文化の日',
					 23 => '勤労感謝の日'},
				 12 => {23 => '天皇誕生日'},
				},
		     },
# 海の日追加
		     {'start' => 1996, 'end' => 1999,
		      'days' => {1  => { 1 => '元日',
					15 => '成人の日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => 'みどりの日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 7  => {20 => '海の日'},
				 9  => {15 => '敬老の日'},
				 10 => {10 => '体育の日'},
				 11 => { 3 => '文化の日',
					 23 => '勤労感謝の日'},
				 12 => {23 => '天皇誕生日'},
				},
		     },
# 天皇誕生日変更 4/29 => 12/23
# 旧天皇誕生日をみどりの日に変更
		     {'start' => 1989, 'end' => 1995,
		      'days' => {1  => { 1 => '元日',
					15 => '成人の日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => 'みどりの日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 9  => {15 => '敬老の日'},
				 10 => {10 => '体育の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				 12 => {23 => '天皇誕生日'},
				},
		     },
# 建国記念の日追加
		     {'start' => 1967, 'end' => 1988,
		      'days' => {1  => { 1 => '元日',
					15 => '成人の日'},
				 2  => {11 => '建国記念の日'},
				 4  => {29 => '天皇誕生日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 9  => {15 => '敬老の日'},
				 10 => {10 => '体育の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 敬老の日,体育の日追加
		     {'start' => 1966, 'end' => 1966,
		      'days' => {1  => { 1 => '元日',
					15 => '成人の日'},
				 4  => {29 => '天皇誕生日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 9  => {15 => '敬老の日'},
				 10 => {10 => '体育の日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 国民の祝日に関する法律に定められた祝日のうち7/20以前のものを追加
		     {'start' => 1949, 'end' => 1965,
		      'days' => {1  => { 1 => '元日',
					15 => '成人の日'},
				 4  => {29 => '天皇誕生日'},
				 5  => { 3 => '憲法記念日',
					 5 => 'こどもの日'},
				 11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
# 国民の祝日に関する法律 1948/7/20制定
		     {'start' => 1948, 'end' => 1948,
		      'days' => {11 => { 3 => '文化の日',
					23 => '勤労感謝の日'},
				},
		     },
		    );

my %ExceptionalHoliday = (
			  195904 => {10 => '皇太子明仁親王の結婚の儀'},
			  198902 => {24 => '昭和天皇の大喪の礼'},
			  199011 => {12 => '即位礼正殿の儀'},
			  199306 => { 9 => '皇太子徳仁親王の結婚の儀'},
			  201905 => { 1 => '天皇の即位の日'},
			  201910 => {22 => '即位礼正殿の儀の行われる日'},
			 );

my @daysInMonth = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

sub days_in_month {
    my ($year, $mon) = @_;

    my $days = $daysInMonth[$mon - 1];

    if ($mon == 2 && $year % 4 == 0) {
	if ($year % 100 == 0) {
	    return $days + 1 if $year % 400 == 0;
	    return $days;
	}
	return $days + 1;
    }

    return $days;
}

# 指定曜日の日付一覧を配列で返す
sub weekdays {
    my ($year, $mon, $wday) = @_;

    my @week_days;

    my $wd = (localtime(timelocal(0, 0, 0, 1, $mon - 1, $year)))[6];

    # 指定曜日の最初の日付(カレンダー的に空欄の場合は0以下の値となる)
    my $start = 1 - $wd + $wday;

    my $last_day = days_in_month($year, $mon);

    for (my $day = $start ; $day <= $last_day ; $day += 7) {
	push @week_days, $day if $day > 0;
    }

    return @week_days;
}

sub lookup_holiday_table {
    my ($year) = @_;

    foreach my $tbl (@StaticHoliday) {
	return $tbl->{days}
	  if ($tbl->{start} <= $year && $year <= $tbl->{end});
    }
    return;
}

# 春分の日
# Ref to.
#   http://www.nao.ac.jp/QA/faq/a0301.html
#   http://ja.wikipedia.org/wiki/%E6%98%A5%E5%88%86%E3%81%AE%E6%97%A5
sub shunbun_day {
    my ($year) = @_;

    my $day;

    my $mod = $year % 4;
    if ($mod == 0) {
	if    (1900 <= $year && $year <= 1956) {$day = 21;}
	elsif (1960 <= $year && $year <= 2088) {$day = 20;}
	elsif (2092 <= $year && $year <= 2096) {$day = 19;}
    } elsif ($mod == 1) {
	if    (1901 <= $year && $year <= 1989) {$day = 21;}
	elsif (1993 <= $year && $year <= 2097) {$day = 20;}
    } elsif ($mod == 2) {
	if    (1902 <= $year && $year <= 2022) {$day = 21;}
	elsif (2026 <= $year && $year <= 2098) {$day = 20;}
    } elsif ($mod == 3) {
	if    (1903 <= $year && $year <= 1923) {$day = 22;}
	elsif (1927 <= $year && $year <= 2055) {$day = 21;}
	elsif (2059 <= $year && $year <= 2099) {$day = 20;}
    }

    return $day;
}

# 秋分の日
sub shuubun_day {
    my ($year) = @_;

    my $day;

    my $mod = $year % 4;
    if ($mod == 0) {
	if    ($year == 1900)                  {$day = 23;}
	elsif (1904 <= $year && $year <= 2008) {$day = 23;}
	elsif (2012 <= $year && $year <= 2096) {$day = 22;}
    } elsif ($mod == 1) {
	if    (1901 <= $year && $year <= 1917) {$day = 24;}
	elsif (1921 <= $year && $year <= 2041) {$day = 23;}
	elsif (2045 <= $year && $year <= 2097) {$day = 22;}
    } elsif ($mod == 2) {
	if    (1902 <= $year && $year <= 1946) {$day = 24;}
	elsif (1950 <= $year && $year <= 2074) {$day = 23;}
	elsif (2078 <= $year && $year <= 2098) {$day = 22;}
    } elsif ($mod == 3) {
	if    (1903 <= $year && $year <= 1979) {$day = 24;}
	elsif (1983 <= $year && $year <= 2099) {$day = 23;}
    }

    return $day;
}

sub furikae_days {
    my ($year, $mon, $holidays_tbl) = @_;

    my %days;

    return \%days if $year < 1973;

    while (my ($h_day, $name) = each %$holidays_tbl) {
	# 祝日が日曜日かチェック
	my $wday = (localtime(timelocal(0, 0, 0, $h_day, $mon - 1, $year)))[6];

	if ($wday == 0) {
	    my $furikae_day = $h_day + 1;
	    if ($year >= 2007) {
		# 振り替えた先も祝日ならさらに進める
		$furikae_day++ while (exists $holidays_tbl->{$furikae_day});
		$days{$furikae_day} = $name;
	    } else {
		$days{$furikae_day} = $name
		  if (!exists $holidays_tbl->{$furikae_day});
	    }
	}
    }

    return \%days;
}

# 指定年月の休日一覧を取得(国民の休日、振替休日を処理する前)
sub get_holidays {
    my ($year, $mon) = @_;

    my $holiday_tbl;

    return if !($holiday_tbl = lookup_holiday_table($year));

    my %holidays;
    if (exists $holiday_tbl->{$mon}) {
	%holidays = %{$holiday_tbl->{$mon}};	# Copy
    }

    # Happy Monday (成人の日、海の日、敬老の日、体育の日)
    my @mondays = weekdays($year, $mon, 1);	# 月曜日の一覧

    if ($year >= 2000 && $mon == 1) {$holidays{$mondays[1]} = '成人の日';}

    # 体育の日/スポーツの日(2020年以降)
    if ($year >= 2000 && $year <= 2019 && $mon == 10) {
	$holidays{$mondays[1]} = '体育の日';
    } elsif ($year == 2020 && $mon == 7) {
	# 2020年はオリンピックにあわせて変更となりHappy Mondayではない
	$holidays{24} = 'スポーツの日';
    } elsif ($year == 2021 && $mon == 7) {
	# 2021年もオリンピックにあわせて変更となりHappy Mondayではない
	$holidays{23} = 'スポーツの日';
    } elsif ($year >= 2022 && $mon == 10) {
	# 2022年以降は第二月曜に戻る
	$holidays{$mondays[1]} = 'スポーツの日';
    }

    # 海の日追加
    if ($year >= 2003 && $mon == 7) {
	if    ($year == 2020) {$holidays{23} = '海の日';} # 2020年は7/23に変更
	elsif ($year == 2021) {$holidays{22} = '海の日';} # 2021年は7/22に変更
	else {
	    $holidays{$mondays[2]} = '海の日';
	}
    }

    if ($year >= 2003 && $mon == 9) {$holidays{$mondays[2]} = '敬老の日';}

    # 不定なもの
    if ($mon == 3) {$holidays{shunbun_day($year)} = '春分の日';}
    if ($mon == 9) {$holidays{shuubun_day($year)} = '秋分の日';}

    # 例外的なもの
    my $yymm = sprintf("%04d%02d", $year, $mon);
    if (exists $ExceptionalHoliday{$yymm}) {
	while (my ($day, $name) = each %{$ExceptionalHoliday{$yymm}}) {
	    $holidays{$day} = $name;
	}
    }

    return \%holidays;
}

sub next_year_mon {
    my ($year, $mon) = @_;

    $mon++;
    if ($mon > 12) {
	$year++;
	$mon = 1;
    }
    return ($year, $mon);
}

sub prev_year_mon {
    my ($year, $mon) = @_;

    $mon--;
    if ($mon < 1) {
	$year--;
	$mon = 12;
    }
    return ($year, $mon);
}

sub getHolidays {
    my ($year, $mon, $furikae) = @_;

    $year = int($year);
    $mon = int($mon);
    if ($mon < 1 || $mon > 12) {
	die('$mon argument is out of range.');
    }

    my $holidays = get_holidays($year, $mon);

    return if not defined $holidays;

    # 国民の休日
    if ($year >= 1986) {
	# 祝日に挟まれた平日を探す (祝日A - 平日B - 祝日C)

	# 休日検索用テーブル
	# 祝日Aと祝日Cが月をまたぐケースもあるので、前後の月の情報も結合する
	my %holidays_search_table = %$holidays;
	my $next_holidays = get_holidays(next_year_mon($year, $mon));
	if ($next_holidays) {
	    my $offset = days_in_month($year, $mon);
	    while (my ($d, $name) = each %$next_holidays) {
		$holidays_search_table{$d + $offset} = $name;
	    }
	}
	my $prev_holidays = get_holidays(prev_year_mon($year, $mon));
	if ($prev_holidays) {
	    my $offset = -days_in_month(prev_year_mon($year, $mon));
	    while (my ($d, $name) = each %$prev_holidays) {
		$holidays_search_table{$d + $offset} = $name;
	    }
	}

	foreach my $day (keys %$holidays) {
	    if ( exists $holidays_search_table{$day + 2} &&
		 !exists $holidays_search_table{$day + 1}) {
		my $wday = (localtime(timelocal(0, 0, 0,
						$day, $mon - 1, $year)))[6];
		# 祝日Aの時は平日Bはただの振り替え休日
		next if $wday == 0;

		# 平日Bが日曜の場合も国民の休日とはならない
		next if $wday == 6;

		$holidays->{$day + 1} = '国民の休日';
	    }
	}
    }

    # 振り替え休日も含める
    if ($furikae) {
	my $furikae_days = furikae_days($year, $mon, $holidays);

	while (my ($val, $name) = each %$furikae_days) {
	    $holidays->{$val} = $FurikaeStr;
	}
    }

    return $holidays;
}

my $Cache_holidays_Year  = 0;
my $Cache_holidays_Month = 0;
my $Cache_holidays;

sub isHoliday {
    my ($year, $mon, $day, $furikae) = @_;

    $year = int($year);
    $mon = int($mon);
    $day = int($day);

    if ($mon < 1 || $mon > 12) {
	die('$mon argument is out of range.');
    }

    my $holidays;

    if ($year == $Cache_holidays_Year &&
	$mon  == $Cache_holidays_Month) {
	$holidays = $Cache_holidays;	# From Cache
    } else {
	$holidays = getHolidays($year, $mon, 1);
	return if not defined $holidays;
	# Cache
	$Cache_holidays = $holidays;
	$Cache_holidays_Year  = $year;
	$Cache_holidays_Month = $mon;
    }

    return if !exists $holidays->{$day};

    return if (!$furikae && $holidays->{$day} eq $FurikaeStr);

    return $holidays->{$day};
}

1;
__END__

=head1 NAME

Calendar::Japanese::Holiday - Japanese holidays in calender

=head1 SYNOPSIS

  use Calendar::Japanese::Holiday;

  # Getting a list of holidays
  $holidays = getHolidays(2008, 5);
  $holidays = getHolidays(2008, 5, 1);

  # Examining whether it is holiday or not.
  $name = isHoliday(2007, 5, 5);

=head1 DESCRIPTION

This module treats holidays information in Japanese calendar.
The list of holidays can be acquired, and you can examine whether
a day is holiday or not. You can acquire the holiday name too.

=head1 FUNCTIONS

=over 5

=item getHolidays($year, $month [, $furikae])

Returns a hash reference that has holidays in $year/$month.
Returns empty hash reference if no holidays.
It returns substitute holidays too if $furikae is true.
$furikae is false when $furikae is omitted.
$year is supported after 1948. A undef is returned if error ocucred.

 # Case 1 - $furikae is omitted
 $holidays = getHolidays(2008, 5);

 Return:
 $holidays = {
          '4' => "\x{307f}\x{3069}\x{308a}\x{306e}\x{65e5}",  # Midori-no-hi
          '3' => "\x{61b2}\x{6cd5}\x{8a18}\x{5ff5}\x{65e5}",  # Kenpou-Kinenbi
          '5' => "\x{3053}\x{3069}\x{3082}\x{306e}\x{65e5}"   # Kodomo-no-hi
        };

 # Case 2 - $furikae is true
 $holidays = getHolidays(2008, 5, 1);

 Return:
 $holidays = {
          '6' => "\x{632f}\x{66ff}",                          # Furikae
          '4' => "\x{307f}\x{3069}\x{308a}\x{306e}\x{65e5}",  # Midori-no-hi
          '3' => "\x{61b2}\x{6cd5}\x{8a18}\x{5ff5}\x{65e5}",  # Kenpou-Kinenbi
          '5' => "\x{3053}\x{3069}\x{3082}\x{306e}\x{65e5}"   # Kodomo-no-hi
        };

 # Case 3 - no holidays
 $holidays = getHolidays(2008, 6);

 Return:
 $holidays = {};

=item isHoliday($year, $month, $day [, $furikae])

Returns holiday name.
Returns undef if $year/$month/$day is not holiday.
$furikae is same as getHolidays().

 $name = isHoliday(2007, 5, 5);
 $name is "\x{3053}\x{3069}\x{3082}\x{306e}\x{65e5}" Kodomo-no-hi

=back

=head1 SEE ALSO

http://wiki.bit-hive.com/tomizoo/pg/Perl%20%BD%CB%C6%FC%CC%BE%A4%CE%BC%E8%C6%C0

(In Japanese document)

=head1 AUTHOR

Kazuyoshi Tomita, E<lt>kztomita@bit-hive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kazuyoshi Tomita

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
