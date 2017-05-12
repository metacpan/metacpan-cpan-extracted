use strict;

use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'defined' => sub {
	my $constraint = $class->get_by_name( 'defined' );

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(check description run) );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'ordinal' => sub {
	my $constraint = $class->get_by_name( 'ordinal' );

	isa_ok( $constraint, $class );
	can_ok( $constraint, qw(run description check) );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest 'fake' => sub {
	my $constraint = $class->get_by_name( 'fake' ); # no such thing

	ok( ! defined $constraint, 'Non-existent constraint returns undef' );
	};

done_testing();
