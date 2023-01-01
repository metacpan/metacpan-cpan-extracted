use Test2::V0;
no warnings 'once';
use DBIx::Class::Schema;

my $ret= eval q{
	package test::Table4;
	use DBIx::Class::ResultDDL -V0;
	table 'table4';
	col c0 => integer, auto_inc;
	col c1 => varchar(50), null, default("foo");
	primary_key 'c0';
	1;
};
my $err= $@;
ok( $ret, 'eval Table4' ) or diag $err;

$ret= eval q{
	package test::Table5;
	use DBIx::Class::ResultDDL -V0;
	table 'table5';
	col c2 => integer;
	col c3 => varchar(50), null, default("foo");
	primary_key 'c2';
	
	belongs_to belong_table4 => 'test::Table4', { 'foreign.c0' => 'self.c2' };
	has_many   has_table4 => { c3 => 'Table4.c1' };
	rel_one    one_table4 => { 'Table4.c0' => 'c2' };
	rel_many   many_table4 => 'test::Table4', { 'foreign.c1' => 'self.c3' };
	1;
};
$err= $@;
ok( $ret, 'eval Table5 with relations' ) or diag $err;

subtest literal_sql_join => sub {
	my $ret= eval <<'PL';
	package test::Table6;
	use DBIx::Class::ResultDDL -V2;
	table 'table6';
	col id => integer;
	primary_key 'id';
	
	might_have double_id => 'LEFT JOIN Table6 ON Table6.id = self.id * 2';
	might_have half_id => 'INNER JOIN Table6 t6 ON t6.id * 2 = self.id';
	1;
PL
	$err= $@;
	ok( $ret, 'eval Table6 with literal sql' ) or diag $err;

	SKIP: {
		skip "Can't test query generation without DBD::SQLite", 2
			unless eval "require DBD::SQLite";

		my $db= DBIx::Class::Schema->connect("dbi:SQLite:memory",'','',{ RaiseError => 1, AutoCommit => 1 });
		$db->register_class(Table6 => 'test::Table6');
		my $q= $db->resultset('Table6')->search_rs(undef, { '+columns' => ['double_id.id'], join => ['double_id'] })->as_query;
		like( $$q->[0], qr/SELECT me.id, double_id.id FROM table6 me LEFT JOIN table6 double_id ON double_id.id = me.id \* 2/i,
			'query for double_id' );
		$q= $db->resultset('Table6')->search_rs(undef, { '+columns' => ['half_id.id'], join => ['half_id'] })->as_query;
		like( $$q->[0], qr/SELECT me.id, half_id.id FROM table6 me INNER JOIN table6 half_id ON half_id.id \* 2 = me.id/i,
			'query for half_id' );
	}
};

done_testing;
