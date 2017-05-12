use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'defined' => sub {
	my $constraint = $class->get_by_name( 'defined' );

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(description) );

	is( $constraint->description,  'True if the value is defined',
		"description is correct" );

	};

subtest 'test' => sub {
	my $constraint = $class->get_by_name( 'test' );

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(description) );


	is( $constraint->description,  "",
		"description inheritance works" );
	is( $constraint->check( 0 ), 1, "'test' constraint returns true" );
	is( $constraint->check( 1 ), 1, "'test' constraint returns true" );
	is( $constraint->check(   ), 1, "'test' constraint returns true" );
	};

done_testing();
