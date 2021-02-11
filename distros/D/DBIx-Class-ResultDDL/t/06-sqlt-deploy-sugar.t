use Test2::V0;
no warnings 'once';

{
    package Mock_sqlt_table;
	sub new { bless {}, shift }
	sub calls { $_[0]{calls} ||= [] }
	sub add_index { push @{shift->calls}, [ add_index => @_ ] }
	sub add_constraint { push @{shift->calls}, [ add_constraint => @_ ] }
}

my $ret= eval q{
	package test::Table1;
	use DBIx::Class::ResultDDL -V1;
	table 'table1';
	col c0 => integer, auto_inc;
	col c1 => integer;
	primary_key 'c0';
	sqlt_add_index(name => 'x', fields => ['c1']);
	sqlt_add_constraint(name => 'y');
	idx z => [ 'c1' ];
	create_index zz => [ 'c1' ], where => 'c1 > 5', type => 'SPATIAL';
	1;
};
my $err= $@;
ok( $ret, 'eval Table1' ) or diag $err;
ok( test::Table1->can('sqlt_deploy_hook'), 'deploy hook installed' );
my $mock_sqlt_table= Mock_sqlt_table->new;
test::Table1->sqlt_deploy_hook($mock_sqlt_table);
is( $mock_sqlt_table->calls,
	[
		[ 'add_index', name => 'x', fields => [ 'c1' ] ],
		[ 'add_constraint', name => 'y' ],
		[ 'add_index', name => 'z', fields => [ 'c1' ] ],
		[ 'add_index', name => 'zz', fields => [ 'c1' ], options => { where => 'c1 > 5' }, type => 'SPATIAL' ],
	],
	'correct call'
);

done_testing;
