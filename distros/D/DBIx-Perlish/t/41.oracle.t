use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# lowercasing case-independent like
$main::flavor = "oracle";

test_select_sql {
	tbl->id =~ /AbC/i
} "ilike emulation",
"select * from tbl t01 where lower(t01.id) like '%abc%'",
[];

# oracle's limit/offset
test_select_sql {
	tbl->id == 1;
	limit: 1
} "ilike emulation",
"select * from (select * from tbl t01 where t01.id = 1) where ROWNUM <= 1",
[];

test_select_sql {
	tbl->id == 1;
	last unless 2..3;
} "ilike emulation",
"select * from (select * from tbl t01 where t01.id = 1) where ROWNUM > 2 and ROWNUM <= 4",
[];

my $someid = 42;
test_select_sql {
	tbl->id  <- tablefunc($someid);
} "Ora: tablefunc IN subselect",
"select * from tbl t01 where t01.id in (select * from table(tablefunc(?)))",
[42];
test_select_sql {
	!tbl->id  <- tablefunc($someid);
} "Ora: tablefunc NOT IN subselect",
"select * from tbl t01 where t01.id not in (select * from table(tablefunc(?)))",
[42];
test_select_sql {
	my $p : table = tablefunc($someid);
	return $p;
} "ora: tableop",
"select t01.* from table(tablefunc(?)) t01",
[42];

# special handling of sysdate
test_select_sql {
	tab->foo == sysdate();
} "sysdate() is special",
"select * from tab t01 where t01.foo = sysdate",
[];

test_select_sql { return `xyz_seq.nextval` } "select from dual",
"select xyz_seq.nextval from dual", [];

done_testing;
