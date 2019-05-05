use Test2::V0;
no warnings 'once';

my $ret= eval q{
	package test::Table3;
	use DBIx::Class::ResultDDL -V0;
	table 'table3';
	col c0 => integer, auto_inc;
	col c1 => char(50), null, default("foo");
	col c2 => varchar(10);
	col c3 => date;
	col c4 => datetime('floating');
	col c5 => datetime('UTC');
	primary_key 'c0';
	1;
};
my $err= $@;
ok( $ret, 'eval column defs' ) or diag $err;

done_testing;
