package App::week::npb;

use strict;
use warnings;
use utf8;

1;

__DATA__

define 赤 400
define 黄 550
define 黒 L00
define 白 L25

######################################################################

define 虎黄 #FFE201
option --tigers \
	--stripe \
	--cm *MONTH=*DAYS=黄/黒 \
	--cm FRAME=*WEEK=赤/虎黄 \
	--cm THISDAY=虎黄/黒,THISDAYS=虎黄/赤 \
	$<ignore>

option --tigers-rev --tigers

######################################################################

option --lions --lions3
option --lions-rev --lions3-rev

define 獅青 #2C9FE8
define 獅緑 (68,226,65)
option --lions2 \
	--cm *MONTH=*DAYS=白/獅緑 \
	--cm FRAME=*WEEK=黒/獅青 \
	--cm THISDAY=赤/白,THISDAYS=白/赤 \
	$<ignore>

option --lions2-rev --lions2

define 獅赤 #AA000A
define 獅紺 #102961
define 獅共通 THISDAY=D;獅赤/白,THISMONTH=THISDAYS=白/獅赤
option --lions3 \
	--cm *MONTH=*DAYS=獅紺/白 \
	--cm FRAME=*WEEK=白/獅紺 \
	--cm 獅共通 \
	$<ignore>

option --lions3-rev --lions3 \
	--cm *MONTH=*DAYS=FRAME=*WEEK=+S --cm 獅共通

######################################################################

define 巨橙 #F97709
option --giants \
	--cm FRAME=*WEEK=白/巨橙,THISWEEK=+黒 \
	--cm *DAYS=黒/白 \
	--cm *MONTH=白/黒 \
	--cm THISDAY=THISDAYS=巨橙/黒,THISDAY=+S \
	$<ignore>

option --giants-rev --giants
