package App::week::olympic;

use strict;
use warnings;
use utf8;

1;

__DATA__

# 参考: https://ayaito.net/webtips/color_code/5166/

define 白 #fff
define 黒 #000

define リング青　#0081c8
define リング黄　#fcb131
define リング黒　#000000
define リング緑　#00a651
define リング赤　#ee334e

define ロゴ赤　#aa272f
define ロゴ青　#00549f
define ロゴ緑　#008542

define エンブレム青　#002063
define エンブレム赤　#ee334e

# 紅
define 紅1 #b42d3b # rgb(180, 45, 59)
define 紅2 #cd3135 # rgb(205, 49, 53)
define 紅3 #c12e4b # rgb(193, 46, 75)
define 紅4 #ed3a71 # rgb(237, 58, 113)

# 藍
define 藍1 #234b86 # rgb(35, 75, 134)
define 藍2 #135995 # rgb(19, 89, 149)
define 藍3 #0093d3 # rgb(0, 147, 211)
define 藍4 #7acded # rgb(122, 205, 237)
define 藍5 #c2bebb # rgb(194, 190, 187)

# 桜
define 桜1 #e1473d # rgb(225, 71, 61)
define 桜2 #f7aab2 # rgb(247, 170, 178)
define 桜3 #ef6072 # rgb(239, 96, 114)
define 桜4 #f0839a # rgb(240, 131, 154)

# 藤
define 藤1 #ba2b56 # rgb(186, 43, 86)
define 藤2 #e52980 # rgb(229, 41, 128)
define 藤3 #952b6d # rgb(149, 43, 109)
define 藤4 #bc2a7b # rgb(188, 42, 123)
define 藤5 #f59cb8 # rgb(245, 156, 184)

# 松葉
define 松葉1 #006652 # rgb(0, 102, 82)
define 松葉2 #007e8d # rgb(0, 126, 141)
define 松葉3 #007184 # rgb(0, 113, 132)
define 松葉4 #03904b # rgb(3, 144, 75)
define 松葉5 #67b255 # rgb(103, 178, 85)

define 2020金 #cfb077 # rgb(207, 176, 119)
define 1964赤 #cc0000 # rgb(204,0,0)
define 1964金 #a57b56 # rgb(165,123,86)

option --olympic-dow \
	--cm DOW_SU=白/リング赤 \
	--cm DOW_MO=白/リング青 \
	--cm DOW_TU=白/リング黄 \
	--cm DOW_WE=白/リング黒 \
	--cm DOW_TH=白/リング緑 \
	--cm DOW_FR=白/リング赤 \
	--cm DOW_SA=白/リング赤

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

option --gold-frame --cm FRAME=+/2020金

option --tokyo2020-gold     --tokyo2020
option --tokyo2020-gold-rev --tokyo2020-rev --gold-frame
