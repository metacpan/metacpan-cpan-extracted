use strict;

use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

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
