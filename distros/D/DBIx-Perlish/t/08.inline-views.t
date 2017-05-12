# $Id$
use warnings;
use strict;
use Test::More tests => 9;
use DBIx::Perlish qw/:all/;
use t::test_utils;

test_select_sql {
	my $a : tab1;
	my $b : table = db_fetch {
		my $c : tab2;
	};
} "stupid inline view",
"select * from tab1 t01, (select * from tab2 s01_t01) t02",
[];

test_select_sql {
	my $a : tab1;
	my $b : table = db_fetch {
		my $c : tab2;
		my $d : tab3;

		$c->x == $d->y;
		return $c->i, $d->j;
	};
	$b->i == $a->j;
	return $a->n, $b->j;
} "more realistic inline view",
"select t01.n, t02.j from tab1 t01, (select s01_t01.i, s01_t02.j from tab2 s01_t01, tab3 s01_t02 where s01_t01.x = s01_t02.y) t02 where t02.i = t01.j",
[];

test_select_sql {
	my $t : dba_tab_columns;
	my $x : table = db_fetch {
		my $u : user_cons_columns;
		my $c : user_cons_columns;
		my $uc : user_constraints;

		$u->constraint_name == $uc->r_constraint_name;
		$c->constraint_name == $uc->constraint_name;
		$uc->constraint_type == "R";

		return reference => "$u->table_name.$u->column_name",
			   ctn => $c->table_name, ccn => $c->column_name;
	};

	join $t < $x => db_fetch {
		$x->ctn == $t->table_name;
		$x->ccn == $t->column_name;
	};

	$t->table_name == 'PRODUCT_TREE';

	return $t->column_name, $t->data_length, $t->data_type,
		   $x->reference;
} "horrid inline view with joins",
"select t01.column_name, t01.data_length, t01.data_type, t02.reference from dba_tab_columns t01 left outer join (select (s01_t01.table_name || ? || s01_t01.column_name) as reference, s01_t02.table_name as ctn, s01_t02.column_name as ccn from user_cons_columns s01_t01, user_cons_columns s01_t02, user_constraints s01_t03 where s01_t01.constraint_name = s01_t03.r_constraint_name and s01_t02.constraint_name = s01_t03.constraint_name and s01_t03.constraint_type = ?) t02 on t02.ctn = t01.table_name and t02.ccn = t01.column_name where t01.table_name = ?",
[qw(. R PRODUCT_TREE)];
