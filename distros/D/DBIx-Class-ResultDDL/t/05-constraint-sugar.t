use Test2::V0;
no warnings 'once';

my $ret= eval q{
	package test::Table4;
	use DBIx::Class::ResultDDL -V1;
	table 'table4';
	col c0 => integer, auto_inc;
	col c1 => integer;
	col c2 => integer;
	col c3 => integer;
	col c4 => integer;
	primary_key 'c0';
	unique ['c1'];
	unique ['c2','c4'];
	unique table4_c2_c3 => ['c2','c3'];
	1;
};
my $err= $@;
ok( $ret, 'eval Table4' ) or diag $err;

done_testing;
