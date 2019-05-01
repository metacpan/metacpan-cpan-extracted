use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

my $vart = 'table1';
my $self = { table => 'table1', id => 42,
	h1 => {
		v  => 42,
		h2 => { v => 42, h3 => { v => 42 } },
	},
};
my %self = ( table => 'table1', id => 42,
	h1 => {
		v  => 42,
		h2 => { v => 42, h3 => { v => 42 } },
	},
);
our $GLOBAL = 42;
our %GLOBAL_HASH; $GLOBAL_HASH{hash} = 42; $GLOBAL_HASH{l1}{l2} = 42;
test_select_sql {
	table: my $t1 = $vart;
	my $t2 : table2;
	$t1->id == $t2->table1_id;
	return $t1, $t2->name;
} "vartable label 1",
"select t01.*, t02.name from table1 t01, table2 t02 where t01.id = t02.table1_id",
[];

test_select_sql {
	table: my $t1 = $self{table};
	my $t2 : table2;
	$t1->id == $t2->table1_id;
	return $t1, $t2->name;
} "vartable label 2",
"select t01.*, t02.name from table1 t01, table2 t02 where t01.id = t02.table1_id",
[];

test_select_sql {
	table: my $t1 = $self->{table};
	my $t2 : table2;
	$t1->id == $t2->table1_id;
	return $t1, $t2->name;
} "vartable label 3",
"select t01.*, t02.name from table1 t01, table2 t02 where t01.id = t02.table1_id",
[];

test_select_sql {
	my $t : table1;
	$t->id == $self->{id};
} "hashref",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self{id};
} "hashelement",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $GLOBAL;
} "global scalar",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $GLOBAL_HASH{hash};
} "global hash",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $GLOBAL_HASH{l1}{l2};
} "global hash multilevel",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self->{h1}{v};
} "hashref l2",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self{h1}{v};
} "hashelement l2",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self->{h1}{h2}{v};
} "hashref l3",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self{h1}{h2}{v};
} "hashelement l3",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self->{h1}{h2}{h3}{v};
} "hashref l4",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table1;
	$t->id == $self{h1}{h2}{h3}{v};
} "hashelement l4",
"select * from table1 t01 where t01.id = ?",
[42];

test_select_sql {
	my $t : table = $self->{table};
} "vartable attribute",
"select * from table1 t01",
[];

our $glotab = "prod.table1";
test_select_sql {
	my $t : table = $glotab;
} "vartable attribute in a global",
"select * from prod.table1 t01",
[];

my $mytab = "prod.table1";
test_select_sql {
	my $t : table = $mytab;
} "vartable attribute in a my",
"select * from prod.table1 t01",
[];

test_select_sql {
	my $t : table = "prod.table1";
} "vartable attribute in a constant",
"select * from prod.table1 t01",
[];

test_select_sql {
	my $t : table(prod.table1);
} "vartable attribute in an attribute argument",
"select * from prod.table1 t01",
[];

test_select_sql {
	my $t : prod(table1);
} "schema attribute with table name as an argument",
"select * from prod.table1 t01",
[];

# conditional post-if
my $type = "ICBM";
test_select_sql {
	my $t : products;
	$t->type eq $type if $type;
} "conditional post-if, true",
"select * from products t01 where t01.type = ?",
["ICBM"];
$type = "";
test_select_sql {
	my $t : products;
	$t->type eq $type if $type;
} "conditional post-if, false",
"select * from products t01",
[];

# conditional real-if
$type = "ICBM";
test_select_sql {
	my $t : products;
	if ($type) {
		$t->type eq $type;
	}
} "conditional real-if, true",
"select * from products t01 where t01.type = ?",
["ICBM"];
$type = "";
test_select_sql {
	my $t : products;
	if ($type) {
		$t->type eq $type;
	}
} "conditional real-if, false",
"select * from products t01",
[];

my $limit = undef;
my $days = 86;
test_select_sql {
	my $e : event_log;
	$e->time < sql("localtimestamp - interval '$days days'");
	return $e->id, $e->circuit_number, time => sql("date_trunc('second', time)"), $e->type;
	if ($limit) {
		last unless 0..$limit;
	}
} "conditional real-if with limit, false",
"select t01.id, t01.circuit_number, date_trunc('second', time) as time, t01.type from event_log t01 where t01.time < localtimestamp - interval '86 days'",
[];

$limit = 5;
test_select_sql {
	my $e : event_log;
	$e->time < sql("localtimestamp - interval '86 days'");
	return $e->id, $e->circuit_number, time => sql("date_trunc('second', time)"), $e->type;
	if ($limit) {
		last unless 0..$limit;
	}
} "conditional real-if with limit, true",
"select t01.id, t01.circuit_number, date_trunc('second', time) as time, t01.type from event_log t01 where t01.time < localtimestamp - interval '86 days' limit 6",
[];

# <- @array
my @ary = (1,2,3);
test_select_sql {
	tab->id  <-  @ary;
} "in array",
"select * from tab t01 where t01.id in (?,?,?)",
[@ary];

# <- @$array
my $ary = [1,2,3];
test_select_sql {
	tab->id  <-  @$ary;
} "in array",
"select * from tab t01 where t01.id in (?,?,?)",
[@$ary];

test_select_sql {
	!tab->id  <-  @ary;
} "in arrayref",
"select * from tab t01 where t01.id not in (?,?,?)",
[@ary];

test_select_sql {
	!tab->id  <-  [1,2,3];
} "in list",
"select * from tab t01 where t01.id not in (1,2,3)",
[];

test_select_sql {
	!tab->id  <-  [1,$self{id},3];
} "in list vals",
"select * from tab t01 where t01.id not in (1,?,3)",
[42];

test_select_sql {
	!tab->id  <-  [1,$self->{id},3];
} "in list vals",
"select * from tab t01 where t01.id not in (1,?,3)",
[42];

test_update_sql {
	tab->col += $self->{id} + 2;
	exec;
} "+= complex",
"update tab set col = col + (? + 2)",
[42];
test_update_sql {
	tab->col -= $self->{id} + 2;
	exec;
} "-= complex",
"update tab set col = col - (? + 2)",
[42];
test_update_sql {
	tab->col *= $self->{id} + 2;
	exec;
} "*= complex",
"update tab set col = col * (? + 2)",
[42];
test_update_sql {
	tab->col /= $self->{id} + 2;
	exec;
} "/= complex",
"update tab set col = col / (? + 2)",
[42];

my $h = { col1 => 42, col2 => 666 };
my %h = ( col1 => 42, col2 => 666 );
test_update_sql {
	my $t : tab;
 	$t = {%h};
	exec;
} "hash assignment 1",
[{sql => "update tab set col1 = ?, col2 = ?", values => [42,666]},
 {sql => "update tab set col2 = ?, col1 = ?", values => [666,42]}];
test_update_sql {
	my $t : tab;
 	$t = {%$h};
	exec;
} "hashref assignment 1",
[{sql => "update tab set col1 = ?, col2 = ?", values => [42,666]},
 {sql => "update tab set col2 = ?, col1 = ?", values => [666,42]}];
test_update_sql {
	my $t : tab;
 	$t = {%h, foobar => 2};
	exec;
} "hash assignment 2",
[{sql => "update tab set col1 = ?, col2 = ?, foobar = 2", values => [42,666]},
 {sql => "update tab set col1 = ?, foobar = 2, col2 = ?", values => [42,666]},
 {sql => "update tab set col2 = ?, col1 = ?, foobar = 2", values => [666,42]},
 {sql => "update tab set col2 = ?, foobar = 2, col1 = ?", values => [666,42]},
 {sql => "update tab set foobar = 2, col1 = ?, col2 = ?", values => [42,666]},
 {sql => "update tab set foobar = 2, col2 = ?, col1 = ?", values => [666,42]}];
test_update_sql {
	my $t : tab;
 	$t = {%$h, foobar => 2};
	exec;
} "hashref assignment 2",
[{sql => "update tab set col1 = ?, col2 = ?, foobar = 2", values => [42,666]},
 {sql => "update tab set col1 = ?, foobar = 2, col2 = ?", values => [42,666]},
 {sql => "update tab set col2 = ?, col1 = ?, foobar = 2", values => [666,42]},
 {sql => "update tab set col2 = ?, foobar = 2, col1 = ?", values => [666,42]},
 {sql => "update tab set foobar = 2, col1 = ?, col2 = ?", values => [42,666]},
 {sql => "update tab set foobar = 2, col2 = ?, col1 = ?", values => [666,42]}];


# union with the same var check
test_select_sql {
	{ t1->name == $vart } union { t2->name == $vart }
} "union with the same var",
"select * from t1 t01 where t01.name = ? union select * from t2 t01 where t01.name = ?",
["table1","table1"];

# conditional returns
test_select_sql {
	my $a : tab;
	return $a->smth, $a->with_id if $self->{id};
	return $a->smth              unless $self->{id};
} "conditional return, if true",
"select t01.smth, t01.with_id from tab t01",
[];
test_select_sql {
	my $a : tab;
	return $a->smth, $a->with_id if $self->{noid};
	return $a->smth              unless $self->{noid};
} "conditional return, unless false",
"select t01.smth from tab t01",
[];

# nonlocal padlists
sub foo
{
	my $me = shift;
	test_select_sql {
		my $t : table = $me->{table};
		!$t->id == 5;
	} "nonlocal padlist", "select * from tbl t01 where not t01.id = 5", [];
}
foo({ table => 'tbl' });

done_testing;
