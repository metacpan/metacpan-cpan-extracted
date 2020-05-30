package App::week::teams;
1;
__DATA__

option --termcolor::bg -Mtermcolor::bg(light=--$<shift>,dark=--$<shift>-rev)
option --team --termcolor::bg $<copy(0,1)>

define 赤 400
define 黄 550
define 黒 L00
define 白 L25

######################################################################

define T黄 #FFE201
option --tigers \
	--cm YEAR=黒 \
	--cm *MONTH=*DAYS=黄/黒 \
	--cm FRAME=*WEEK=赤/T黄 \
	--cm THISDAY=T黄/黒,THISDAYS=T黄/赤 \
	$<ignore>

option --tigers-rev --tigers

######################################################################

option --lions --lions3
option --lions-rev --lions3-rev

define L青 #2C9FE8
define L緑 (68,226,65)
option --lions2 \
	--cm YEAR=黒 \
	--cm *MONTH=*DAYS=白/L緑 \
	--cm FRAME=*WEEK=黒/L青 \
	--cm THISDAY=赤/白,THISDAYS=白/赤 \
	$<ignore>

option --lions2-rev --lions2

define L赤 #AA000A
define L紺 #122961
define L共通 THISDAY=D;L赤/白,THISMONTH=THISDAYS=白/L赤
option --lions3 \
	--cm YEAR=黒 \
	--cm *MONTH=*DAYS=L紺/白 \
	--cm FRAME=*WEEK=白/L紺 \
	--cm THISDAY=D;L赤/白,THISMONTH=THISDAYS=白/L赤 \
	--cm L共通 \
	$<ignore>

option --lions3-rev --lions3 \
	--cm *=+S --cm L共通

######################################################################

define G橙 #F97709
option --giants \
	--cm YEAR= \
	--cm FRAME=*WEEK=白/G橙,THISWEEK=+黒 \
	--cm *DAYS=黒/白 \
	--cm *MONTH=白/黒 \
	--cm THISDAY=THISDAYS=G橙/黒,THISDAY=+S \
	$<ignore>

option --giants-rev --giants
