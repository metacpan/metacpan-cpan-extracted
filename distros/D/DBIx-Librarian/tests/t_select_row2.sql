select1	bugid "foo.bugid",
	product "foo.prodnum",
	assigned_to "foo.assignee",
	version "foo.version"
from	BUG
where	groupset = :groupset;
