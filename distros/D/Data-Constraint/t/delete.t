use strict;

use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

my $predefined_constraints = 3;

$class->add_constraint(
       'defined',
       'run'         => sub { defined $_[1] },
       'description' => 'True if the value is defined',
       );

$class->add_constraint(
       'ordinal',
       'run'         => sub { $_[1] =~ /^\d+\z/ },
       'description' => 'True if the value is has only digits',
       );

$class->add_constraint(
       'test',
       'run' => sub { 1 },
       );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'no argument' => sub {
	my @names = $class->get_all_names;

	is( scalar @names, $predefined_constraints,
		"There are three predefined constraints" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'defined get_by_name' => sub {
	my $constraint = $class->get_by_name( 'defined' );

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(check description run) );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'defined delete_by_name' => sub {
	$class->delete_by_name( 'defined' );

	my $constraint = $class->delete_by_name( 'defined' );

	ok( ! defined $constraint, "Constraint disappears after delete" );

	my @names = $class->get_all_names;

	is( scalar @names, $predefined_constraints - 1,
		"There are three predefined tests" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'delete_all' => sub {
	$class->delete_all;

	my @names = $class->get_all_names;

	is( scalar @names, 0, "There are no more predefined constraints" );
	};

done_testing();
