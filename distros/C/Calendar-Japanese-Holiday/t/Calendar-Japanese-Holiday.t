#########################

use utf8;

use Test::More tests => 74;
BEGIN { use_ok('Calendar::Japanese::Holiday') };

#########################

sub cmpHash {
    my ($h1, $h2) = @_;

    return if int(keys(%$h1)) != int(keys(%$h2));

    while (my ($key, $val) = each %$h1) {
	return if !exists $h2->{$key};

	return if $h2->{$key} ne $val;
    }

    return 1;
}

sub checkHoliday {
    my ($year0, $year1, $mon, $day, $val) = @_;

    for my $year ($year0 .. $year1) {
	my $name = isHoliday($year, $mon, $day);
	$name ||= '';
	return if $name ne $val;
    }

    return 1;
}

my $Shunbun_Shuubun_List = {2000 => [20, 23],
			    2001 => [20, 23],
			    2002 => [21, 23],
			    2003 => [21, 23],
			    2004 => [20, 23],
			    2005 => [20, 23],
			    2006 => [21, 23],
			    2007 => [21, 23],
			    2008 => [20, 23],
			    2009 => [20, 23],
			    2010 => [21, 23],
			    2011 => [21, 23],
			    2012 => [20, 22],
			    2013 => [20, 23],
			    2014 => [21, 23],
			    2015 => [21, 23],
			    2016 => [20, 22],
			    2017 => [20, 23],
			    2018 => [21, 23],
			    2019 => [21, 23],
			    2020 => [20, 22],
			    2021 => [20, 23],
			    2022 => [21, 23],
			    2023 => [21, 23],
			    2024 => [20, 22],
			    2025 => [20, 23],
			    2026 => [20, 23],
			    2027 => [21, 23],
			    2028 => [20, 22],
			    2029 => [20, 23],
			    2030 => [20, 23],
			   };

sub checkShunbunShuubun {

    while (my ($year, $days) = each %$Shunbun_Shuubun_List) {
	return if (isHoliday($year, 3, $days->[0]) ne '春分の日');

	return if (isHoliday($year, 9, $days->[1]) ne '秋分の日');
    }
    return 1;
}

#
# Test for getHolidays()
#
ok(cmpHash(getHolidays(2007, 11),
	   {3  => '文化の日',
	    23 => '勤労感謝の日'}),
   "getHolidays");

# HappyMonday、春分の日、秋分の日
ok(cmpHash(getHolidays(2007, 3),
	   {21 => '春分の日'}),
   "getHolidays - HappyMonday - Shunbun");

ok(cmpHash(getHolidays(2007, 1),
	   {1 => '元日',
	    8 => '成人の日'}),
   "getHolidays - HappyMonday - Seijin");

ok(cmpHash(getHolidays(2007, 7),
	   {16 => '海の日'}),
   "getHolidays - HappyMonday - Umi");

ok(cmpHash(getHolidays(2007, 9),
	   {17 => '敬老の日',
	    23 => '秋分の日'}),
   "getHolidays - HappyMonday - Keirou, Shuubun");

ok(cmpHash(getHolidays(2007, 10),
	   {8 => '体育の日'}),
   "getHolidays - HappyMonday - Taiiku");

# HappyMonday適用前では従来の値が表示されること
ok(cmpHash(getHolidays(1999, 1),
	   {1  => '元日',
	    15 => '成人の日'}),
   "getHolidays - !HappyMonday - Seijin");

ok(cmpHash(getHolidays(2002, 7),
	   {20 => '海の日'}),
   "getHolidays - !HappyMonday - Umi");

ok(cmpHash(getHolidays(2002, 9),
	   {15 => '敬老の日',
	    23 => '秋分の日'}),
   "getHolidays - !HappyMonday - Keirou, Shuubun");

ok(cmpHash(getHolidays(1999, 10),
	   {10 => '体育の日'}),
   "getHolidays - !HappyMonday - Taiiku");

#
# 振替休日処理
#

# 振り替え休日は取得しない
ok(cmpHash(getHolidays(2007, 9),
	   {17 => '敬老の日',
	    23 => '秋分の日'}),
   "getHolidays - furikae - FALSE");

# 振り替え休日も取得
ok(cmpHash(getHolidays(2007, 9, 1),
	   {17 => '敬老の日',
	    23 => '秋分の日',
	    24 => '振替'}),
   "getHolidays - furikae - TRUE");

# 月曜以外の振り替え休日 (2007年以降)
ok(cmpHash(getHolidays(2008, 5, 1),
	   {3 => '憲法記念日',
	    4 => 'みどりの日',
	    5 => 'こどもの日',
	    6 => '振替'}),
   "getHolidays - Substitute holiday other than Monday (2007-)");

#
# 国民の休日処理のテスト
#
ok(cmpHash(getHolidays(2006, 5, 1),
	   {3 => '憲法記念日',
	    4 => '国民の休日',
	    5 => 'こどもの日'}),
   "getHolidays - Kokumin-no-hi");

# 制定前
ok(cmpHash(getHolidays(1980, 5, 1),
	   {3 => '憲法記念日',
	    5 => 'こどもの日'}),
   "getHolidays - Before enacting Kokumin-no-hi");

# 5/4が日曜日で国民の休日ではない場合
ok(cmpHash(getHolidays(1986, 5, 1),
	   {3 => '憲法記念日',
	    5 => 'こどもの日'}),
   "getHolidays - Sunday > Kokumin-no-hi");

# 3日が日曜で4日が国民の休日ではなく振り替え休日になる場合
ok(cmpHash(getHolidays(1998, 5, 1),
	   {3 => '憲法記念日',
	    4 => '振替',
	    5 => 'こどもの日'}),
   "getHolidays - Furikae > Kokumin-no-hi");

# 2009年は9月にも国民の休日が発生する
ok(cmpHash(getHolidays(2009, 9, 1),
	   {21 => '敬老の日',
	    22 => '国民の休日',
	    23 => '秋分の日'}),
   "getHolidays - Kokumin-no-hi in september (2009)");

# 2019年4,5月分の処理(4/30は判定が月をまたぐケース)
ok(cmpHash(getHolidays(2019, 4, 1),
	   {29 => '昭和の日',
	    30 => '国民の休日'}),
   "getHolidays - Kokumin-no-hi in 2019.4");
ok(cmpHash(getHolidays(2019, 5, 1),
	   {1 => '天皇の即位の日',
	    2 => '国民の休日',
	    3 => '憲法記念日',
	    4 => 'みどりの日',
	    5 => 'こどもの日',
	    6 => '振替'}),
   "getHolidays - Kokumin-no-hi in 2019.5");


#
# Test for isHoliday()
#

my $ST = 1948;	# サポート開始年
my $ED = 2030;

ok(checkHoliday(1949,  $ED, 1,  1, '元日'),         'Ganjitsu');

ok(checkHoliday(1949, 1999, 1, 15, '成人の日'),     'Seijin(-1999)');
ok(checkHoliday(2000,  $ED, 1, 15, ''),             'Seijin(2000- !Happy Monday)');
ok(checkHoliday(2007, 2007, 1,  8, '成人の日'),     'Seijin(2007 Happy Monday)');

ok(checkHoliday( $ST, 1966, 2, 11, ''),             'KenkokuKinen(-1966)');
ok(checkHoliday(1967,  $ED, 2, 11, '建国記念の日'), 'KenkokuKinen(1967-)');

ok(checkHoliday( $ST, 1985, 5,  4, ''),             'Kokumin(-1985)');
# 5/4はかならず国民の休日となるとは限らない
ok(checkHoliday(1986, 1986, 5,  4, ''),             'Kokumin(1986)'); # 日曜
ok(checkHoliday(1987, 1987, 5,  4, ''),             'Kokumin(1987)'); # 振替
ok(checkHoliday(1988, 1988, 5,  4, '国民の休日'),   'Kokumin(1988)'); # 初回
ok(checkHoliday(2006, 2006, 5,  4, '国民の休日'),   'Kokumin(2006)'); # 最後

ok(checkHoliday(1989, 2006, 4, 29, 'みどりの日'),   'Midori(1989-2006)');
ok(checkHoliday(2007,  $ED, 5,  4, 'みどりの日'),   'Midori(2007-)');
ok(checkHoliday(2007,  $ED, 4, 29, '昭和の日'),     'Shouwai(2007-)');

ok(checkHoliday(1949, 1988, 4, 29, '天皇誕生日'),   'TennouTanjoubi(-1988)');
ok(checkHoliday(1989, 2018,12, 23, '天皇誕生日'),   'TennouTanjoubi(1989-2018)');
ok(checkHoliday(2019, 2019,12, 23, ''),             'TennouTanjoubi(2019)');
ok(checkHoliday(2020,  $ED, 2, 23, '天皇誕生日'),   'TennouTanjoubi(2020-)');

ok(checkHoliday(1949,  $ED, 5,  3, '憲法記念日'),   'Kenpou');

ok(checkHoliday(1949,  $ED, 5,  5, 'こどもの日'),   'Kodomo');

ok(checkHoliday( $ST, 1995, 7, 20, ''),             'Umi(-1995)');
ok(checkHoliday(1996, 2002, 7, 20, '海の日'),       'Umi(1996-2002)');
ok(checkHoliday(2003, 2003, 7, 20, ''),             'Umi(2003 !Happy Monday)');
ok(checkHoliday(2007, 2007, 7, 16, '海の日'),       'Umi(2007 Happy Monday)');
ok(checkHoliday(2019, 2019, 7, 15, '海の日'),       'Umi(2019 Happy Monday)');
ok(checkHoliday(2020, 2020, 7, 23, '海の日'),       'Umi(2020 olympic)');
ok(checkHoliday(2021, 2021, 7, 19, '海の日'),       'Umi(2021 Happy Monday)');

ok(checkHoliday( $ST, 1965, 9, 15, ''),             'Keirou(-1965)');
ok(checkHoliday(1966, 2002, 9, 15, '敬老の日'),     'Keirou(1966-2002)');
# 2003年は第3月曜日がたまたま15日なので2004年でチェック
ok(checkHoliday(2004, 2004, 9, 15, ''),             'Keirou(2004 !Happy Monday)');
ok(checkHoliday(2007, 2007, 9, 17, '敬老の日'),     'Keirou(2007 Happy Monday)');

ok(checkHoliday( $ST, 1965,10, 10, ''),             'Taiiku(-1965)');
ok(checkHoliday(1966, 1999,10, 10, '体育の日'),     'Taiiku(1966-1999)');
ok(checkHoliday(2000, 2000,10, 10, ''),             'Taiiku(2000 !Happy Monday)');
ok(checkHoliday(2007, 2007,10,  8, '体育の日'),     'Taiiku(2007 Happy Monday)');
ok(checkHoliday(2019, 2019,10, 14, '体育の日'),     'Taiiku(2019 Happy Monday)');
ok(checkHoliday(2020, 2020, 7, 24, 'スポーツの日'), 'Taiiku(2020 olympic)');
ok(checkHoliday(2021, 2021,10, 11, 'スポーツの日'), 'Taiiku(2021 olympic)');

ok(checkHoliday( $ST,  $ED,11,  3, '文化の日'),     'Bunka');

ok(checkHoliday( $ST,  $ED,11, 23, '勤労感謝の日'), 'KinrouKansha');

ok(checkHoliday(1959, 1959, 4, 10, '皇太子明仁親王の結婚の儀'), 'Exceptional');
ok(checkHoliday(1989, 1989, 2, 24, '昭和天皇の大喪の礼'),       'Exceptional');
ok(checkHoliday(1990, 1990,11, 12, '即位礼正殿の儀'),           'Exceptional');
ok(checkHoliday(1993, 1993, 6,  9, '皇太子徳仁親王の結婚の儀'), 'Exceptional');
ok(checkHoliday(2019, 2019, 5,  1, '天皇の即位の日'), 'Exceptional');
ok(checkHoliday(2019, 2019,10, 22, '即位礼正殿の儀の行われる日'), 'Exceptional');

ok(checkHoliday( $ST, 2015, 8, 11, ''),             'Yama(-2015)');
ok(checkHoliday(2016, 2019, 8, 11, '山の日'),       'Yama(2016-2019)');
ok(checkHoliday(2020, 2020, 8, 10, '山の日'),       'Yama(2020)');
ok(checkHoliday(2021,  $ED, 8, 11, '山の日'),       'Yama(2016-2021)');

ok(checkShunbunShuubun(), 'Shunbun/Shuubun');

ok(!isHoliday(2007, 9, 24),                         'Furikae (FALSE)');
ok(isHoliday(2007, 9, 24, 1) eq '振替',             'Furikae (TRUE)');

