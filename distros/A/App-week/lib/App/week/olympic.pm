package App::week::olympic;

use strict;
use warnings;
use utf8;

1;

__DATA__

# 参考: https://ayaito.net/webtips/color_code/5166/

define 白 #fff
define 黒 #000

# 五輪
define リング青　#0081c8
define リング黄　#fcb131
define リング黒　#000000
define リング緑　#00a651
define リング赤　#ee334e

# パラリンピック
define パラ赤　#aa272f
define パラ青　#00549f
define パラ緑　#008542

# tokyo 2020
define エンブレム青　#002063
define エンブレム赤　#ee334e

# 紅
define 紅1 #b42d3b
define 紅2 #cd3135
define 紅3 #c12e4b
define 紅4 #ed3a71

# 藍
define 藍1 #234b86
define 藍2 #135995
define 藍3 #0093d3
define 藍4 #7acded
define 藍5 #c2bebb

# 桜
define 桜1 #e1473d
define 桜2 #f7aab2
define 桜3 #ef6072
define 桜4 #f0839a

# 藤
define 藤1 #ba2b56
define 藤2 #e52980
define 藤3 #952b6d
define 藤4 #bc2a7b
define 藤5 #f59cb8

# 松葉
define 松葉1 #006652
define 松葉2 #007e8d
define 松葉3 #007184
define 松葉4 #03904b
define 松葉5 #67b255

define 2020金 #cfb077
define 1964赤 #cc0000
define 1964金 #a57b56

option --olympic-dow \
	--cm DOW_SU=白/エンブレム赤 \
	--cm DOW_MO=白/リング青 \
	--cm DOW_TU=白/リング黄 \
	--cm DOW_WE=白/リング黒 \
	--cm DOW_TH=白/リング緑 \
	--cm DOW_FR=白/リング赤 \
	--cm DOW_SA=白/エンブレム青 \
	--cm DOW_CW=白/エンブレム青

option --paralympic-dow --olympic-dow

option --olympic-dow-rev \
	--olympic-dow \
	--cm DOW_SU=DOW_SA=+S

expand --tokyo2020-common \
	--cm *MONTH=*DAYS=白/エンブレム青 \
	--cm WEEK=/エンブレム青

option --tokyo2020 \
	--tokyo2020-common \
	--olympic-dow \
	--cm FRAME=白/エンブレム赤 \
	--cm THISDAY=D;白/エンブレム赤,THISMONTH=THISDAYS=THISWEEK=エンブレム青/白

option --tokyo2020-rev \
	--tokyo2020-common \
	--olympic-dow-rev \
	--cm FRAME=エンブレム赤/白 \
	--cm THISDAY=D;エンブレム赤/白,THISMONTH=THISDAYS=THISWEEK=白/エンブレム赤

option --gold-frame --cm FRAME=/2020金

option --tokyo2020-gold     --tokyo2020     --gold-frame
option --tokyo2020-gold-rev --tokyo2020-rev --gold-frame

option --para2020 \
	--paralympic-dow \
	--cm FRAME=白/パラ青 \
	--cm DAYS=WEEK=パラ緑/白 \
	--cm *MONTH=黒/白 \
	--cm THIS*=白/パラ赤,THISDAY=+DS \
	--cm *DAYS=+I

option --para2020-rev --para2020
