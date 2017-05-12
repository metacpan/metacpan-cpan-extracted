select1	bugid,
	product,
	assigned_to,
	version
from	BUG
where	groupset = :groupset;
