package App::week::colors;

use strict;
use warnings;

1;

__DATA__

option --mono \
	--cm MONTH=WEEK=L00/L19 \
	--cm DAYS=L00/L21 \
	--cm THISMONTH=THISWEEK=L25/L04 \
	--cm THISDAYS=L25/L08 \
	--cm THISDAY=L01/L25 \
	--cm FRAME=L00/L23

option --green \
	--cm MONTH=DAYS=L05/242 \
	--cm FRAME=*WEEK=L05/353 \
	--cm THISDAY=533/131 \
	--cm THISMONTH=THISDAYS=555/131

option --lavender \
	--cm MONTH=DAYS=L05/335 \
	--cm FRAME=*WEEK=L05/445 \
	--cm THISDAY=522/113 \
	--cm THISMONTH=THISDAYS=555/113

define <FG> L23
option --lavender-rev \
	--cm MONTH=DAYS=<FG>/113 \
	--cm FRAME=*WEEK=<FG>/223 \
	--cm THISDAY=<FG>/113 \
	--cm THISMONTH=THISDAYS=<FG>/001

define C1 #a8d8ea
define C2 #aa96da
define C3 #fcbad3
define C4 #ffffd2
define C5 #ffffff
option --pastel \
	--cm FRAME=*WEEK=C2/C4 \
	--cm MONTH=DAYS=C5/C3 \
	--cm THISMONTH=THISDAYS=THISDAY=C5/C2 \
	--cm THISDAY=+S
