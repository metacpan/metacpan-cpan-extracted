package MyService::Member;
use strict;
use base 'MyService::Base';

__PACKAGE__->table('member');
__PACKAGE__->columns(Primary => 'member_id');
__PACKAGE__->columns(Essential => qw/name age member_type/);
__PACKAGE__->set_factory(
	type_column => 'member_type',
	types		=> {
		-Base		=> 'Basic',
		1			=> 'Free',
		2			=> 'VIP',
	},
);

sub CONSTRUCT {
	my $class = shift;
	$class->construct_table;
	$class->insert_samples;
}

sub construct_table {
	my $class = shift;
	$class->db_Main->do(<<SQL);
	CREATE TABLE member (
		member_id integer,
		name varchar(50),
		age integer,
		member_type integer default 0
	);
SQL
	;
}
sub insert_samples {
	my $class = shift;
	my @samples = (
		[ 1, 'Mirko',    30, 0 ],
		[ 2, 'Nogueira', 29, 1 ],
		[ 3, 'Fedor',    28, 2 ],
	);
	$class->create({member_id => $_->[0], name => $_->[1], age => $_->[2], member_type => $_->[3]})
	for @samples;
}

