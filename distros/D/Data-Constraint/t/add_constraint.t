use strict;
use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'fake' => sub {
	my $constraint = $class->get_by_name( 'fake' ); # no such thing

	ok( ! defined $constraint, 'Non-existent constraint returns undef' );
	ok( ! eval { $constraint->isa( $class ) },
		'Non-existent constraint is not an object' );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# once we are sure that it doesn't exist, make it exist
subtest 'make it exist' => sub {
	my $constraint = $class->add_constraint(
		'fake',
		run         => sub { $_[1] =~ m/a/i },
		description => "Match things with an 'a'",
		);

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(check) );

	is( $constraint->check( 'Foo' ), 0, 'Foo does not have an "a"' );
	is( $constraint->check( 'Bar' ), 1, 'Bar does have an "a"' );
	};

done_testing();
