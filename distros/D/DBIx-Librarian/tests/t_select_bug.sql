select1	reporter,
	version,
	product
from	BUG
where	bugid = :bugid
#  and	(:nothing is null)
;
