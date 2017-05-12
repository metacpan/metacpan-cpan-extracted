# $Id$
use warnings;
use strict;
use Test::More tests => 46;
use DBIx::Perlish qw/:all/;
use t::test_utils;

test_select_sql {
	my $x : x;
	my $y : y;
	join $x * $y;
} "unconditional join",
"select * from x t01 cross join y t02",
[];

test_select_sql {
	my $x : x;
	my $y : y;
	join $x * $y => db_fetch {};
} "unconditional join 2",
"select * from x t01 cross join y t02",
[];

test_select_sql {
	my $x : x;
	my $y : y;
	join $x < $y => db_fetch { $x-> id > $y-> id };
} "conditional join",
"select * from x t01 left outer join y t02 on t01.id > t02.id",
[];

test_select_sql {
	my $x : x;
	my $y : y;
	my $z : z;
	$y->id == $z->y_id;
	join $x < $y => db_fetch { $x-> id > $y-> id };
	my $w : w;
	$x->id == $w->x_id;
} "funny join 1",
"select * from x t01 left outer join y t02 on t01.id > t02.id, z t03, w t04 where t02.id = t03.y_id and t01.id = t04.x_id",
[];

test_select_sql {
	my $w : w;
	my $z : z;
	my $x : x;
	my $y : y;
	$y->id == $z->y_id;
	join $x < $y => db_fetch { $x-> id > $y-> id };
	$x->id == $w->x_id;
} "funny join 2",
"select * from x t03 left outer join y t04 on t03.id > t04.id, w t01, z t02 where t04.id = t02.y_id and t03.id = t01.x_id",
[];

test_select_sql {
	my $w : w;
	my $x : x;
	my $y : y;
	my $z : z;
	$y->id == $z->y_id;
	join $x < $y => db_fetch { $x-> id > $y-> id };
	$x->id == $w->x_id;
} "funny join 3",
"select * from x t02 left outer join y t03 on t02.id > t03.id, w t01, z t04 where t03.id = t04.y_id and t02.id = t01.x_id",
[];

test_select_sql {
	my $x : x;
	my $y : y;
	join $x * $y <= db_fetch {};
} "inverse join",
"select * from x t01 cross join y t02",
[];

test_select_sql {
	my $w : w;
	my $x : x;
	my $y : y;
	my $z : z;
	$y->id == $z->y_id;
	join $x + $y <= db_fetch { $x-> id > $y-> id };
	$x->id == $w->x_id;
} "inverse join 2",
"select * from x t02 full outer join y t03 on t02.id > t03.id, w t01, z t04 where t03.id = t04.y_id and t02.id = t01.x_id",
[];

test_select_sql {
	my $x : x;
	my $y : y;
	join $x < $y => db_fetch { $x->blah == "hello" };
} "join with bound values",
"select * from x t01 left outer join y t02 on t01.blah = ?",
["hello"];

test_select_sql {
	my $x : x;
	my $y : y;
	$y->yy == "y";
	join $x < $y => db_fetch { $x->blah == "hello" };
} "join with bound values",
"select * from x t01 left outer join y t02 on t01.blah = ? where t02.yy = ?",
["hello", "y"];

test_select_sql {
	my $x : x;
	my $y : y;
	$y->yy == "y";
	join $x < $y => db_fetch { $x->blah == "hello" };
	$x->xx == "x";
} "join with bound values 2",
"select * from x t01 left outer join y t02 on t01.blah = ? where t02.yy = ? and t01.xx = ?",
["hello", "y", "x"];

test_select_sql {
	my $w : w;
	$w->w1 == "w1";
	$w->id  <-  db_fetch {
		my $x : x;
		my $y : y;
		$y->yy == "y";
		join $x < $y => db_fetch { $x->blah == "hello" };
		$x->xx == "x";
		return $x->toret;
	};
	$w->w2 == "w2";
} "complex join with bound values",
"select * from w t01 where t01.w1 = ? and t01.id in (select s01_t01.toret from x s01_t01 left outer join y s01_t02 on s01_t01.blah = ? where s01_t02.yy = ? and s01_t01.xx = ?) and t01.w2 = ?",
["w1", "hello", "y", "x", "w2"];


test_select_sql {
	my $s : sensors;
	my $z : zones;
	my $d : prod(datacenters);
	my $t : types;

	$t->name == "Temperature"; 
	$d->short_ref == 'eqx';
	join $s x $z => db_fetch { $s->id_zone == $z->id_zone };
	join $z x $d => db_fetch { $z->id_datacenter == $d->id_datacenter };
	join $s x $t => db_fetch { $s->id_type == $t->id_type };
	return $s, $z;
} "real life multiple join",
"select t01.*, t02.* from sensors t01 inner join zones t02 on t01.id_zone = t02.id_zone inner join prod.datacenters t03 on t02.id_datacenter = t03.id_datacenter inner join types t04 on t01.id_type = t04.id_type where t04.name = ? and t03.short_ref = ?",
["Temperature", "eqx"];

test_bad_select {
	my $a : taba;
	my $b : tabb;
	my $c : tabc;

	join $a x $b <= db_fetch { $a->id == $b->id };
	join $b x $c <= db_fetch { $b->id == $c->id };
	join $a x $c <= db_fetch { $a->id == $c->id };
} "strange join, prolly a bug",
qr/not sure what to do with repeated tables .*? in a join/;

test_select_sql {
	my $p : product_tree;
	my $m : product_mab_dsl;
	my $pt : product_type;
	my $pp : product_tree;
	my $ppt : product_type;
	my $sb : site_basic;
	my $eda : product_eda_adsl;

	join $p < $sb => db_fetch {
		$p->circuit_number == $sb->circuit_number;
	};

	join $pp < $eda => db_fetch {
		$pp->id == $eda->id;
	};
} "real life disjoint multiple join",
"select * from product_tree t01 left outer join site_basic t06 on t01.circuit_number = t06.circuit_number, product_tree t04 left outer join product_eda_adsl t07 on t04.id = t07.id, product_mab_dsl t02, product_type t03, product_type t05",
[];

test_select_sql {
	my $h : hosts;
	my $s : services;
	my $hs : host_service;
	join $hs * $s => db_fetch { $hs->id_service == $s->id_service };
	join $h x $s => db_fetch { $h->id_host == $s->id_host };
} "strange join, rearrange",
"select * from host_service t03 inner join services t02 on t03.id_service = t02.id_service inner join hosts t01 on t01.id_host = t02.id_host",
[];

test_select_sql {
	my $h : hosts;
	my $s : services;
	my $hs : host_service;
	join $hs < $s => db_fetch { $hs->id_service == $s->id_service };
	join $h < $s => db_fetch { $h->id_host == $s->id_host };
} "strange join, rearrange with swap",
"select * from host_service t03 left outer join services t02 on t03.id_service = t02.id_service right outer join hosts t01 on t01.id_host = t02.id_host",
[];

