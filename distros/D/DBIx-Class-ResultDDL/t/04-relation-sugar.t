use Test2::V0;
no warnings 'once';

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

done_testing;
