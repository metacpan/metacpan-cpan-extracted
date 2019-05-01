use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# varcols
my $col = "col1";
test_select_sql {
	tab->$col == 42;
} "varcol1",
"select * from tab t01 where t01.col1 = 42",
[];
test_select_sql {
	my $t : tab;
	$t->$col == 42;
} "varcol2",
"select * from tab t01 where t01.col1 = 42",
[];

test_select_sql {
	my $t : tab;
} "select with exec is no mistake",
"select * from tab t01",
[];

# update selfmod
test_update_sql {
	tab->col++;
	exec;
} "postinc",
"update tab set col = col + 1",
[];
test_update_sql {
	++tab->col;
	exec;
} "preinc",
"update tab set col = col + 1",
[];
test_update_sql {
	tab->col--;
	exec;
} "postdec",
"update tab set col = col - 1",
[];
test_update_sql {
	--tab->col;
	exec;
} "predec",
"update tab set col = col - 1",
[];

test_update_sql {
	tab->col += 2;
	exec;
} "+= 2",
"update tab set col = col + 2",
[];
test_update_sql {
	tab->col -= 2;
	exec;
} "-= 2",
"update tab set col = col - 2",
[];
test_update_sql {
	tab->col *= 2;
	exec;
} "*= 2",
"update tab set col = col * 2",
[];
test_update_sql {
	tab->col /= 2;
	exec;
} "/= 2",
"update tab set col = col / 2",
[];
test_update_sql {
	tab->col .= "2";
	exec;
} ".= 2",
"update tab set col = col || ?",
["2"];

test_bad_select { tbl->id++; } "selfmod in select 1", qr/self-modifications are not understood/;
test_bad_select { tbl->id += 2; } "selfmod in select 2", qr/self-modifications are not understood/;

test_bad_update { tbl->id++ - 5 } "bad selfmod 1", qr/cannot reconstruct term/;
test_bad_update { 4 + (tbl->id += 4) } "bad selfmod 2", qr/self-modifications inside an expression is illegal/;


done_testing;
