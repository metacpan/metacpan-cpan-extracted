use Test2::V0;
no warnings 'once';

my $ret = eval q{
	package test::ViewTable;
	use DBIx::Class::ResultDDL -V1;
	view 'table9001', 'select * from that_table';
	col c0 => integer, auto_inc;
	col c1 => varchar(50), null, default("foo");
	primary_key 'c0';
	1;
};
my $err= $@;
ok( $ret, 'eval ViewTable' ) or diag $err;

my $i = test::ViewTable->new;
is $i->result_source->view_definition, 'select * from that_table', 'correctly makes view';

$ret = eval q{
	package test::VirtualViewTable;
	use DBIx::Class::ResultDDL -V1;
	view 'table9002', 'select * from another_table', virtual => 1;
	col c0 => integer, auto_inc;
	col c1 => varchar(50), null, default("foo");
	primary_key 'c0';
	1;
};
$err= $@;
ok( $ret, 'eval VirtualViewTable' ) or diag $err;

$i = test::VirtualViewTable->new;
is $i->result_source->view_definition, 'select * from another_table', 'correctly makes virtual view';
is $i->result_source->is_virtual, 1, 'and it is virtual';

done_testing;
