package App::week::teams;
1;
__DATA__

define 赤 400
define 黄 550
define 黒 L00
define 白 L25
option --tigers \
	--cm YEAR=黒 \
	--cm *MONTH=*DAYS=黄/黒 \
	--cm FRAME=*WEEK=赤/黄 \
	--cm THISDAY=黄/黒,THISDAYS=黄/赤 \
	$<move(0,0)>

define ブルー 035
define グリーン 020
option --lions \
	--cm YEAR=黒 \
	--cm *MONTH=*DAYS=白/グリーン \
	--cm FRAME=*WEEK=黒/ブルー \
	--cm THISDAY=赤/白,THISDAYS=白/赤 \
	$<move(0,0)>

define オレンジ 420
option --giants \
	--cm YEAR= \
	--cm FRAME=*WEEK=白/オレンジ,THISWEEK=+黒 \
	--cm *DAYS=黒/白 \
	--cm *MONTH=白/黒 \
	--cm THISDAY=THISDAYS=オレンジ/黒,THISDAY=+S \
	$<move(0,0)>
